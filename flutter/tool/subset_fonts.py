#!/usr/bin/env python3
"""画面に出す文字だけを含むフォントを作る / 足りない文字が無いか検査する。

Flutter Web(CanvasKit)は端末のフォントを使えず、日本語の字形は表示時に
Google Fonts から後追いで読み込む。読み込みが済むまでの間は「□」になるため、
画面に出す文字だけを含むフォントを同梱して、初回から正しく表示させる。

使い方:
  # 元フォントから同梱用フォントを作り直す（画面の文言を変えたら実行する）
  python3 tool/subset_fonts.py build --noto <NotoSansJP[wght].ttf> --mono <JetBrainsMono[wght].ttf>
  # 同梱フォントに、lib/ の文字列リテラルの文字がすべて含まれるか検査する
  python3 tool/subset_fonts.py check

元フォントの入手先（どちらも SIL Open Font License 1.1）:
  https://github.com/google/fonts/tree/main/ofl/notosansjp
  https://github.com/google/fonts/tree/main/ofl/jetbrainsmono
依存: pip install fonttools
"""

import argparse
import pathlib
import re
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONTS = ROOT / 'assets' / 'fonts'
NOTO_OUT = FONTS / 'NotoSansJP-Subset.ttf'
MONO_OUT = FONTS / 'JetBrainsMono-Subset.ttf'

# 等幅フォントに含める文字: ASCII・Latin-1 と、画面で使う記号
MONO_CHARS = {chr(c) for c in range(0x20, 0x7F)} | {chr(c) for c in range(0xA0, 0x100)} | set('—…')

# 文字列リテラル（'...' と "..."）。コメント中の文字は対象にしない。
STRING_LITERAL = re.compile(r"'(?:[^'\\\n]|\\.)*'|\"(?:[^\"\\\n]|\\.)*\"")


def ui_chars() -> set[str]:
    """lib/ の文字列リテラルに現れる非 ASCII 文字を集める。"""
    chars: set[str] = set()
    for path in sorted((ROOT / 'lib').rglob('*.dart')):
        for line in path.read_text(encoding='utf-8').splitlines():
            if line.lstrip().startswith('//'):
                continue
            for literal in STRING_LITERAL.findall(line):
                chars.update(ch for ch in literal if ord(ch) > 0x7E)
    return chars


def make_subset(source: pathlib.Path, chars: set[str], out: pathlib.Path) -> None:
    font = TTFont(source)
    if 'fvar' in font:
        # 可変フォントは標準の太さ(400)に固定する
        font = instancer.instantiateVariableFont(font, {'wght': 400})
    options = subset.Options()
    options.layout_features = ['*']
    options.name_IDs = ['*']
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=[ord(c) for c in sorted(chars)])
    subsetter.subset(font)
    font.save(out)
    print(f'{out.relative_to(ROOT)}: {len(chars)} 文字, {out.stat().st_size} bytes')


def covered(font_path: pathlib.Path) -> set[str]:
    cmap = TTFont(font_path).getBestCmap()
    return {chr(c) for c in cmap}


def check() -> int:
    have = covered(NOTO_OUT) | covered(MONO_OUT)
    missing = sorted(ui_chars() - have)
    if missing:
        print('同梱フォントに無い文字があります: ' + ''.join(missing))
        print('tool/subset_fonts.py build でフォントを作り直してください。')
        return 1
    print('同梱フォントは画面の文字をすべて含んでいます。')
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest='command', required=True)
    b = sub.add_parser('build')
    b.add_argument('--noto', required=True, type=pathlib.Path)
    b.add_argument('--mono', required=True, type=pathlib.Path)
    sub.add_parser('check')
    args = parser.parse_args()

    if args.command == 'build':
        FONTS.mkdir(parents=True, exist_ok=True)
        make_subset(args.mono, MONO_CHARS, MONO_OUT)
        make_subset(args.noto, ui_chars() - MONO_CHARS, NOTO_OUT)
        return check()
    return check()


if __name__ == '__main__':
    sys.exit(main())

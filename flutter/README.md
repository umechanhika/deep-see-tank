# deep-see-tank / Flutter Scene 版

[Flutter Scene](https://fscene.dev/)（Flutter GPU 上の 3D エンジン）で描く、深海水槽放置ゲームの Web 版。
three.js 版（[`../three/`](../three/)）と同じゲームを移植したもの。
遊び方とフェーズ進行はリポジトリ直下の [README](../README.md) を参照。

## 必要なもの

- Flutter 3.47 以上（stable）。動作確認は 3.47.9。
- Web では WebGL2 が使えるブラウザ。Flutter Scene が Web 用の描画処理を内蔵しているため、起動フラグは要らない。

## セットアップ

このディレクトリ（`flutter/`）で実行する。

```bash
flutter pub get
flutter run -d chrome                      # 開発用に起動
flutter test                               # テスト
flutter build web --release --no-web-resources-cdn   # 本番ビルド（build/web/ に出力）
```

サイトのサブパスに置くときは `--base-href /<パス>/` を付けてビルドする（例: `--base-href /deep-see-tank/flutter/`）。

## 技術スタック

| 役割 | 技術 |
|---|---|
| 3Dレンダリング | Flutter Scene（Flutter GPU / Web では WebGL2） |
| 独自シェーダー | Flutter Scene の `.fmat` マテリアル（ビルド時にコンパイル） |
| 言語 | Dart |
| UI（HUD・ツールチップ・演出） | Flutter ウィジェット |
| 永続化 | shared_preferences（Web では localStorage） |
| 環境音 | Web Audio API（`package:web`） |
| ノイズ | 自前のシンプレックスノイズ（`lib/core/noise.dart`） |

## ディレクトリ構成

```
lib/
├── main.dart                 # エントリーポイント・画面と入力
├── deep_sea_game.dart        # 全体のオーケストレーター
├── core/
│   ├── game_state.dart       # 状態管理・セーブ/ロード・放置時間の計算
│   ├── constants.dart        # 水槽寸法・フェーズしきい値
│   ├── noise.dart            # 共有シンプレックスノイズ
│   ├── color.dart            # sRGB ⇔ 線形色の変換
│   ├── geometry_utils.dart   # 円柱・半球の形状生成
│   ├── sprite_batch.dart     # 加算合成で光る点群
│   └── soft_particle.dart    # 発光スプライトのテクスチャ
├── scene/
│   ├── tank_glass.dart       # ガラス筐体
│   ├── water.dart            # 水中シェーダー
│   ├── lighting.dart         # ライティング
│   └── orbit_camera.dart     # 回転・ズームするカメラ
├── creatures/
│   ├── plankton.dart         # パーティクル
│   ├── jellyfish.dart        # 発光クラゲ
│   ├── fish_school.dart      # 魚の群れ（Boid・インスタンス描画）
│   ├── deep_sea_fish.dart    # 深海魚
│   └── creature_manager.dart # 出現・管理
├── environment/
│   ├── coral.dart            # 珊瑚（L-system）
│   ├── coral_garden.dart     # 複数珊瑚の管理
│   ├── bubbles.dart          # 泡
│   ├── feed_effect.dart      # 餌やりエフェクト
│   └── sea_floor.dart        # 砂地・岩
└── ui/
    ├── hud.dart              # フェーズ・時間表示
    ├── creature_tooltip.dart # 生き物の名前表示
    ├── phase_transition.dart # フェーズ移行演出
    └── ambient_audio.dart    # 環境音
assets/
├── materials/                # 水・クラゲの .fmat シェーダー
└── fonts/                    # 画面の文字だけを含む部分フォント
hook/build.dart               # .fmat をビルド時にコンパイルする Flutter Scene のフック
tool/subset_fonts.py          # 部分フォントの作成・検査
```

`flutter_scene_generated/` はビルド時に生成される。中身はコミットしない（同梱の `.gitignore` で除外済み）。

## 画面の文言を変えるとき

Flutter の Web 版は端末のフォントを使えないため、日本語は同梱の部分フォントで描いている。
画面に新しい漢字・かなを足したら、フォントを作り直す。足りない文字があると CI の検査が失敗する。

```bash
pip install fonttools
python3 tool/subset_fonts.py build --noto <NotoSansJP[wght].ttf> --mono <JetBrainsMono[wght].ttf>
python3 tool/subset_fonts.py check
```

元フォントの入手先は `tool/subset_fonts.py` の冒頭に記載。どちらも SIL Open Font License 1.1（`assets/fonts/OFL-*.txt`）。

## three.js 版との違い

見た目と挙動は three.js 版に合わせているが、次の点は意図して変えている。

| 項目 | three.js 版 | Flutter Scene 版 |
|---|---|---|
| ガラス | 透過（transmission）マテリアル | 薄い半透明。Web で透過用の画面キャプチャが重いため |
| 水 | 半透明で背景に重ねる | 背景色との合成をシェーダー内で行い不透明で描く。描画順の乱れを避けるため |
| クラゲの傘の内側 | 縁の光が常に最大になり、傘全体が白く飛ぶ | 内側も縁ほど明るくなるようにした |
| クラゲの漂い | 壁で止まらず、長時間で水槽の外へ出る | 壁で向きを反転する |
| 魚・深海魚の向き | 尾の側へ進む | 頭（深海魚は誘導灯）の側へ進む |
| カメラの初期位置 | 水槽の +Z 側 | -Z 側。エンジンの座標系の違いで、左右を three.js 版と揃えるため |
| セーブデータ | localStorage の `deep-see-tank/save` | `flutter.deep-see-tank/save`。2 つの版の進行は共有しない |

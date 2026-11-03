import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../creatures/creature_info.dart';

/// ツールチップの表示内容。位置は画面座標（論理ピクセル）。
class TooltipData {
  const TooltipData({
    required this.info,
    required this.level,
    required this.position,
  });

  final CreatureInfo info;
  final int level;
  final Offset position;
}

/// 生き物ホバー時に名前とレベルを表示するツールチップ。
/// 対象の 3D 位置を画面へ投影した座標に追従させる。
class CreatureTooltip extends StatelessWidget {
  const CreatureTooltip({super.key, required this.data});

  final ValueListenable<TooltipData?> data;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<TooltipData?>(
        valueListenable: data,
        builder: (context, d, _) {
          return Stack(
            children: [
              if (d != null)
                Positioned(
                  left: d.position.dx,
                  top: d.position.dy,
                  // 対象の少し上に、中央揃えで表示する
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1.3),
                    child: _TooltipBox(info: d.info, level: d.level),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TooltipBox extends StatelessWidget {
  const _TooltipBox({required this.info, required this.level});

  final CreatureInfo info;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xC706121E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x597FD4FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 等幅フォントに「✦」の字形が無いため、同じ意味のアイコンで描く
              const Icon(
                Icons.auto_awesome,
                size: 11,
                color: Color(0xFFDFF0FF),
              ),
              const SizedBox(width: 4),
              Text(
                info.name,
                style: const TextStyle(fontSize: 12, color: Color(0xFFDFF0FF)),
              ),
            ],
          ),
          Text(
            'レベル $level',
            style: const TextStyle(fontSize: 12, color: Color(0xFF7FB6DD)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';

const Map<int, String> _phaseNames = {
  1: 'プランクトンの海',
  2: '発光クラゲの目覚め',
  3: '魚群の到来',
  4: '深海の住人',
  5: '豊穣の水槽',
};

/// HUD に表示する値。
class HudData {
  const HudData({
    required this.phase,
    required this.phaseProgress,
    required this.coralGrowth,
    required this.totalPlayTime,
  });

  final int phase;
  final double phaseProgress;
  final double coralGrowth;
  final double totalPlayTime;
}

String _formatDuration(double totalSeconds) {
  final s = totalSeconds.floor();
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${sec}s';
  return '${sec}s';
}

const _shadow = [Shadow(color: Color(0xCC000000), blurRadius: 8)];

/// 画面オーバーレイの HUD。フェーズ名・豊かさゲージ・総経過時間を表示する。
class Hud extends StatelessWidget {
  const Hud({super.key, required this.data});

  final ValueListenable<HudData> data;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<HudData>(
        valueListenable: data,
        builder: (context, d, _) => Stack(
          children: [
            Positioned(
              top: 20,
              left: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PHASE ${d.phase} / $maxPhase — ${_phaseNames[d.phase] ?? ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFCFE6FF),
                      letterSpacing: 1,
                      shadows: _shadow,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Gauge(progress: d.phaseProgress),
                  const SizedBox(height: 6),
                  Text(
                    '豊かさ ${(d.coralGrowth * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6F9EC2),
                      letterSpacing: 1,
                      shadows: _shadow,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 22,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TOTAL TIME',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF5F86A8),
                      letterSpacing: 1,
                      shadows: _shadow,
                    ),
                  ),
                  Text(
                    _formatDuration(d.totalPlayTime),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFFCFE6FF),
                      letterSpacing: 1,
                      shadows: _shadow,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0x2E78AAD2),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 600),
        curve: Curves.ease,
        widthFactor: progress.clamp(0.0, 1.0),
        heightFactor: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [Color(0xFF2A6EA5), Color(0xFF7FD4FF)],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x997FD4FF), blurRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}

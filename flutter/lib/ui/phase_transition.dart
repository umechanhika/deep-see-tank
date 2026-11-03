import 'dart:async';

import 'package:flutter/material.dart';

const Map<int, String> _phaseMessages = {
  2: '新しい生き物が現れた… 発光クラゲ',
  3: '新しい生き物が現れた… 魚の群れ',
  4: '新しい生き物が現れた… 深海の住人',
  5: '水槽が豊かさに満ちた…',
};

/// フェーズ移行の演出を外から起動するためのコントローラ。
class PhaseTransitionController extends ChangeNotifier {
  int? _phase;
  int _serial = 0;

  int? get phase => _phase;
  int get serial => _serial;

  void play(int phase) {
    if (!_phaseMessages.containsKey(phase)) return;
    _phase = phase;
    _serial++;
    notifyListeners();
  }
}

/// フェーズ移行時の、上から光が差し込む演出とメッセージ表示。
class PhaseTransition extends StatefulWidget {
  const PhaseTransition({super.key, required this.controller});

  final PhaseTransitionController controller;

  @override
  State<PhaseTransition> createState() => _PhaseTransitionState();
}

class _PhaseTransitionState extends State<PhaseTransition> {
  bool _flash = false;
  bool _message = false;
  String _text = '';
  Timer? _flashTimer;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPlay);
    // 画面の表示前(放置時間の反映時)にフェーズが上がっていた場合も演出する
    if (widget.controller.phase != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onPlay();
      });
    }
  }

  void _onPlay() {
    final phase = widget.controller.phase;
    if (phase == null) return;
    _flashTimer?.cancel();
    _messageTimer?.cancel();
    setState(() {
      _text = _phaseMessages[phase]!;
      _flash = true;
      _message = true;
    });
    _flashTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _flash = false);
    });
    _messageTimer = Timer(const Duration(milliseconds: 3600), () {
      if (mounted) setState(() => _message = false);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlay);
    _flashTimer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _flash ? 1 : 0,
              duration: const Duration(milliseconds: 1200),
              curve: Curves.ease,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [Color(0x735AA0DC), Color(0x0001060F)],
                    stops: [0, 0.6],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.16),
            child: AnimatedOpacity(
              opacity: _message ? 1 : 0,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.ease,
              child: Text(
                _text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (width * 0.03).clamp(16.0, 26.0),
                  letterSpacing: 4,
                  color: const Color(0xFFE6F4FF),
                  shadows: const [
                    Shadow(color: Color(0xB37FC8FF), blurRadius: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

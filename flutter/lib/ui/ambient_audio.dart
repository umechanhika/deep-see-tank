import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// 深海の環境音。低い持続音 + ゆっくりした揺らぎでアンビエントを作る。
/// ブラウザの自動再生制限に従い、最初のユーザー操作で開始する。
///
/// Web Audio API を直接使うため Web 専用。
class AmbientAudio {
  web.AudioContext? _ctx;
  web.GainNode? _master;
  bool _started = false;
  bool _muted = false;

  /// 最初のユーザー操作時に呼ぶ。多重起動はしない。
  void start() {
    if (_started) {
      // 一度サスペンドされていれば再開
      _ctx?.resume();
      return;
    }
    _started = true;

    final ctx = web.AudioContext();
    _ctx = ctx;

    final master = ctx.createGain()..gain.value = 0;
    master.connect(ctx.destination);
    _master = master;

    final filter = ctx.createBiquadFilter()
      ..type = 'lowpass'
      ..frequency.value = 420
      ..Q.value = 0.7;
    filter.connect(master);

    // 低い持続音を2つ重ねてうねりを作る
    const freqs = [55.0, 82.4];
    for (var i = 0; i < freqs.length; i++) {
      final osc = ctx.createOscillator()
        ..type = 'sine'
        ..frequency.value = freqs[i];
      final g = ctx.createGain()..gain.value = i == 0 ? 0.5 : 0.3;
      osc.connect(g);
      g.connect(filter);
      osc.start();

      // ゆっくりした音量のうねり
      final lfo = ctx.createOscillator()..frequency.value = 0.05 + i * 0.03;
      final lfoGain = ctx.createGain()..gain.value = 0.15;
      lfo.connect(lfoGain);
      lfoGain.connect(g.gain);
      lfo.start();
    }

    // ふわっとフェードイン
    master.gain.linearRampToValueAtTime(0.18, ctx.currentTime + 3);
  }

  /// ミュートを切り替え、切り替え後の状態を返す。
  bool toggleMute() {
    final ctx = _ctx;
    final master = _master;
    if (ctx == null || master == null) return _muted;
    _muted = !_muted;
    master.gain.linearRampToValueAtTime(
      _muted ? 0 : 0.18,
      ctx.currentTime + 0.4,
    );
    return _muted;
  }

  @visibleForTesting
  bool get started => _started;
}

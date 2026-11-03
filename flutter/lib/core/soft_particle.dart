import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';

Texture2D? _softParticle;

/// 中心が明るく外周に向けて減衰する円形スプライト。
/// プランクトンや泡・餌の発光表現に使い回す。
TextureSource softParticleTexture() {
  final cached = _softParticle;
  if (cached != null) return cached;

  const size = 64;
  final pixels = Uint8List(size * size * 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = (x + 0.5) / size * 2 - 1;
      final dy = (y + 0.5) / size * 2 - 1;
      final r = (dx * dx + dy * dy).clamp(0.0, 1.0);
      final d = r == 0 ? 0.0 : math.sqrt(r);
      // three.js 版の放射グラデーション(0→1, 0.25→0.7, 1→0)と同じ減衰
      final a = d < 0.25 ? 1 - d / 0.25 * 0.3 : 0.7 * (1 - (d - 0.25) / 0.75);
      final o = (y * size + x) * 4;
      pixels[o] = 255;
      pixels[o + 1] = 255;
      pixels[o + 2] = 255;
      pixels[o + 3] = (a.clamp(0.0, 1.0) * 255).round();
    }
  }
  return _softParticle = Texture2D.fromPixels(pixels, size, size);
}

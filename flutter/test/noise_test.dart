import 'dart:math' as math;

import 'package:deep_see_tank/core/noise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ノイズは -1〜1 に収まり、同じ入力には同じ値を返す', () {
    final n = SimplexNoise(math.Random(1));
    final rng = math.Random(2);
    var min = double.infinity;
    var max = -double.infinity;
    for (var i = 0; i < 20000; i++) {
      final x = rng.nextDouble() * 200 - 100;
      final y = rng.nextDouble() * 200 - 100;
      final z = rng.nextDouble() * 200 - 100;
      final v = n.noise3(x, y, z);
      expect(n.noise3(x, y, z), v);
      min = math.min(min, v);
      max = math.max(max, v);
    }
    expect(min, greaterThanOrEqualTo(-1));
    expect(max, lessThanOrEqualTo(1));
    // 値域の大半を使っている（定数や極端に偏った出力になっていない）
    expect(min, lessThan(-0.6));
    expect(max, greaterThan(0.6));
  });

  test('近い入力どうしは近い値になる（なめらかさ）', () {
    final n = SimplexNoise(math.Random(3));
    for (var i = 0; i < 1000; i++) {
      final x = i * 0.37;
      final a = n.noise3(x, 1.3, 2.7);
      final b = n.noise3(x + 1e-4, 1.3, 2.7);
      expect((a - b).abs(), lessThan(0.01));
    }
  });
}

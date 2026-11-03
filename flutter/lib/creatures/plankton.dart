import 'dart:math' as math;
import 'dart:typed_data';

import '../core/constants.dart';
import '../core/noise.dart';
import '../core/sprite_batch.dart';

/// 微弱に発光しながら漂うプランクトン。
/// 加算合成の点群で群れの光を表現し、シンプレックスノイズで
/// ゆっくりランダムウォークさせる。ゲーム開始直後から常時表示。
class Plankton {
  Plankton(math.Random rng, {this.count = 4000})
    : _positions = Float32List(count * 3),
      batch = SpriteBatch(
        capacity: count,
        color: 0x9fd4ff,
        size: 0.12,
        opacity: 0.7,
        name: 'plankton',
      ) {
    final b = tankBounds(0.5);
    final size = b.max - b.min;
    for (var i = 0; i < count; i++) {
      _positions[i * 3] = b.min.x + rng.nextDouble() * size.x;
      _positions[i * 3 + 1] = b.min.y + rng.nextDouble() * size.y;
      _positions[i * 3 + 2] = b.min.z + rng.nextDouble() * size.z;
    }
  }

  final int count;
  final Float32List _positions;
  final SpriteBatch batch;
  final _bounds = tankBounds(0.5);

  void update(double delta, double time) {
    final pos = _positions;
    final min = _bounds.min;
    final max = _bounds.max;

    for (var i = 0; i < count; i++) {
      final ix = i * 3;
      final x = pos[ix];
      final y = pos[ix + 1];
      final z = pos[ix + 2];

      // 3軸それぞれ別のノイズ場でゆったり漂わせる
      final nx = noise.noise3(x * 0.08, y * 0.08, time * 0.05);
      final ny = noise.noise3(y * 0.08, z * 0.08, time * 0.05 + 100);
      final nz = noise.noise3(z * 0.08, x * 0.08, time * 0.05 + 200);

      pos[ix] += nx * delta * 0.5;
      pos[ix + 1] += (ny * 0.4 + 0.05) * delta * 0.5; // 僅かに上昇
      pos[ix + 2] += nz * delta * 0.5;

      // 範囲外に出たら反対側へ回り込ませて密度を保つ
      if (pos[ix] < min.x) {
        pos[ix] = max.x;
      } else if (pos[ix] > max.x) {
        pos[ix] = min.x;
      }
      if (pos[ix + 1] < min.y) {
        pos[ix + 1] = max.y;
      } else if (pos[ix + 1] > max.y) {
        pos[ix + 1] = min.y;
      }
      if (pos[ix + 2] < min.z) {
        pos[ix + 2] = max.z;
      } else if (pos[ix + 2] > max.z) {
        pos[ix + 2] = min.z;
      }
      batch.set(i, pos[ix], pos[ix + 1], pos[ix + 2]);
    }
    batch.commit(count);

    // 全体をゆっくり明滅
    batch.opacity = 0.55 + math.sin(time * 0.5) * 0.12;
  }
}

import 'dart:math' as math;
import 'dart:typed_data';

import '../core/constants.dart';
import '../core/sprite_batch.dart';

/// 海底から立ち上る泡。上端に達したら下へリセットして循環させる。
class Bubbles {
  Bubbles(this._rng, {this.count = 200})
    : _positions = Float32List(count * 3),
      _speed = Float32List(count),
      batch = SpriteBatch(
        capacity: count,
        color: 0xbfe6ff,
        size: 0.14,
        opacity: 0.35,
        name: 'bubbles',
      ) {
    for (var i = 0; i < count; i++) {
      _reset(i, randomY: true);
    }
  }

  final math.Random _rng;
  final int count;
  final Float32List _positions;
  final Float32List _speed;
  final SpriteBatch batch;

  void _reset(int i, {required bool randomY}) {
    final ix = i * 3;
    _positions[ix] = (_rng.nextDouble() - 0.5) * (Tank.width - 3);
    _positions[ix + 1] = randomY
        ? -Tank.height / 2 + _rng.nextDouble() * Tank.height
        : -Tank.height / 2 + 0.2;
    _positions[ix + 2] = (_rng.nextDouble() - 0.5) * (Tank.depth - 3);
    _speed[i] = 0.5 + _rng.nextDouble() * 1.0;
  }

  void update(double delta, double time) {
    const top = Tank.height / 2;
    for (var i = 0; i < count; i++) {
      final ix = i * 3;
      _positions[ix + 1] += _speed[i] * delta;
      // 左右にゆらゆら
      _positions[ix] += math.sin(time * 2 + i) * delta * 0.2;
      if (_positions[ix + 1] > top) _reset(i, randomY: false);
      batch.set(i, _positions[ix], _positions[ix + 1], _positions[ix + 2]);
    }
    batch.commit(count);
  }
}

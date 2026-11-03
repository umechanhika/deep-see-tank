import 'dart:math' as math;

import 'package:vector_math/vector_math.dart' as vm;

import '../core/constants.dart';
import '../core/sprite_batch.dart';

class _Particle {
  final vm.Vector3 pos = vm.Vector3.zero();
  final vm.Vector3 vel = vm.Vector3.zero();
  double life = 0;
}

/// 餌やりで水中に降る餌粒。クリック地点から発生し、ゆっくり沈む。
class FeedEffect {
  FeedEffect(this._rng, {int poolSize = 240})
    : _pool = List.generate(poolSize, (_) => _Particle()),
      batch = SpriteBatch(
        capacity: poolSize,
        color: 0xffe6a8,
        size: 0.22,
        opacity: 0.9,
        name: 'feed',
      ) {
    batch.commit(0);
  }

  final math.Random _rng;
  final List<_Particle> _pool;
  final SpriteBatch batch;

  /// 指定地点から餌をばらまく。
  void spawn(vm.Vector3 point, {int amount = 24}) {
    var spawned = 0;
    for (final p in _pool) {
      if (spawned >= amount) break;
      if (p.life > 0) continue;
      p.pos.setValues(
        point.x + (_rng.nextDouble() - 0.5) * 1.5,
        point.y + (_rng.nextDouble() - 0.5) * 1.0,
        point.z + (_rng.nextDouble() - 0.5) * 1.5,
      );
      p.vel.setValues(
        (_rng.nextDouble() - 0.5) * 0.3,
        -0.4 - _rng.nextDouble() * 0.4,
        (_rng.nextDouble() - 0.5) * 0.3,
      );
      p.life = 6 + _rng.nextDouble() * 3;
      spawned++;
    }
  }

  void update(double delta) {
    const floor = -Tank.height / 2 + 0.3;
    var live = 0;
    for (final p in _pool) {
      if (p.life <= 0) continue;
      p.life -= delta;
      p.vel.x *= 0.98;
      p.vel.z *= 0.98;
      p.pos.addScaled(p.vel, delta);
      if (p.pos.y <= floor) {
        p.pos.y = floor;
        p.life = 0;
      }
      // 生きている粒だけを先頭から詰めて描く
      batch.set(live++, p.pos.x, p.pos.y, p.pos.z);
    }
    batch.commit(live);
  }
}

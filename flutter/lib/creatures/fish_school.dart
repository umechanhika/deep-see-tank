import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/color.dart';
import '../core/constants.dart';
import '../core/geometry_utils.dart';

const double _maxSpeed = 3.2;
const double _maxForce = 0.08;
const double _perception = 3.0;
const double _separationDist = 1.4;

/// 1匹の魚の運動状態。古典的な Boid の3ルールで群れを作る。
class _Boid {
  _Boid(vm.Aabb3 bounds, math.Random rng) {
    final size = bounds.max - bounds.min;
    position.setValues(
      bounds.min.x + rng.nextDouble() * size.x,
      bounds.min.y + rng.nextDouble() * size.y,
      bounds.min.z + rng.nextDouble() * size.z,
    );
    velocity
      ..setValues(
        rng.nextDouble() - 0.5,
        (rng.nextDouble() - 0.5) * 0.4,
        rng.nextDouble() - 0.5,
      )
      ..normalize()
      ..scale(_maxSpeed * 0.6);
  }

  final vm.Vector3 position = vm.Vector3.zero();
  final vm.Vector3 velocity = vm.Vector3.zero();
  final vm.Vector3 _acceleration = vm.Vector3.zero();

  void flock(List<_Boid> boids) {
    final sep = vm.Vector3.zero();
    final ali = vm.Vector3.zero();
    final coh = vm.Vector3.zero();
    var sepCount = 0;
    var count = 0;

    for (final other in boids) {
      if (identical(other, this)) continue;
      final d = position.distanceTo(other.position);
      if (d > _perception) continue;

      ali.add(other.velocity);
      coh.add(other.position);
      count++;

      if (d < _separationDist && d > 0) {
        sep.add((position - other.position)..scale(1 / (d * d)));
        sepCount++;
      }
    }

    if (count > 0) {
      ali.scale(1 / count);
      _steerTo(ali, 1.0);

      coh
        ..scale(1 / count)
        ..sub(position);
      _steerTo(coh, 0.9);
    }
    if (sepCount > 0) {
      sep.scale(1 / sepCount);
      _steerTo(sep, 1.6);
    }
  }

  /// desired 方向へ向かう操舵力を加速度に足し込む。
  void _steerTo(vm.Vector3 desired, double weight) {
    if (desired.length2 == 0) return;
    desired
      ..normalize()
      ..scale(_maxSpeed);
    final steer = desired - velocity;
    if (steer.length > _maxForce) steer.length = _maxForce;
    _acceleration.addScaled(steer, weight);
  }

  /// 壁に近づいたら中心方向へ緩やかに押し戻す。
  void _avoidWalls(vm.Aabb3 bounds) {
    const margin = 2.0;
    const push = 0.05;
    if (position.x < bounds.min.x + margin) {
      _acceleration.x += push;
    } else if (position.x > bounds.max.x - margin) {
      _acceleration.x -= push;
    }
    if (position.y < bounds.min.y + margin) {
      _acceleration.y += push;
    } else if (position.y > bounds.max.y - margin) {
      _acceleration.y -= push;
    }
    if (position.z < bounds.min.z + margin) {
      _acceleration.z += push;
    } else if (position.z > bounds.max.z - margin) {
      _acceleration.z -= push;
    }
  }

  /// 餌など外的な誘引点へ向かう力を加える。
  void attractTo(vm.Vector3 target, double strength) {
    final dir = target - position;
    final d = dir.length;
    if (d > 0.001) _acceleration.addScaled(dir, strength / d);
  }

  void update(double delta, vm.Aabb3 bounds) {
    _avoidWalls(bounds);
    velocity.addScaled(_acceleration, delta * 60);
    if (velocity.length > _maxSpeed) velocity.length = _maxSpeed;
    // 完全停止しないよう最低速度を保つ
    if (velocity.length < _maxSpeed * 0.25) velocity.length = _maxSpeed * 0.25;

    position.addScaled(velocity, delta);

    // 万一はみ出したら境界内へクランプ
    position.clamp(bounds.min, bounds.max);
    _acceleration.setZero();
  }
}

/// 魚の群れ。インスタンス描画で多数を1ドローコールで描く。
class FishSchool {
  FishSchool(this._rng, {this.maxCount = 30, int color = 0xc9d8e0}) {
    // 魚の形: 円錐を +Z(進行方向)へ向け、薄く成形する
    final cone = cylinderMeshData(
      bottomRadius: 0.28,
      topRadius: 0,
      height: 1.1,
      yStart: -0.55,
      radialSegments: 6,
    );
    final shape = vm.Matrix4.diagonal3Values(0.65, 0.5, 1)
      ..multiply(vm.Matrix4.rotationX(math.pi / 2));
    final material = PhysicallyBasedMaterial()
      ..baseColorFactor = linearRgba(color)
      ..roughnessFactor = 0.6
      ..metallicFactor = 0.2
      ..emissiveFactor = linearRgba(0x0a1a24);
    _mesh = InstancedMesh(
      geometry: MeshGeometry.fromMeshData(cone.transformed(shape)),
      material: material,
    );
    node = Node(name: 'fish-school')
      ..frustumCulled = false
      ..raycastable = false
      ..addComponent(InstancedMeshComponent(_mesh));
  }

  final math.Random _rng;
  final int maxCount;
  final List<_Boid> _boids = [];
  final vm.Aabb3 _bounds = tankBounds(2.0);
  late final InstancedMesh _mesh;
  late final Node node;

  final vm.Matrix4 _scratch = vm.Matrix4.identity();
  final vm.Vector3 _up = vm.Vector3(0, 1, 0);

  int get count => _boids.length;

  /// 群れの匹数を設定（増減）。
  void setCount(int n) {
    final target = n.clamp(0, maxCount);
    while (_boids.length < target) {
      _boids.add(_Boid(_bounds, _rng));
      _mesh.addInstance(_scratch);
    }
    while (_boids.length > target) {
      _boids.removeLast();
      _mesh.removeInstanceAt(_boids.length);
    }
  }

  /// 餌の位置へ群れを引き寄せる。
  void attract(vm.Vector3 target, double strength) {
    for (final b in _boids) {
      b.attractTo(target, strength);
    }
  }

  void update(double delta) {
    if (_boids.isEmpty) return;
    for (final b in _boids) {
      b.flock(_boids);
    }
    for (final b in _boids) {
      b.update(delta, _bounds);
    }
    _mesh.updateInstanceTransforms((transforms) {
      for (var i = 0; i < _boids.length; i++) {
        final b = _boids[i];
        // 進行方向(+Z)を速度ベクトルへ向ける
        final forward = b.velocity.normalized();
        final right = _up.cross(forward);
        if (right.length2 < 1e-6) right.setValues(1, 0, 0);
        right.normalize();
        final up = forward.cross(right);
        transforms[i].setValues(
          right.x,
          right.y,
          right.z,
          0,
          up.x,
          up.y,
          up.z,
          0,
          forward.x,
          forward.y,
          forward.z,
          0,
          b.position.x,
          b.position.y,
          b.position.z,
          1,
        );
      }
    }, recomputeWinding: false);
  }
}

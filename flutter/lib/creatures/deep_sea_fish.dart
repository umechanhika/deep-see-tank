import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/color.dart';
import '../core/constants.dart';
import '../core/noise.dart';

const List<int> _lureColors = [0x7affe0, 0x9fb0ff, 0xc9ff8f];

/// 深海魚1体。暗い体に発光する誘導灯(ルアー)を持ち、
/// ノイズ場に沿ってゆっくり徘徊する。提灯アンコウのイメージ。
class DeepSeaFish {
  DeepSeaFish(vm.Vector3 position, math.Random rng)
    : _seed = rng.nextDouble() * 100,
      _speed = 0.5 + rng.nextDouble() * 0.4 {
    final scale = 1.1 + rng.nextDouble() * 0.7;
    final lureColor = linearRgb(_lureColors[rng.nextInt(_lureColors.length)]);

    // 体: 進行方向(+Z)に長く潰した多面体。面ごとの法線でゴツゴツさせる
    final bodyData = IcosphereGeometry(radius: 1, subdivisions: 1)
        .extractMeshData()
        .transformed(
          vm.Matrix4.diagonal3Values(0.8 * scale, 0.9 * scale, 1.8 * scale),
        )
        .unweld();
    final body = Node(
      name: 'body',
      mesh: Mesh(
        MeshGeometry.fromMeshData(bodyData),
        PhysicallyBasedMaterial()
          ..baseColorFactor = linearRgba(0x0a141c)
          ..roughnessFactor = 0.9
          ..metallicFactor = 0.1
          ..emissiveFactor = linearRgba(0x05121a),
      ),
    );

    // 誘導灯: 頭部前方(+Z)の上に発光する小球
    _lureMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(lureColor.x, lureColor.y, lureColor.z, 1)
      ..emissiveFactor = vm.Vector4(lureColor.x, lureColor.y, lureColor.z, 1)
      ..emissiveStrength = 2.5;
    _light = PointLight(
      color: lureColor,
      intensity: 1.2,
      range: 7 * scale,
      falloffExponent: 2,
    );
    final lure =
        Node(
            name: 'lure',
            mesh: Mesh(
              SphereGeometry(radius: 0.16 * scale, segments: 12, rings: 12),
              _lureMaterial,
            ),
          )
          ..position = vm.Vector3(0, 0.7 * scale, 1.9 * scale)
          ..addComponent(PointLightComponent(_light));

    node
      ..position = position
      ..add(body)
      ..add(lure);
  }

  final Node node = Node(name: 'deep-sea-fish');
  final double _seed;
  final double _speed;
  final vm.Aabb3 _bounds = tankBounds(2.5);
  final vm.Vector3 _heading = vm.Vector3(1, 0, 0);
  late final PhysicallyBasedMaterial _lureMaterial;
  late final PointLight _light;

  void update(double delta, double time) {
    final t = time * 0.06 + _seed;
    final p = node.position;

    // ノイズで進行方向をなめらかに変える
    final desired = vm.Vector3(
      noise.noise3(p.x * 0.05, p.y * 0.05, t),
      noise.noise3(p.y * 0.05, p.z * 0.05, t + 50) * 0.4,
      noise.noise3(p.z * 0.05, p.x * 0.05, t + 100),
    );

    // 壁が近ければ中心へ向ける
    if (!_bounds.containsVector3(p)) {
      desired.add((_bounds.center - p)..normalize());
    }

    if (desired.length2 > 0) {
      desired.normalize();
      final k = 1 - math.pow(0.001, delta).toDouble();
      _heading
        ..add((desired - _heading)..scale(k))
        ..normalize();
    }

    p
      ..addScaled(_heading, _speed * delta)
      ..clamp(_bounds.min, _bounds.max);
    node.position = p;

    // 進行方向を向く
    node.lookAt(p + _heading);

    // 誘導灯のゆらめき
    final flicker = 0.8 + math.sin(time * 2 + _seed) * 0.3;
    _light.intensity = 1.0 + flicker;
    _lureMaterial.emissiveStrength = 2.0 + flicker;
  }
}

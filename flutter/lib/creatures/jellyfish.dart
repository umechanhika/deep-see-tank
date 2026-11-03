import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/color.dart';
import '../core/constants.dart';
import '../core/geometry_utils.dart';

// 個体ごとの基調色候補（淡い発光色）
const List<int> _palette = [0x6ad1ff, 0xb58bff, 0xff8fcf, 0x7affd1, 0xffd07a];

/// 発光クラゲ1体。半透明の傘＋揺れる触手＋追従ポイントライト。
/// ふわふわ上下しながらゆっくり漂う。
class Jellyfish {
  Jellyfish._(
    this.node,
    this._bell,
    this._tentacles,
    this._light,
    this._baseY,
    math.Random rng,
  ) : _bobSpeed = 0.3 + rng.nextDouble() * 0.3,
      _bobAmp = 0.6 + rng.nextDouble() * 0.8,
      _pulseSpeed = 0.8 + rng.nextDouble() * 0.5,
      _driftX = (rng.nextDouble() - 0.5) * 0.15,
      _driftZ = (rng.nextDouble() - 0.5) * 0.15,
      _seed = rng.nextDouble() * 100;

  static Future<Jellyfish> create(vm.Vector3 position, math.Random rng) async {
    final colorHex = _palette[rng.nextInt(_palette.length)];
    final color = linearRgb(colorHex);
    final scale = 0.7 + rng.nextDouble() * 0.6;

    // --- 傘 ---
    final bellRadius = 1.4 * scale;
    final bellMaterial = await loadFmatMaterial(
      'assets/materials/jellyfish_bell.fmat',
    );
    // リムの色は基調色と白の中間（three.js 版は線形空間で補間していた）
    final rimColor = color + (vm.Vector3.all(1) - color) * 0.5;
    bellMaterial.parameters
      ..setVec3('base_color', color)
      ..setVec3('rim_color', rimColor)
      ..setFloat('opacity', 0.85);
    final bell = Node(
      name: 'bell',
      mesh: Mesh(
        MeshGeometry.fromMeshData(
          domeMeshData(radius: bellRadius, thetaLength: math.pi * 0.55),
        ),
        bellMaterial,
      ),
    );

    // --- 触手 (8本をまとめて1ドローコール) ---
    final tentacleMaterial = await loadFmatMaterial(
      'assets/materials/jellyfish_tentacle.fmat',
    );
    tentacleMaterial.parameters.setVec3('base_color', color);
    final tentacles = Node(
      name: 'tentacles',
      mesh: Mesh(
        MeshGeometry.fromMeshData(_buildTentacles(bellRadius, scale, rng)),
        tentacleMaterial,
      ),
    )..raycastable = false;

    // --- 追従ライト ---
    final light = PointLight(
      color: color,
      intensity: 1.4,
      range: 9 * scale,
      falloffExponent: 1.8,
    );

    final node = Node(name: 'jellyfish')
      ..position = position
      ..add(bell)
      ..add(tentacles)
      ..addComponent(PointLightComponent(light));

    return Jellyfish._(
      node,
      bellMaterial,
      tentacleMaterial,
      light,
      position.y,
      rng,
    );
  }

  static MeshData _buildTentacles(
    double bellRadius,
    double scale,
    math.Random rng,
  ) {
    const num = 8;
    final length = 3.5 * scale;
    final rim = bellRadius * 0.7;
    final parts = <MeshData>[];

    for (var i = 0; i < num; i++) {
      // 上端を原点に、下へ垂らす
      final cylinder = cylinderMeshData(
        bottomRadius: 0.015 * scale,
        topRadius: 0.05 * scale,
        height: length,
        yStart: -length,
        radialSegments: 5,
        heightSegments: 10,
      );
      final n = cylinder.vertexCount;
      final t = Float32List(n);
      final phase = Float32List(n);
      final ph = (i / num) * math.pi * 2 + rng.nextDouble();
      for (var v = 0; v < n; v++) {
        t[v] = -cylinder.positions[v * 3 + 1] / length; // 0:上端 → 1:先端
        phase[v] = ph;
      }
      final withAttributes = MeshData(
        positions: cylinder.positions,
        vertexCount: n,
        normals: cylinder.normals,
        texCoords: cylinder.texCoords,
        indices: cylinder.indices,
        customAttributes: {
          'tentacle_t': MeshAttributeData(t, components: 1),
          'tentacle_phase': MeshAttributeData(phase, components: 1),
        },
      );

      final angle = (i / num) * math.pi * 2;
      parts.add(
        withAttributes.transformed(
          vm.Matrix4.translationValues(
            math.cos(angle) * rim,
            -bellRadius * 0.15,
            math.sin(angle) * rim,
          ),
        ),
      );
    }
    return MeshData.merge(parts);
  }

  final Node node;
  final PreprocessedMaterial _bell;
  final PreprocessedMaterial _tentacles;
  final PointLight _light;
  final double _baseY;
  final double _bobSpeed;
  final double _bobAmp;
  final double _pulseSpeed;
  double _driftX;
  double _driftZ;
  final double _seed;
  final vm.Aabb3 _bounds = tankBounds(2.5);

  void update(double delta, double time) {
    final t = time + _seed;

    // 脈動 0〜1
    final pulse = math
        .pow(math.sin(t * _pulseSpeed) * 0.5 + 0.5, 1.5)
        .toDouble();
    _bell.parameters.setFloat('pulse', pulse);
    _tentacles.parameters.setFloat('time', t);

    // 水槽の壁に近づいたら漂う向きを反転させる。
    // three.js 版は反転がなく、長時間の放置で水槽の外へ漂い出ていたため。
    final p = node.position;
    if ((p.x < _bounds.min.x && _driftX < 0) ||
        (p.x > _bounds.max.x && _driftX > 0)) {
      _driftX = -_driftX;
    }
    if ((p.z < _bounds.min.z && _driftZ < 0) ||
        (p.z > _bounds.max.z && _driftZ > 0)) {
      _driftZ = -_driftZ;
    }

    // 脈動と連動した推進＋ふわふわ上下
    node.position = vm.Vector3(
      p.x + _driftX * delta,
      _baseY + math.sin(t * _bobSpeed) * _bobAmp,
      p.z + _driftZ * delta,
    );

    // ライトの明滅
    _light.intensity = 1.0 + pulse * 1.2;
  }
}

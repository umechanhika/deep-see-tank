import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/color.dart';
import '../core/constants.dart';
import '../core/noise.dart';

/// 砂地と岩。平面の頂点をノイズで持ち上げて凹凸を作り、
/// 歪ませた多面体をいくつか散らして岩礁にする。
class SeaFloor {
  SeaFloor(math.Random rng) {
    node.add(_buildSand());
    _buildRocks(rng);
  }

  final Node node = Node(name: 'sea-floor');

  Node _buildSand() {
    const segs = 64;
    const row = segs + 1;
    final positions = Float32List(row * row * 3);
    for (var iz = 0; iz <= segs; iz++) {
      for (var ix = 0; ix <= segs; ix++) {
        final x = (ix / segs - 0.5) * Tank.width;
        final z = (iz / segs - 0.5) * Tank.depth;
        // 頂点を高さ方向にノイズ変位
        final h =
            noise.noise3(x * 0.12, z * 0.12, 0) * 0.6 +
            noise.noise3(x * 0.4, z * 0.4, 10) * 0.18;
        final o = (iz * row + ix) * 3;
        positions[o] = x;
        positions[o + 1] = h;
        positions[o + 2] = z;
      }
    }
    final indices = <int>[];
    for (var iz = 0; iz < segs; iz++) {
      for (var ix = 0; ix < segs; ix++) {
        final a = iz * row + ix;
        final b = a + row;
        indices.addAll([a, b, a + 1, a + 1, b, b + 1]);
      }
    }
    // 法線は省略し、エンジンに頂点法線を生成させる
    final data = MeshData.build(positions: positions, indices: indices);

    final material = PhysicallyBasedMaterial()
      ..baseColorFactor = linearRgba(0x14222e)
      ..roughnessFactor = 1
      ..metallicFactor = 0;

    return Node(
        name: 'sand',
        mesh: Mesh(MeshGeometry.fromMeshData(data), material),
      )
      ..position = vm.Vector3(0, -Tank.height / 2 + 0.05, 0)
      ..raycastable = false;
  }

  void _buildRocks(math.Random rng) {
    final material = PhysicallyBasedMaterial()
      ..baseColorFactor = linearRgba(0x0d1820)
      ..roughnessFactor = 0.95
      ..metallicFactor = 0.05;

    const count = 7;
    for (var i = 0; i < count; i++) {
      final r = 0.7 + rng.nextDouble() * 1.8;
      // 頂点を歪ませて自然な岩に
      final source = IcosphereGeometry(
        radius: r,
        subdivisions: 1,
      ).extractMeshData();
      final p = Float32List.fromList(source.positions);
      for (var j = 0; j < source.vertexCount; j++) {
        final o = j * 3;
        final f = 1 + noise.noise3(p[o], p[o + 1], p[o + 2]) * 0.35;
        p[o] *= f;
        p[o + 1] *= f;
        p[o + 2] *= f;
      }
      // 面ごとの法線にしてゴツゴツした質感（フラットシェーディング）にする
      final data = MeshData.build(
        positions: p,
        indices: source.indices,
      ).unweld();

      final x = (rng.nextDouble() - 0.5) * (Tank.width - 4);
      final z = (rng.nextDouble() - 0.5) * (Tank.depth - 4);
      node.add(
        Node(
            name: 'rock',
            mesh: Mesh(MeshGeometry.fromMeshData(data), material),
          )
          ..position = vm.Vector3(x, -Tank.height / 2 + r * 0.4, z)
          ..rotation = vm.Quaternion.euler(
            rng.nextDouble(),
            rng.nextDouble(),
            rng.nextDouble(),
          )
          ..scale = vm.Vector3(1, 0.7, 1)
          ..raycastable = false,
      );
    }
  }
}

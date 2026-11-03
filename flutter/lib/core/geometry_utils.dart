import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';

/// 円柱（円錐台）の頂点データを作る。
///
/// Y 軸方向に [yStart] から [yStart] + [height] まで伸び、
/// 下端の半径が [bottomRadius]、上端の半径が [topRadius]。
/// 合成や頂点ごとの属性付けのため、GPU に載せる前の [MeshData] で返す。
MeshData cylinderMeshData({
  required double bottomRadius,
  required double topRadius,
  required double height,
  double yStart = 0,
  int radialSegments = 8,
  int heightSegments = 1,
  bool caps = true,
}) {
  final positions = <double>[];
  final normals = <double>[];
  final uvs = <double>[];
  final indices = <int>[];

  // 側面の法線は傾き(半径差 / 高さ)の分だけ Y 成分を持つ
  final slope = (bottomRadius - topRadius) / height;
  for (var y = 0; y <= heightSegments; y++) {
    final v = y / heightSegments;
    final r = bottomRadius + (topRadius - bottomRadius) * v;
    for (var x = 0; x <= radialSegments; x++) {
      final u = x / radialSegments;
      final theta = u * math.pi * 2;
      final s = math.sin(theta);
      final c = math.cos(theta);
      positions.addAll([r * s, yStart + height * v, r * c]);
      final len = math.sqrt(1 + slope * slope);
      normals.addAll([s / len, slope / len, c / len]);
      uvs.addAll([u, v]);
    }
  }
  final row = radialSegments + 1;
  for (var y = 0; y < heightSegments; y++) {
    for (var x = 0; x < radialSegments; x++) {
      final a = y * row + x;
      final b = a + row;
      indices.addAll([a, a + 1, b, b, a + 1, b + 1]);
    }
  }

  if (caps) {
    void cap(double r, double y, double ny) {
      if (r <= 0) return;
      final center = positions.length ~/ 3;
      positions.addAll([0, y, 0]);
      normals.addAll([0, ny, 0]);
      uvs.addAll([0.5, 0.5]);
      for (var x = 0; x <= radialSegments; x++) {
        final theta = x / radialSegments * math.pi * 2;
        positions.addAll([r * math.sin(theta), y, r * math.cos(theta)]);
        normals.addAll([0, ny, 0]);
        uvs.addAll([0.5 + 0.5 * math.sin(theta), 0.5 + 0.5 * math.cos(theta)]);
      }
      for (var x = 0; x < radialSegments; x++) {
        final a = center + 1 + x;
        // 上蓋は +Y、下蓋は -Y を表にする
        if (ny > 0) {
          indices.addAll([center, a, a + 1]);
        } else {
          indices.addAll([center, a + 1, a]);
        }
      }
    }

    cap(bottomRadius, yStart, -1);
    cap(topRadius, yStart + height, 1);
  }

  return MeshData(
    positions: Float32List.fromList(positions),
    vertexCount: positions.length ~/ 3,
    normals: Float32List.fromList(normals),
    texCoords: Float32List.fromList(uvs),
    indices: indices,
  );
}

/// 上半分（極から [thetaLength] ラジアンまで）だけの球面。クラゲの傘に使う。
///
/// UV の v は極で 1、縁に向かって減る（three.js の SphereGeometry と同じ向き）。
MeshData domeMeshData({
  required double radius,
  required double thetaLength,
  int widthSegments = 24,
  int heightSegments = 18,
}) {
  final positions = <double>[];
  final normals = <double>[];
  final uvs = <double>[];
  final indices = <int>[];

  for (var iy = 0; iy <= heightSegments; iy++) {
    final v = iy / heightSegments;
    final theta = v * thetaLength;
    for (var ix = 0; ix <= widthSegments; ix++) {
      final u = ix / widthSegments;
      final phi = u * math.pi * 2;
      final nx = math.sin(theta) * math.cos(phi);
      final ny = math.cos(theta);
      final nz = math.sin(theta) * math.sin(phi);
      positions.addAll([nx * radius, ny * radius, nz * radius]);
      normals.addAll([nx, ny, nz]);
      uvs.addAll([u, 1 - v]);
    }
  }
  final row = widthSegments + 1;
  for (var iy = 0; iy < heightSegments; iy++) {
    for (var ix = 0; ix < widthSegments; ix++) {
      final a = iy * row + ix;
      final b = a + row;
      indices.addAll([a, b, a + 1, a + 1, b, b + 1]);
    }
  }

  return MeshData(
    positions: Float32List.fromList(positions),
    vertexCount: positions.length ~/ 3,
    normals: Float32List.fromList(normals),
    texCoords: Float32List.fromList(uvs),
    indices: indices,
  );
}

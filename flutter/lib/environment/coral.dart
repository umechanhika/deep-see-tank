import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/color.dart';
import '../core/geometry_utils.dart';

const List<int> _coralColors = [0xff7fa8, 0xffa24f, 0xf0e6e0]; // ピンク / オレンジ / 白

class _Segment {
  _Segment(this.start, this.end, this.depth);
  final vm.Vector3 start;
  final vm.Vector3 end;
  final int depth;
}

/// L-system ベースの珊瑚。成長度(0〜1)に応じて反復回数を変え、
/// 枝分かれする形状を再構築する。
class Coral {
  Coral(vm.Vector3 position, double scale, this._rng)
    : _angle = (22 + _rng.nextDouble() * 10) * (math.pi / 180),
      _segLength = 0.55 * scale {
    final color = linearRgb(_coralColors[_rng.nextInt(_coralColors.length)]);
    _material = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(color.x, color.y, color.z, 1)
      ..roughnessFactor = 0.45
      ..metallicFactor = 0.05
      ..emissiveFactor = vm.Vector4(
        color.x * 0.12,
        color.y * 0.12,
        color.z * 0.12,
        1,
      );
    node
      ..position = position
      ..scale = vm.Vector3.all(scale);
  }

  final Node node = Node(name: 'coral')..raycastable = false;
  final math.Random _rng;
  final double _angle;
  final double _segLength;
  static const int _maxIter = 4;

  late final PhysicallyBasedMaterial _material;
  double _growthLevel = 0;
  Node? _meshNode;

  /// ロード時などに成長度を直接設定する。
  void setGrowth(double level) {
    _growthLevel = level.clamp(0.0, 1.0);
    _rebuild();
  }

  /// L-system 文字列を生成する。A=成長点。
  static String _generate(int iterations) {
    var s = 'A';
    for (var i = 0; i < iterations; i++) {
      final next = StringBuffer();
      for (final c in s.split('')) {
        next.write(c == 'A' ? 'F[+A][-A][&A]' : c);
      }
      s = next.toString();
    }
    return s;
  }

  void _rebuild() {
    final old = _meshNode;
    if (old != null) {
      node.remove(old);
      _meshNode = null;
    }
    final iterations = (_growthLevel * _maxIter).floor();
    if (iterations == 0) return;

    final segments = _interpret(_generate(iterations));
    if (segments.isEmpty) return;

    final merged = MeshData.merge([
      for (final seg in segments) _segmentMeshData(seg),
    ]);
    _meshNode = Node(mesh: Mesh(MeshGeometry.fromMeshData(merged), _material))
      ..raycastable = false;
    node.add(_meshNode!);
  }

  /// タートルグラフィクスで L-system 文字列を 3D の枝に変換する。
  List<_Segment> _interpret(String commands) {
    final segments = <_Segment>[];
    var pos = vm.Vector3.zero();
    var orient = vm.Quaternion.identity(); // 初期前方は +Y
    final stack = <(vm.Vector3, vm.Quaternion, int)>[];
    var depth = 0;

    final yaw = vm.Vector3(0, 0, 1);
    final pitch = vm.Vector3(1, 0, 0);
    final up = vm.Vector3(0, 1, 0);

    for (final c in commands.split('')) {
      switch (c) {
        case 'F':
          final dir = orient.rotated(up)..scale(_segLength);
          final start = pos.clone();
          pos = pos + dir;
          segments.add(_Segment(start, pos.clone(), depth));
        case '+':
          orient = orient * vm.Quaternion.axisAngle(yaw, _angle);
        case '-':
          orient = orient * vm.Quaternion.axisAngle(yaw, -_angle);
        case '&':
          orient = orient * vm.Quaternion.axisAngle(pitch, _angle);
        case '[':
          stack.add((pos.clone(), orient.clone(), depth));
          // 枝ごとにランダムなロールを加えて立体的に広げる
          orient =
              orient *
              vm.Quaternion.axisAngle(up, _rng.nextDouble() * math.pi * 2);
          depth++;
        case ']':
          final (p, o, d) = stack.removeLast();
          pos = p;
          orient = o;
          depth = d;
      }
    }
    return segments;
  }

  /// 1本の枝を、太さが先細りする円柱にする。
  MeshData _segmentMeshData(_Segment seg) {
    final len = seg.start.distanceTo(seg.end);
    final baseR = 0.12 / (seg.depth + 1) + 0.02;
    final topR = baseR * 0.7;
    final cylinder = cylinderMeshData(
      bottomRadius: baseR,
      topRadius: topR,
      height: len,
      radialSegments: 5,
    );
    // 円柱(初期+Y)を枝の向きに合わせて配置
    final dir = (seg.end - seg.start)..normalize();
    final q = vm.Quaternion.fromTwoVectors(vm.Vector3(0, 1, 0), dir);
    final m = vm.Matrix4.compose(seg.start, q, vm.Vector3.all(1));
    return cylinder.transformed(m);
  }
}

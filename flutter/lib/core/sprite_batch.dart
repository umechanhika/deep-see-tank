import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'color.dart';
import 'soft_particle.dart';

/// 加算合成で光る点群。three.js 版の Points + PointsMaterial に相当する。
///
/// カメラを向く四角形(ビルボード)を 1 回の描画でまとめて描く。
class SpriteBatch {
  SpriteBatch({
    required this.capacity,
    required int color,
    required this.size,
    required double opacity,
    String name = 'sprites',
  }) : _geometry = BillboardGeometry(capacity: capacity),
       _material = SpriteMaterial(colorTexture: softParticleTexture())
         ..blendMode = SpriteBlendMode.additive {
    _color = linearRgb(color);
    this.opacity = opacity;
    node = Node(name: name, mesh: Mesh(_geometry, _material))
      ..raycastable = false
      ..frustumCulled = false;
  }

  final int capacity;

  /// 1 粒の大きさ。three.js 版の PointsMaterial.size と同じ値を受け取る。
  final double size;

  /// three.js の点は「size × 画面高さの半分 ÷ 奥行き」ピクセルで描かれる。
  /// 視野角 50° のカメラでこれと同じ見た目になるワールド単位の一辺は size × tan(25°)。
  static final double _pointSizeToWorld = math.tan(25 * math.pi / 180);

  final BillboardGeometry _geometry;
  final SpriteMaterial _material;
  late final vm.Vector3 _color;
  late final Node node;

  final vm.Vector3 _center = vm.Vector3.zero();
  late final double _worldSize = size * _pointSizeToWorld;

  /// 全体の不透明度。加算合成なので明るさとして効く。
  set opacity(double value) {
    _material.tint = vm.Vector4(_color.x, _color.y, _color.z, value);
  }

  /// [index] 番目の粒を [x], [y], [z] に置く。描画に反映するには [commit] を呼ぶ。
  void set(int index, double x, double y, double z) {
    _center.setValues(x, y, z);
    _geometry.setInstance(
      index,
      center: _center,
      width: _worldSize,
      height: _worldSize,
    );
  }

  /// 先頭から [count] 個の粒を描画対象として確定する。
  void commit(int count) => _geometry.commit(count);
}

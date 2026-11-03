import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/color.dart';
import '../core/constants.dart';

/// 水槽内部を満たす水のボリューム。
/// 箱の内側にグラデーション＋ゴッドレイのシェーダーを貼り、
/// 水中にいる雰囲気を作る。
class Water {
  Water._(this.node, this._material);

  static Future<Water> create() async {
    final material = await loadFmatMaterial('assets/materials/water.fmat');
    material.parameters
      ..setVec3('deep_color', linearRgb(SeaColors.deep))
      ..setVec3('light_color', linearRgb(SeaColors.light))
      // three.js 版は表示色のまま背景色と合成していたため、背景色は線形化せずに渡す
      ..setVec3('background_color', srgbRgb(SeaColors.fog))
      ..setFloat('tank_height', Tank.height);
    final node = Node(
      name: 'water',
      mesh: Mesh(
        CuboidGeometry(vm.Vector3(Tank.width, Tank.height, Tank.depth)),
        material,
      ),
    )..raycastable = false;
    return Water._(node, material);
  }

  final Node node;
  final PreprocessedMaterial _material;

  void update(double time) {
    _material.parameters.setFloat('time', time);
  }
}

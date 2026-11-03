import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/color.dart';
import '../core/constants.dart';

/// 水槽のガラス筐体。外側から見ると薄く反射するガラスで、
/// 中の生態系が透けて見える。枠のエッジを淡く光らせて輪郭を出す。
class TankGlass {
  TankGlass() {
    // three.js 版は透過(transmission)マテリアルを使っていたが、
    // Web では透過のための画面キャプチャが重いため、薄い半透明＋クリアコートで近似する。
    final glass = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.55, 0.7, 0.85, 0.06)
      ..alphaMode = AlphaMode.blend
      ..metallicFactor = 0
      ..roughnessFactor = 0.05;
    node.add(
      Node(
        name: 'tank-glass',
        mesh: Mesh(
          CuboidGeometry(vm.Vector3(Tank.width, Tank.height, Tank.depth)),
          glass,
        ),
      )..raycastable = false,
    );

    node.add(_buildFrame());
  }

  final Node node = Node(name: 'tank');

  /// 12 本の辺を細い角柱で描く。
  Node _buildFrame() {
    const t = 0.05; // 枠の太さ
    const hx = Tank.width / 2;
    const hy = Tank.height / 2;
    const hz = Tank.depth / 2;
    final material = UnlitMaterial()
      ..baseColorFactor = linearRgba(0x2a4d6e, 0.35)
      ..alphaMode = AlphaMode.blend;

    final frame = Node(name: 'tank-frame')..raycastable = false;
    void edge(vm.Vector3 size, vm.Vector3 center) {
      frame.add(
        Node(mesh: Mesh(CuboidGeometry(size), material))
          ..position = center
          ..raycastable = false,
      );
    }

    // X 方向の辺（角は Y/Z 方向の辺と重ならないよう長さを詰める）
    for (final y in [-hy, hy]) {
      for (final z in [-hz, hz]) {
        edge(vm.Vector3(Tank.width - t, t, t), vm.Vector3(0, y, z));
      }
    }
    // Y 方向の辺
    for (final x in [-hx, hx]) {
      for (final z in [-hz, hz]) {
        edge(vm.Vector3(t, Tank.height + t, t), vm.Vector3(x, 0, z));
      }
    }
    // Z 方向の辺
    for (final x in [-hx, hx]) {
      for (final y in [-hy, hy]) {
        edge(vm.Vector3(t, t, Tank.depth - t), vm.Vector3(x, y, 0));
      }
    }
    return frame;
  }
}

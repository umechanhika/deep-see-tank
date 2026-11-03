import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/color.dart';
import '../core/constants.dart';

/// 深海の薄明かり。上方から差し込む弱い指向性光と、
/// 全体を持ち上げる僅かな環境光、手前の補助光で構成する。
class SeaLighting {
  SeaLighting(Scene scene) {
    // 環境光: 一様な拡散放射。照度 = 色 × 強さ なので放射輝度は π で割る。
    final ambient = linearRgb(SeaColors.light) * (0.35 / math.pi);
    scene.environment = EnvironmentMap.constantDiffuse(ambient);

    // 水面から差し込む光（three.js 版の位置 (2, H, 4) から原点へ向かう向き）。
    // カメラを -Z 側に置くため、Z を反転して手前上方から差し込ませる。
    scene.directionalLight = DirectionalLight(
      direction: vm.Vector3(-2, -Tank.height, 4).normalized(),
      color: linearRgb(0x3a6ea5),
      intensity: 1.1,
    );

    // 手前を僅かに照らす補助光
    node.add(
      Node(name: 'fill-light')
        ..position = vm.Vector3(0, 2, -Tank.depth)
        ..addComponent(
          PointLightComponent(
            PointLight(
              color: linearRgb(0x1a4a7a),
              intensity: 0.6,
              range: Tank.width * 2,
              falloffExponent: 1.5,
            ),
          ),
        ),
    );
  }

  final Node node = Node(name: 'lighting');
}

import 'dart:math' as math;

import 'package:vector_math/vector_math.dart' as vm;

/// sRGB の 1 チャンネル(0〜1)を線形値へ変換する。
double srgbToLinear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

/// 0xRRGGBB を線形 RGB に変換する。マテリアルやライトは線形値を受け取るため。
vm.Vector3 linearRgb(int hex) => vm.Vector3(
  srgbToLinear(((hex >> 16) & 0xff) / 255),
  srgbToLinear(((hex >> 8) & 0xff) / 255),
  srgbToLinear((hex & 0xff) / 255),
);

/// 0xRRGGBB を sRGB のまま 0〜1 に正規化する（線形化しない）。
vm.Vector3 srgbRgb(int hex) => vm.Vector3(
  ((hex >> 16) & 0xff) / 255,
  ((hex >> 8) & 0xff) / 255,
  (hex & 0xff) / 255,
);

/// 0xRRGGBB と不透明度から線形 RGBA を作る。
vm.Vector4 linearRgba(int hex, [double alpha = 1]) {
  final c = linearRgb(hex);
  return vm.Vector4(c.x, c.y, c.z, alpha);
}

import 'package:vector_math/vector_math.dart' as vm;

/// 水槽の内寸（中心が原点）。生き物の遊泳範囲もこれを基準にする。
abstract final class Tank {
  static const double width = 24;
  static const double height = 16;
  static const double depth = 14;
}

/// 水槽内部の遊泳可能な境界（壁から少し内側に余白を取る）。
vm.Aabb3 tankBounds([double margin = 1.5]) {
  final hx = Tank.width / 2 - margin;
  final hy = Tank.height / 2 - margin;
  final hz = Tank.depth / 2 - margin;
  return vm.Aabb3.minMax(vm.Vector3(-hx, -hy, -hz), vm.Vector3(hx, hy, hz));
}

/// 各フェーズに到達するまでの累計プレイ時間（秒）。
const Map<int, double> phaseThresholds = {
  1: 0, // 開始直後: プランクトン
  2: 5 * 60, // 5分後: クラゲ出現
  3: 15 * 60, // 15分後: 魚の群れ
  4: 30 * 60, // 30分後: 深海魚
  5: 60 * 60, // 60分後: 完成形
};

const int maxPhase = 5;

/// 経過時間からフェーズ番号を求める。
int phaseForTime(double totalPlayTime) {
  var phase = 1;
  for (var p = 1; p <= maxPhase; p++) {
    if (totalPlayTime >= phaseThresholds[p]!) phase = p;
  }
  return phase;
}

/// オフライン放置で反映する最大時間（24時間）。
const double maxOfflineSeconds = 24 * 60 * 60;

/// 深海の色定義（sRGB の 16 進）。
abstract final class SeaColors {
  static const int deep = 0x020b18;
  static const int light = 0x0d3b6e;
  static const int fog = 0x03101f;
}

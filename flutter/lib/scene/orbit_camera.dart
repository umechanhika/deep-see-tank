import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// 水槽の周りを回るカメラ。three.js 版の OrbitControls の設定を再現する。
///
/// - ドラッグで回転、ホイール/ピンチで距離を変える。
/// - 操作には慣性(ダンピング)が付く。
/// - 操作しなければ自動でゆっくり回る。一度でも操作したら自動回転は止める。
/// - 真上・真下からの回り込みを制限して水槽らしい視点を保つ。
class OrbitCamera {
  static const double fovDegrees = 50;
  static const double minDistance = 12;
  static const double maxDistance = 40;
  static const double minPolar = math.pi * 0.25;
  static const double maxPolar = math.pi * 0.72;
  static const double rotateSpeed = 0.4;
  static const double dampingFactor = 0.05;

  /// 自動回転の角速度（rad/秒）。OrbitControls の autoRotateSpeed 0.25 相当。
  static const double autoRotateSpeed = 2 * math.pi / 60 * 0.25;

  final vm.Vector3 target = vm.Vector3.zero();

  // three.js 版の初期位置 (0, 1, 26) に相当する球面座標。
  // このエンジンは -Z 側から +Z を見ると世界の +X が画面右になるため、Z を反転して置く。
  double _distance = math.sqrt(1 + 26 * 26);
  double _polar = math.acos(1 / math.sqrt(1 + 26 * 26));
  double _azimuth = math.pi;

  double _azimuthVelocity = 0;
  double _polarVelocity = 0;
  bool autoRotate = true;

  /// ドラッグ量(論理ピクセル)を回転として加える。[viewHeight] は表示領域の高さ。
  void rotateBy(double dx, double dy, double viewHeight) {
    autoRotate = false;
    _azimuthVelocity -= 2 * math.pi * dx / viewHeight * rotateSpeed;
    _polarVelocity -= 2 * math.pi * dy / viewHeight * rotateSpeed;
  }

  /// 距離を [scale] 倍にする（1 より小さいと近づく）。
  void dollyBy(double scale) {
    autoRotate = false;
    _distance = (_distance * scale).clamp(minDistance, maxDistance);
  }

  void update(double delta) {
    if (autoRotate) _azimuth -= autoRotateSpeed * delta;

    // OrbitControls と同じく「1 フレームで速度の dampingFactor 分だけ進む」を
    // フレームレートに依存しない形にしたもの
    final frames = delta * 60;
    final step = 1 - math.pow(1 - dampingFactor, frames).toDouble();
    final moveAz = _azimuthVelocity * step;
    final movePolar = _polarVelocity * step;
    _azimuthVelocity -= moveAz;
    _polarVelocity -= movePolar;
    _azimuth += moveAz;
    _polar = (_polar + movePolar).clamp(minPolar, maxPolar);
  }

  vm.Vector3 get position =>
      target +
      vm.Vector3(
        _distance * math.sin(_polar) * math.sin(_azimuth),
        _distance * math.cos(_polar),
        _distance * math.sin(_polar) * math.cos(_azimuth),
      );

  /// 現在の視点からカメラを作る。
  PerspectiveCamera build() => PerspectiveCamera(
    fovRadiansY: fovDegrees * vm.degrees2Radians,
    position: position,
    target: target.clone(),
    fovNear: 0.1,
    fovFar: 200,
  );
}

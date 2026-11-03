import 'dart:math' as math;

/// 3D シンプレックスノイズ（Stefan Gustavson の実装を Dart に移植）。
///
/// 生き物の遊泳や海底の凹凸など、自然な揺らぎに使う。
/// 整数ハッシュを使わず double だけで計算するため、Web(dart2js)でも
/// ネイティブと同じ値になる。
class SimplexNoise {
  SimplexNoise([math.Random? random]) {
    final rng = random ?? math.Random();
    final p = List<int>.generate(256, (i) => i);
    for (var i = 255; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final t = p[i];
      p[i] = p[j];
      p[j] = t;
    }
    for (var i = 0; i < 512; i++) {
      _perm[i] = p[i & 255];
      _permMod12[i] = _perm[i] % 12;
    }
  }

  final List<int> _perm = List<int>.filled(512, 0);
  final List<int> _permMod12 = List<int>.filled(512, 0);

  static const List<List<double>> _grad3 = [
    [1, 1, 0],
    [-1, 1, 0],
    [1, -1, 0],
    [-1, -1, 0],
    [1, 0, 1],
    [-1, 0, 1],
    [1, 0, -1],
    [-1, 0, -1],
    [0, 1, 1],
    [0, -1, 1],
    [0, 1, -1],
    [0, -1, -1],
  ];

  static const double _f3 = 1 / 3;
  static const double _g3 = 1 / 6;

  /// -1〜1 のノイズ値を返す。
  double noise3(double xin, double yin, double zin) {
    final s = (xin + yin + zin) * _f3;
    final i = (xin + s).floor();
    final j = (yin + s).floor();
    final k = (zin + s).floor();
    final t = (i + j + k) * _g3;
    final x0 = xin - (i - t);
    final y0 = yin - (j - t);
    final z0 = zin - (k - t);

    int i1, j1, k1, i2, j2, k2;
    if (x0 >= y0) {
      if (y0 >= z0) {
        i1 = 1;
        j1 = 0;
        k1 = 0;
        i2 = 1;
        j2 = 1;
        k2 = 0;
      } else if (x0 >= z0) {
        i1 = 1;
        j1 = 0;
        k1 = 0;
        i2 = 1;
        j2 = 0;
        k2 = 1;
      } else {
        i1 = 0;
        j1 = 0;
        k1 = 1;
        i2 = 1;
        j2 = 0;
        k2 = 1;
      }
    } else {
      if (y0 < z0) {
        i1 = 0;
        j1 = 0;
        k1 = 1;
        i2 = 0;
        j2 = 1;
        k2 = 1;
      } else if (x0 < z0) {
        i1 = 0;
        j1 = 1;
        k1 = 0;
        i2 = 0;
        j2 = 1;
        k2 = 1;
      } else {
        i1 = 0;
        j1 = 1;
        k1 = 0;
        i2 = 1;
        j2 = 1;
        k2 = 0;
      }
    }

    final x1 = x0 - i1 + _g3;
    final y1 = y0 - j1 + _g3;
    final z1 = z0 - k1 + _g3;
    final x2 = x0 - i2 + 2 * _g3;
    final y2 = y0 - j2 + 2 * _g3;
    final z2 = z0 - k2 + 2 * _g3;
    final x3 = x0 - 1 + 3 * _g3;
    final y3 = y0 - 1 + 3 * _g3;
    final z3 = z0 - 1 + 3 * _g3;

    final ii = i & 255;
    final jj = j & 255;
    final kk = k & 255;

    double corner(int gi, double x, double y, double z) {
      var tt = 0.6 - x * x - y * y - z * z;
      if (tt < 0) return 0;
      tt *= tt;
      final g = _grad3[gi];
      return tt * tt * (g[0] * x + g[1] * y + g[2] * z);
    }

    final n0 = corner(_permMod12[ii + _perm[jj + _perm[kk]]], x0, y0, z0);
    final n1 = corner(
      _permMod12[ii + i1 + _perm[jj + j1 + _perm[kk + k1]]],
      x1,
      y1,
      z1,
    );
    final n2 = corner(
      _permMod12[ii + i2 + _perm[jj + j2 + _perm[kk + k2]]],
      x2,
      y2,
      z2,
    );
    final n3 = corner(
      _permMod12[ii + 1 + _perm[jj + 1 + _perm[kk + 1]]],
      x3,
      y3,
      z3,
    );

    return 32 * (n0 + n1 + n2 + n3);
  }
}

/// アプリ全体で共有するノイズ。
final SimplexNoise noise = SimplexNoise();

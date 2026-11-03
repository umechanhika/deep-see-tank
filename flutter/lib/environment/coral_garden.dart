import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/constants.dart';
import '../core/game_state.dart';
import 'coral.dart';

/// 海底に配置した複数の珊瑚をまとめて成長させる。
/// 成長度は GameState の珊瑚成長度に同期し、時間と餌やりで進む。
class CoralGarden {
  CoralGarden(this._state, math.Random rng) {
    const floor = -Tank.height / 2;
    const spots = 5;
    for (var i = 0; i < spots; i++) {
      final x = (rng.nextDouble() - 0.5) * (Tank.width - 6);
      final z = (rng.nextDouble() - 0.5) * (Tank.depth - 6);
      final scale = 1.4 + rng.nextDouble() * 1.0;
      final coral = Coral(vm.Vector3(x, floor, z), scale, rng);
      _corals.add(coral);
      node.add(coral.node);
    }
    _syncGrowth();
  }

  final GameState _state;
  final Node node = Node(name: 'coral-garden');
  final List<Coral> _corals = [];
  int _appliedStage = -1;

  /// 餌やりなどで成長を進める。
  void grow(double amount) {
    _state.data.coralGrowth = math.min(1, _state.data.coralGrowth + amount);
    _syncGrowth();
  }

  /// プレイ時間に応じた緩やかな自然成長（1時間でほぼ満開）。
  void update(double delta) {
    if (_state.data.coralGrowth < 1) {
      _state.data.coralGrowth = math.min(
        1,
        _state.data.coralGrowth + delta / 3600,
      );
      _syncGrowth();
    }
  }

  /// 成長段階が変わったときだけ形状を作り直す。
  void _syncGrowth() {
    final g = _state.data.coralGrowth;
    // 4段階のしきい値をまたいだときのみ再構築（負荷抑制）
    final stage = (g * 4).floor();
    if (stage == _appliedStage) return;
    _appliedStage = stage;
    for (final c in _corals) {
      c.setGrowth(g);
    }
  }
}

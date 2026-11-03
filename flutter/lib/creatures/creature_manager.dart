import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/constants.dart';
import '../core/game_state.dart';
import 'creature_info.dart';
import 'deep_sea_fish.dart';
import 'fish_school.dart';
import 'jellyfish.dart';
import 'plankton.dart';

const int _maxJellyfish = 5;
const int _maxFish = 30;
const int _maxDeepSea = 4;

/// 生き物の出現・更新を統括する。
/// 累計プレイ時間から各種の目標数を算出し、増減を反映する。
class CreatureManager {
  CreatureManager(this._state, this._rng)
    : plankton = Plankton(_rng),
      fishSchool = FishSchool(_rng, maxCount: _maxFish) {
    node
      ..add(plankton.batch.node)
      ..add(fishSchool.node);
  }

  final GameState _state;
  final math.Random _rng;
  final Plankton plankton;
  final FishSchool fishSchool;
  final Node node = Node(name: 'creatures');

  final List<Jellyfish> _jellyfish = [];
  final List<DeepSeaFish> _deepSeaFish = [];

  /// ホバー判定に使う、生き物のルートノードと情報の対応。
  final Map<Node, CreatureInfo> creatureInfo = {};

  /// クラゲは素材の読み込みが非同期のため、生成中の重複を防ぐ。
  bool _spawningJellyfish = false;

  /// 累計プレイ時間に応じて各生き物の目標数を返す。
  static ({int jelly, int fish, int deep}) _targets(double t) => (
    jelly: t >= 300
        ? math.min(_maxJellyfish, 1 + ((t - 300) / 300).floor())
        : 0,
    fish: t >= 900 ? math.min(_maxFish, 10 + ((t - 900) / 60).floor()) : 0,
    deep: t >= 1800 ? math.min(_maxDeepSea, 1 + ((t - 1800) / 300).floor()) : 0,
  );

  /// ランダムな遊泳開始位置を返す。
  vm.Vector3 _randomSpawn() {
    final b = tankBounds(2.5);
    final s = b.max - b.min;
    return vm.Vector3(
      b.min.x + _rng.nextDouble() * s.x,
      b.min.y + _rng.nextDouble() * s.y,
      b.min.z + _rng.nextDouble() * s.z,
    );
  }

  /// 放置復帰時などに、現在の経過時間へ即座に個体数を合わせる。
  Future<void> syncToTime(double totalPlayTime) async {
    final t = _targets(totalPlayTime);
    while (_jellyfish.length < t.jelly) {
      await _spawnJellyfish();
    }
    while (_deepSeaFish.length < t.deep) {
      _spawnDeepSeaFish();
    }
    fishSchool.setCount(t.fish);
    _writeCounts();
  }

  Future<void> _spawnJellyfish() async {
    _spawningJellyfish = true;
    try {
      final j = await Jellyfish.create(_randomSpawn(), _rng);
      creatureInfo[j.node] = const CreatureInfo(
        name: 'ミズクラゲ',
        kind: 'jellyfish',
      );
      _jellyfish.add(j);
      node.add(j.node);
      _writeCounts();
    } finally {
      _spawningJellyfish = false;
    }
  }

  void _spawnDeepSeaFish() {
    final d = DeepSeaFish(_randomSpawn(), _rng);
    creatureInfo[d.node] = const CreatureInfo(
      name: 'チョウチンアンコウ',
      kind: 'deepSeaFish',
    );
    _deepSeaFish.add(d);
    node.add(d.node);
    _writeCounts();
  }

  void _writeCounts() {
    _state.data.creatureCounts = CreatureCounts(
      jellyfish: _jellyfish.length,
      fish: fishSchool.count,
      deepSeaFish: _deepSeaFish.length,
    );
  }

  /// 餌やり: 指定座標へ生き物を引き寄せる。
  void feed(vm.Vector3 point) => fishSchool.attract(point, 0.12);

  void update(double delta, double time, double totalPlayTime) {
    final t = _targets(totalPlayTime);
    if (_jellyfish.length < t.jelly && !_spawningJellyfish) {
      // 生成の失敗は握りつぶさず、そのまま例外として表に出す
      _spawnJellyfish();
    }
    if (_deepSeaFish.length < t.deep) _spawnDeepSeaFish();
    if (fishSchool.count != t.fish) {
      fishSchool.setCount(t.fish);
      _writeCounts();
    }

    plankton.update(delta, time);
    fishSchool.update(delta);
    for (final j in _jellyfish) {
      j.update(delta, time);
    }
    for (final d in _deepSeaFish) {
      d.update(delta, time);
    }
  }
}

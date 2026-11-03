import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart';

import 'core/color.dart';
import 'core/constants.dart';
import 'core/game_state.dart';
import 'creatures/creature_manager.dart';
import 'environment/bubbles.dart';
import 'environment/coral_garden.dart';
import 'environment/feed_effect.dart';
import 'environment/sea_floor.dart';
import 'scene/lighting.dart';
import 'scene/orbit_camera.dart';
import 'scene/tank_glass.dart';
import 'scene/water.dart';
import 'ui/ambient_audio.dart';
import 'ui/creature_tooltip.dart';
import 'ui/hud.dart';
import 'ui/phase_transition.dart';

const double _autosaveInterval = 30; // 秒
const double _hudInterval = 0.25; // 秒

/// ゲーム全体のオーケストレーター。
/// シーン構築・状態管理・更新ループ・入力・UI 用の値・セーブをまとめる。
class DeepSeaGame {
  DeepSeaGame._(this.state, this.scene, this._water, this._rng)
    : _bubbles = Bubbles(_rng),
      _feed = FeedEffect(_rng),
      _corals = CoralGarden(state, _rng),
      _creatures = CreatureManager(state, _rng);

  /// エンジンの初期化とシーン構築を行い、遊べる状態のゲームを返す。
  static Future<DeepSeaGame> create() async {
    final state = await GameState.load();
    await Scene.initializeStaticResources();
    final scene = Scene();
    final water = await Water.create();
    final game = DeepSeaGame._(state, scene, water, math.Random());
    await game._build();
    return game;
  }

  final GameState state;
  final Scene scene;
  final math.Random _rng;
  final Water _water;
  final Bubbles _bubbles;
  final FeedEffect _feed;
  final CoralGarden _corals;
  final CreatureManager _creatures;

  final OrbitCamera orbit = OrbitCamera();
  final AmbientAudio audio = AmbientAudio();
  final PhaseTransitionController phaseTransition = PhaseTransitionController();

  late final ValueNotifier<HudData> hud = ValueNotifier(_hudData());
  final ValueNotifier<TooltipData?> tooltip = ValueNotifier(null);

  double _elapsed = 0;
  double _saveTimer = 0;
  double _hudTimer = 0;
  ui.Size _viewSize = ui.Size.zero;
  ui.Offset? _hoverPosition;

  Future<void> _build() async {
    // 深海の濁りを指数フォグで表現
    scene.fog
      ..enabled = true
      ..mode = FogMode.exponentialSquared
      ..color = linearRgb(SeaColors.fog)
      ..density = 0.022;
    // three.js 版はトーンマッピングなしで描いていたため、色をそのまま出す
    scene.toneMapping = ToneMappingMode.linear;

    scene.add(SeaLighting(scene).node);
    scene
      ..add(_water.node)
      ..add(TankGlass().node)
      ..add(SeaFloor(_rng).node)
      ..add(_bubbles.batch.node)
      ..add(_corals.node)
      ..add(_creatures.node)
      ..add(_feed.batch.node);

    // フェーズ移行演出
    state.onPhaseChange((phase, _) => phaseTransition.play(phase));

    // 放置時間を累計に反映してから生態系を現在へ追いつかせる
    state.addPlayTime(state.elapsedSinceLastSession());
    await _creatures.syncToTime(state.data.totalPlayTime);
    hud.value = _hudData();
  }

  /// 現在の視点のカメラ。
  PerspectiveCamera camera() => orbit.build();

  /// 1 フレーム分ゲームを進める。[delta] は前フレームからの経過秒。
  void tick(double delta, ui.Size viewSize) {
    // タブ復帰直後などの巨大な差分でシミュレーションが飛ばないよう抑える
    final dt = math.min(delta, 0.1);
    _elapsed += dt;
    _viewSize = viewSize;

    state.addPlayTime(dt);
    orbit.update(dt);

    _water.update(_elapsed);
    _bubbles.update(dt, _elapsed);
    _corals.update(dt);
    _creatures.update(dt, _elapsed, state.data.totalPlayTime);
    _feed.update(dt);

    _updateHover();

    _hudTimer += dt;
    if (_hudTimer >= _hudInterval) {
      _hudTimer = 0;
      hud.value = _hudData();
    }

    // オートセーブ
    _saveTimer += dt;
    if (_saveTimer >= _autosaveInterval) {
      _saveTimer = 0;
      save();
    }
  }

  Future<void> save() => state.save();

  HudData _hudData() => HudData(
    phase: state.data.phase,
    phaseProgress: state.phaseProgress,
    coralGrowth: state.data.coralGrowth,
    totalPlayTime: state.data.totalPlayTime,
  );

  // --- 入力 ---

  /// ポインタが画面に触れた。環境音の自動再生制限の解除を兼ねる。
  void pointerDown() => audio.start();

  void hover(ui.Offset? position) => _hoverPosition = position;

  /// クリック地点を水中の点へ変換し、餌をまく。
  void feedAt(ui.Offset screen) {
    if (_viewSize.isEmpty) return;
    final ray = camera().screenPointToRay(screen, _viewSize);
    // three.js 版と同じく、水槽の中心を通りカメラの初期向きに垂直な面(z = 0)で受ける
    if (ray.direction.z.abs() < 1e-6) return;
    final t = -ray.origin.z / ray.direction.z;
    if (t < 0) return;
    final b = tankBounds(1.5);
    final hit = (ray.origin + ray.direction * t)..clamp(b.min, b.max);

    _feed.spawn(hit);
    _creatures.feed(hit);
    _corals.grow(0.01); // 餌やりで少し成長
    hud.value = _hudData();
  }

  /// ホバー中の生き物を判定してツールチップを出す。
  void _updateHover() {
    final pos = _hoverPosition;
    if (pos == null || _viewSize.isEmpty) {
      tooltip.value = null;
      return;
    }
    final cam = camera();
    final ray = cam.screenPointToRay(pos, _viewSize);
    final hit = scene.raycast(
      ray,
      where: (node) => _creatureRoot(node) != null,
    );
    final root = hit == null ? null : _creatureRoot(hit.node);
    final info = root == null ? null : _creatures.creatureInfo[root];
    if (root == null || info == null) {
      tooltip.value = null;
      return;
    }
    final screen = cam.worldToScreen(
      root.globalTransform.getTranslation(),
      _viewSize,
    );
    if (screen == null) {
      // カメラ背面に回ったら隠す
      tooltip.value = null;
      return;
    }
    final level = 1 + (state.data.coralGrowth * 4).floor();
    tooltip.value = TooltipData(info: info, level: level, position: screen);
  }

  /// ヒットしたノードから、生き物の情報を持つ親を辿る。
  Node? _creatureRoot(Node node) {
    Node? n = node;
    while (n != null) {
      if (_creatures.creatureInfo.containsKey(n)) return n;
      n = n.parent;
    }
    return null;
  }

  /// 中心からの距離を [scale] 倍にする。
  void zoom(double scale) => orbit.dollyBy(scale);
}

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:web/web.dart' as web;

import 'deep_sea_game.dart';
import 'ui/creature_tooltip.dart';
import 'ui/hud.dart';
import 'ui/phase_transition.dart';

const Color _background = Color(0xFF01060F);

void main() {
  runApp(const DeepSeaTankApp());
}

class DeepSeaTankApp extends StatelessWidget {
  const DeepSeaTankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deep Sea Tank — 深海水槽',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _background,
        // 日本語は同梱の部分フォントで描く（tool/subset_fonts.py を参照）
        fontFamily: 'JetBrainsMono',
        fontFamilyFallback: const ['NotoSansJP'],
      ),
      home: const TankPage(),
    );
  }
}

/// ゲーム画面。読み込み中は「submerging…」を出し、準備ができたら水槽を表示する。
class TankPage extends StatefulWidget {
  const TankPage({super.key});

  @override
  State<TankPage> createState() => _TankPageState();
}

class _TankPageState extends State<TankPage> {
  late final Future<DeepSeaGame> _game = DeepSeaGame.create();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DeepSeaGame>(
        future: _game,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // 初期化の失敗は黙って続行せず、原因を画面に出す
            return _ErrorView(error: snapshot.error!);
          }
          final game = snapshot.data;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: game == null
                ? const _Loading()
                : _TankView(key: const ValueKey('tank'), game: game),
          );
        },
      ),
    );
  }
}

class _TankView extends StatefulWidget {
  const _TankView({super.key, required this.game});

  final DeepSeaGame game;

  @override
  State<_TankView> createState() => _TankViewState();
}

class _TankViewState extends State<_TankView> {
  static const double _clickMaxMove = 6; // px: これ以下なら「クリック」とみなす

  late final AppLifecycleListener _lifecycle;
  StreamSubscription<web.BeforeUnloadEvent>? _beforeUnload;
  Size _size = Size.zero;

  Offset? _downPosition;
  double _scaleBase = 1;

  DeepSeaGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      // タブが隠れたら保存する。復帰時の巨大な差分はゲーム側で抑える
      onHide: () => unawaited(game.save()),
    );
    _beforeUnload = web.EventStreamProviders.beforeUnloadEvent
        .forTarget(web.window)
        .listen((_) => unawaited(game.save()));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _beforeUnload?.cancel();
    unawaited(game.save());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF03101F)),
        LayoutBuilder(
          builder: (context, constraints) {
            _size = constraints.biggest;
            return Listener(
              onPointerDown: (e) {
                game.pointerDown();
                _downPosition = e.localPosition;
              },
              onPointerUp: (e) {
                final down = _downPosition;
                _downPosition = null;
                if (down != null &&
                    (e.localPosition - down).distance <= _clickMaxMove) {
                  game.feedAt(e.localPosition);
                }
              },
              onPointerSignal: (e) {
                if (e is PointerScrollEvent) {
                  // OrbitControls と同じく、ホイール 1 回で 0.95 倍ずつ寄る/離れる
                  game.zoom(e.scrollDelta.dy > 0 ? 1 / 0.95 : 0.95);
                }
              },
              child: MouseRegion(
                onHover: (e) => game.hover(e.localPosition),
                onExit: (_) => game.hover(null),
                child: GestureDetector(
                  onScaleStart: (_) => _scaleBase = 1,
                  onScaleUpdate: (d) {
                    if (d.pointerCount >= 2) {
                      // ピンチで距離を変える
                      game.zoom(_scaleBase / d.scale);
                      _scaleBase = d.scale;
                    } else {
                      game.orbit.rotateBy(
                        d.focalPointDelta.dx,
                        d.focalPointDelta.dy,
                        _size.height,
                      );
                    }
                  },
                  child: SceneView(
                    game.scene,
                    cameraBuilder: (_) => game.camera(),
                    onTick: (_, delta) => game.tick(delta, _size),
                  ),
                ),
              ),
            );
          },
        ),
        Hud(data: game.hud),
        CreatureTooltip(data: game.tooltip),
        PhaseTransition(controller: game.phaseTransition),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _background,
      child: Center(
        child: Text(
          'SUBMERGING…',
          style: TextStyle(
            color: Color(0xFF5B86B3),
            letterSpacing: 4,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '水槽の準備に失敗しました\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFFF9F9F), fontSize: 13),
          ),
        ),
      ),
    );
  }
}

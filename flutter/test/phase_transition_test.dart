import 'package:deep_see_tank/ui/phase_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('フェーズが上がるとメッセージを表示し、時間が経つと消す', (tester) async {
    final controller = PhaseTransitionController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PhaseTransition(controller: controller)),
      ),
    );

    controller.play(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));

    final text = find.text('新しい生き物が現れた… 発光クラゲ');
    expect(text, findsOneWidget);
    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(of: text, matching: find.byType(AnimatedOpacity)),
    );
    expect(opacity.opacity, 1);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.ancestor(of: text, matching: find.byType(AnimatedOpacity)),
          )
          .opacity,
      0,
    );
  });

  testWidgets('表示前に上がったフェーズも、表示した時点で演出する', (tester) async {
    final controller = PhaseTransitionController()..play(3);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PhaseTransition(controller: controller)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('新しい生き物が現れた… 魚の群れ'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });
}

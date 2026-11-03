import 'dart:convert';

import 'package:deep_see_tank/core/constants.dart';
import 'package:deep_see_tank/core/game_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameState> _stateWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return GameState.withPrefs(await SharedPreferences.getInstance());
}

void main() {
  group('phaseForTime', () {
    test('各フェーズのしきい値ちょうどで次のフェーズに入る', () {
      expect(phaseForTime(0), 1);
      expect(phaseForTime(5 * 60 - 0.001), 1);
      expect(phaseForTime(5 * 60), 2);
      expect(phaseForTime(15 * 60), 3);
      expect(phaseForTime(30 * 60), 4);
      expect(phaseForTime(60 * 60), 5);
      expect(phaseForTime(1e9), maxPhase);
    });
  });

  group('GameState', () {
    test('セーブが無ければ初期状態から始める', () async {
      final state = await _stateWith({});
      expect(state.data.totalPlayTime, 0);
      expect(state.data.phase, 1);
    });

    test('保存した内容を読み戻せる', () async {
      final state = await _stateWith({});
      state.data
        ..totalPlayTime = 1234
        ..coralGrowth = 0.4;
      state.addPlayTime(0);
      await state.save();

      final prefs = await SharedPreferences.getInstance();
      final restored = GameState.withPrefs(prefs);
      expect(restored.data.totalPlayTime, 1234);
      expect(restored.data.phase, 3);
      expect(restored.data.coralGrowth, 0.4);
    });

    test('壊れたセーブ・形式が不正なセーブは初期化する', () async {
      final broken = await _stateWith({GameState.storageKey: '{not json'});
      expect(broken.data.totalPlayTime, 0);

      final invalid = await _stateWith({
        GameState.storageKey: jsonEncode({'totalPlayTime': 'abc'}),
      });
      expect(invalid.data.totalPlayTime, 0);
    });

    test('フェーズが上がった瞬間だけ通知し、飛び越えたら到達先だけを通知する', () async {
      final state = await _stateWith({});
      final events = <(int, int)>[];
      state.onPhaseChange((phase, prev) => events.add((phase, prev)));

      state.addPlayTime(299);
      expect(events, isEmpty);
      state.addPlayTime(1);
      expect(events, [(2, 1)]);
      state.addPlayTime(30 * 60);
      expect(events, [(2, 1), (4, 2)]);
    });

    test('フェーズの進捗は区間内の割合、最終フェーズでは珊瑚の成長度', () async {
      final state = await _stateWith({});
      state.addPlayTime(10 * 60); // フェーズ2(5〜15分)の中間
      expect(state.phaseProgress, closeTo(0.5, 1e-9));

      state.addPlayTime(60 * 60);
      state.data.coralGrowth = 0.7;
      expect(state.phaseProgress, 0.7);
    });

    test('放置時間は前回セーブからの経過秒で、24時間で頭打ちになる', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final state = await _stateWith({});

      state.data.lastSavedAt = now - 90 * 1000;
      expect(state.elapsedSinceLastSession(), closeTo(90, 2));

      state.data.lastSavedAt = now - 3 * 24 * 3600 * 1000;
      expect(state.elapsedSinceLastSession(), maxOfflineSeconds);

      // 端末の時計が戻った場合でも負にはしない
      state.data.lastSavedAt = now + 60 * 1000;
      expect(state.elapsedSinceLastSession(), 0);
    });
  });
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// 生き物の個体数。
class CreatureCounts {
  CreatureCounts({this.jellyfish = 0, this.fish = 0, this.deepSeaFish = 0});

  int jellyfish;
  int fish;
  int deepSeaFish;

  Map<String, Object> toJson() => {
    'jellyfish': jellyfish,
    'fish': fish,
    'deepSeaFish': deepSeaFish,
  };
}

/// 永続化するセーブデータ。
class SaveData {
  SaveData({
    required this.totalPlayTime,
    required this.lastSavedAt,
    required this.phase,
    required this.coralGrowth,
    required this.creatureCounts,
  });

  factory SaveData.initial() => SaveData(
    totalPlayTime: 0,
    lastSavedAt: DateTime.now().millisecondsSinceEpoch,
    phase: 1,
    coralGrowth: 0,
    creatureCounts: CreatureCounts(),
  );

  static const int version = 1;

  double totalPlayTime; // 累計プレイ時間(秒)
  int lastSavedAt; // UNIXタイムスタンプ(ms)
  int phase; // 現在フェーズ(1〜5)
  double coralGrowth; // 珊瑚の成長度(0〜1)
  CreatureCounts creatureCounts;

  Map<String, Object> toJson() => {
    'version': version,
    'totalPlayTime': totalPlayTime,
    'lastSavedAt': lastSavedAt,
    'phase': phase,
    'coralGrowth': coralGrowth,
    'creatureCounts': creatureCounts.toJson(),
  };

  /// JSON から復元する。形式が不正なら null を返す。
  static SaveData? tryParse(Object? value) {
    if (value is! Map) return null;
    final counts = value['creatureCounts'];
    if (value['totalPlayTime'] is! num ||
        value['lastSavedAt'] is! num ||
        value['phase'] is! num ||
        value['coralGrowth'] is! num ||
        counts is! Map ||
        counts['jellyfish'] is! num ||
        counts['fish'] is! num ||
        counts['deepSeaFish'] is! num) {
      return null;
    }
    return SaveData(
      totalPlayTime: (value['totalPlayTime'] as num).toDouble(),
      lastSavedAt: (value['lastSavedAt'] as num).toInt(),
      phase: (value['phase'] as num).toInt(),
      coralGrowth: (value['coralGrowth'] as num).toDouble(),
      creatureCounts: CreatureCounts(
        jellyfish: (counts['jellyfish'] as num).toInt(),
        fish: (counts['fish'] as num).toInt(),
        deepSeaFish: (counts['deepSeaFish'] as num).toInt(),
      ),
    );
  }
}

/// ゲーム全体の永続状態。SharedPreferences（Web では localStorage）への
/// 保存・読み込みを担う。
/// フォールバックで握りつぶさず、復元に失敗したら理由を明示してから初期化する。
class GameState {
  GameState._(this._prefs, this.data);

  static const String storageKey = 'deep-see-tank/save';

  final SharedPreferences _prefs;
  SaveData data;

  /// フェーズが上がった瞬間に発火するコールバック群。
  final List<void Function(int phase, int prev)> _phaseListeners = [];

  static Future<GameState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return GameState._(prefs, _decode(prefs.getString(storageKey)));
  }

  /// テストなどで、保存先を指定して生成する。
  @visibleForTesting
  static GameState withPrefs(SharedPreferences prefs) =>
      GameState._(prefs, _decode(prefs.getString(storageKey)));

  static SaveData _decode(String? raw) {
    if (raw == null) return SaveData.initial();

    Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } on FormatException catch (err) {
      // 壊れたセーブを黙って無視すると原因不明の初期化になるため、必ず記録する
      debugPrint('[GameState] セーブデータのJSON解析に失敗しました。初期化します。 $err');
      return SaveData.initial();
    }

    final save = SaveData.tryParse(parsed);
    if (save == null) {
      debugPrint('[GameState] セーブデータの形式が不正です。初期化します。 $parsed');
      return SaveData.initial();
    }
    return save;
  }

  Future<void> save() {
    data.lastSavedAt = DateTime.now().millisecondsSinceEpoch;
    return _prefs.setString(storageKey, jsonEncode(data.toJson()));
  }

  Future<void> reset() {
    data = SaveData.initial();
    return _prefs.remove(storageKey);
  }

  /// 累計プレイ時間を進め、フェーズが上がっていればリスナーに通知する。
  void addPlayTime(double seconds) {
    data.totalPlayTime += seconds;
    final next = phaseForTime(data.totalPlayTime);
    if (next > data.phase) {
      final prev = data.phase;
      data.phase = next;
      for (final fn in _phaseListeners) {
        fn(next, prev);
      }
    }
  }

  void onPhaseChange(void Function(int phase, int prev) fn) {
    _phaseListeners.add(fn);
  }

  /// 現在フェーズの進捗(0〜1)。最終フェーズなら珊瑚の成長度を進捗とみなす。
  double get phaseProgress {
    final phase = data.phase;
    if (phase >= maxPhase) return data.coralGrowth;
    final start = phaseThresholds[phase]!;
    final end = phaseThresholds[phase + 1]!;
    return ((data.totalPlayTime - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// 前回セーブ時刻からの経過秒を返す（最大 [maxOfflineSeconds] まで）。
  /// 復帰時に一度だけ呼び、状態をスキップさせる用途。
  double elapsedSinceLastSession() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = ((now - data.lastSavedAt) / 1000).clamp(
      0.0,
      double.infinity,
    );
    return elapsed > maxOfflineSeconds ? maxOfflineSeconds : elapsed;
  }
}

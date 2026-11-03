import { MAX_PHASE, PHASE_THRESHOLDS, phaseForTime } from './constants';

export interface CreatureCounts {
  jellyfish: number;
  fish: number;
  deepSeaFish: number;
}

export interface SaveData {
  version: number;
  totalPlayTime: number; // 累計プレイ時間(秒)
  lastSavedAt: number; // UNIXタイムスタンプ(ms)
  phase: number; // 現在フェーズ(1〜5)
  coralGrowth: number; // 珊瑚の成長度(0〜1)
  creatureCounts: CreatureCounts;
}

const STORAGE_KEY = 'deep-see-tank/save';
const SAVE_VERSION = 1;

function defaultSave(): SaveData {
  return {
    version: SAVE_VERSION,
    totalPlayTime: 0,
    lastSavedAt: Date.now(),
    phase: 1,
    coralGrowth: 0,
    creatureCounts: { jellyfish: 0, fish: 0, deepSeaFish: 0 },
  };
}

/**
 * ゲーム全体の永続状態。localStorage への保存・読み込みを担う。
 * フォールバックで握りつぶさず、復元に失敗したら理由を明示してから初期化する。
 */
export class GameState {
  data: SaveData;

  /** フェーズが上がった瞬間に発火するコールバック群。 */
  private phaseListeners: Array<(phase: number, prev: number) => void> = [];

  constructor() {
    this.data = GameState.load();
  }

  static load(): SaveData {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaultSave();

    let parsed: unknown;
    try {
      parsed = JSON.parse(raw);
    } catch (err) {
      // 壊れたセーブを黙って無視すると原因不明の初期化になるため、必ず記録する
      console.error('[GameState] セーブデータのJSON解析に失敗しました。初期化します。', err);
      return defaultSave();
    }

    if (!GameState.isValidSave(parsed)) {
      console.error('[GameState] セーブデータの形式が不正です。初期化します。', parsed);
      return defaultSave();
    }

    return parsed;
  }

  private static isValidSave(value: unknown): value is SaveData {
    if (typeof value !== 'object' || value === null) return false;
    const v = value as Record<string, unknown>;
    const counts = v.creatureCounts as Record<string, unknown> | undefined;
    return (
      typeof v.totalPlayTime === 'number' &&
      typeof v.lastSavedAt === 'number' &&
      typeof v.phase === 'number' &&
      typeof v.coralGrowth === 'number' &&
      typeof counts === 'object' &&
      counts !== null &&
      typeof counts.jellyfish === 'number' &&
      typeof counts.fish === 'number' &&
      typeof counts.deepSeaFish === 'number'
    );
  }

  save(): void {
    this.data.lastSavedAt = Date.now();
    this.data.version = SAVE_VERSION;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(this.data));
  }

  reset(): void {
    this.data = defaultSave();
    localStorage.removeItem(STORAGE_KEY);
  }

  /** 累計プレイ時間を進め、フェーズが上がっていればリスナーに通知する。 */
  addPlayTime(seconds: number): void {
    this.data.totalPlayTime += seconds;
    const next = phaseForTime(this.data.totalPlayTime);
    if (next > this.data.phase) {
      const prev = this.data.phase;
      this.data.phase = next;
      for (const fn of this.phaseListeners) fn(next, prev);
    }
  }

  onPhaseChange(fn: (phase: number, prev: number) => void): void {
    this.phaseListeners.push(fn);
  }

  /** 現在フェーズの進捗(0〜1)。最終フェーズなら珊瑚の成長度を進捗とみなす。 */
  get phaseProgress(): number {
    const phase = this.data.phase;
    if (phase >= MAX_PHASE) return this.data.coralGrowth;
    const start = PHASE_THRESHOLDS[phase];
    const end = PHASE_THRESHOLDS[phase + 1];
    return Math.min(1, Math.max(0, (this.data.totalPlayTime - start) / (end - start)));
  }
}

import { MAX_OFFLINE_SECONDS } from './constants';
import type { GameState } from './GameState';

/**
 * 放置(オフライン)時間とフレーム差分を扱う。
 */
export class TimeManager {
  private readonly state: GameState;
  private lastTick = performance.now();

  constructor(state: GameState) {
    this.state = state;
  }

  /**
   * 前回セーブ時刻からの経過秒を返す（最大 MAX_OFFLINE_SECONDS まで）。
   * 復帰時に一度だけ呼び、状態をスキップさせる用途。
   */
  getElapsedSinceLastSession(): number {
    const last = this.state.data.lastSavedAt;
    const now = Date.now();
    const elapsed = Math.max(0, (now - last) / 1000);
    return Math.min(elapsed, MAX_OFFLINE_SECONDS);
  }

  /** 直近フレームからの経過秒（実時間ベース・上限0.1秒でスパイク抑制）。 */
  tick(): number {
    const now = performance.now();
    const delta = Math.min((now - this.lastTick) / 1000, 0.1);
    this.lastTick = now;
    return delta;
  }

  /** タブ復帰時などにフレーム計測の基準をリセットして巨大なdeltaを防ぐ。 */
  resetTick(): void {
    this.lastTick = performance.now();
  }
}

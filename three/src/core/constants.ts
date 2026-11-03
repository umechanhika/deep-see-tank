import { Box3, Vector3 } from 'three';

/**
 * 水槽の内寸（中心が原点）。生き物の遊泳範囲もこれを基準にする。
 */
export const TANK = {
  width: 24,
  height: 16,
  depth: 14,
} as const;

/** 水槽内部の遊泳可能な境界（壁から少し内側に余白を取る）。 */
export function getTankBounds(margin = 1.5): Box3 {
  const hx = TANK.width / 2 - margin;
  const hy = TANK.height / 2 - margin;
  const hz = TANK.depth / 2 - margin;
  return new Box3(new Vector3(-hx, -hy, -hz), new Vector3(hx, hy, hz));
}

/** 各フェーズに到達するまでの累計プレイ時間（秒）。 */
export const PHASE_THRESHOLDS: Record<number, number> = {
  1: 0, // 開始直後: プランクトン
  2: 5 * 60, // 5分後: クラゲ出現
  3: 15 * 60, // 15分後: 魚の群れ
  4: 30 * 60, // 30分後: 深海魚
  5: 60 * 60, // 60分後: 完成形
};

export const MAX_PHASE = 5;

/** 経過時間からフェーズ番号を求める。 */
export function phaseForTime(totalPlayTime: number): number {
  let phase = 1;
  for (let p = 1; p <= MAX_PHASE; p++) {
    if (totalPlayTime >= PHASE_THRESHOLDS[p]) phase = p;
  }
  return phase;
}

/** オフライン放置で反映する最大時間（24時間）。 */
export const MAX_OFFLINE_SECONDS = 24 * 60 * 60;

/** 深海の色定義。 */
export const COLORS = {
  deep: 0x020b18,
  light: 0x0d3b6e,
  fog: 0x03101f,
} as const;

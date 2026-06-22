import { createNoise3D, type NoiseFunction3D } from 'simplex-noise';

/**
 * アプリ全体で共有する3Dシンプレックスノイズ。
 * 生き物の遊泳や海底の凹凸など、自然な揺らぎに使う。
 */
export const noise3D: NoiseFunction3D = createNoise3D();

/** -1〜1 のノイズを 0〜1 に正規化して返す。 */
export function noise01(x: number, y: number, z: number): number {
  return noise3D(x, y, z) * 0.5 + 0.5;
}

import { CanvasTexture, type Texture } from 'three';

let softParticle: Texture | null = null;

/**
 * 中心が明るく外周に向けて減衰する円形スプライト。
 * プランクトンや泡の発光表現に使い回す。
 */
export function getSoftParticleTexture(): Texture {
  if (softParticle) return softParticle;

  const size = 64;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('2D context の取得に失敗しました');

  const g = ctx.createRadialGradient(
    size / 2,
    size / 2,
    0,
    size / 2,
    size / 2,
    size / 2
  );
  g.addColorStop(0, 'rgba(255,255,255,1)');
  g.addColorStop(0.25, 'rgba(255,255,255,0.7)');
  g.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, size, size);

  softParticle = new CanvasTexture(canvas);
  return softParticle;
}

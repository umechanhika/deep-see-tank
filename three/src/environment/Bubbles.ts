import {
  AdditiveBlending,
  BufferAttribute,
  BufferGeometry,
  Points,
  PointsMaterial,
} from 'three';
import { TANK } from '../core/constants';
import { getSoftParticleTexture } from '../core/textures';

/**
 * 海底から立ち上る泡。上端に達したら下へリセットして循環させる。
 */
export class Bubbles {
  readonly points: Points;

  private readonly count: number;
  private readonly positions: Float32Array;
  private readonly speed: Float32Array;
  private readonly geometry: BufferGeometry;

  constructor(count = 200) {
    this.count = count;
    this.positions = new Float32Array(count * 3);
    this.speed = new Float32Array(count);

    for (let i = 0; i < count; i++) {
      this.resetParticle(i, true);
    }

    this.geometry = new BufferGeometry();
    this.geometry.setAttribute('position', new BufferAttribute(this.positions, 3));

    const material = new PointsMaterial({
      color: 0xbfe6ff,
      size: 0.14,
      map: getSoftParticleTexture(),
      transparent: true,
      opacity: 0.35,
      blending: AdditiveBlending,
      depthWrite: false,
    });

    this.points = new Points(this.geometry, material);
    this.points.frustumCulled = false;
  }

  private resetParticle(i: number, randomY: boolean): void {
    const ix = i * 3;
    this.positions[ix] = (Math.random() - 0.5) * (TANK.width - 3);
    this.positions[ix + 1] = randomY
      ? -TANK.height / 2 + Math.random() * TANK.height
      : -TANK.height / 2 + 0.2;
    this.positions[ix + 2] = (Math.random() - 0.5) * (TANK.depth - 3);
    this.speed[i] = 0.5 + Math.random() * 1.0;
  }

  update(delta: number, time: number): void {
    const top = TANK.height / 2;
    for (let i = 0; i < this.count; i++) {
      const ix = i * 3;
      this.positions[ix + 1] += this.speed[i] * delta;
      // 左右にゆらゆら
      this.positions[ix] += Math.sin(time * 2 + i) * delta * 0.2;
      if (this.positions[ix + 1] > top) this.resetParticle(i, false);
    }
    (this.geometry.attributes.position as BufferAttribute).needsUpdate = true;
  }
}

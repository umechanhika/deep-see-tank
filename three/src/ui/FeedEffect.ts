import {
  AdditiveBlending,
  BufferAttribute,
  BufferGeometry,
  Points,
  PointsMaterial,
  Vector3,
} from 'three';
import { TANK } from '../core/constants';
import { getSoftParticleTexture } from '../core/textures';

interface Particle {
  pos: Vector3;
  vel: Vector3;
  life: number;
}

const HIDDEN_Y = -9999;

/**
 * 餌やりで水中に降る餌粒。クリック地点から発生し、ゆっくり沈む。
 */
export class FeedEffect {
  readonly points: Points;

  private readonly pool: Particle[] = [];
  private readonly positions: Float32Array;
  private readonly geometry: BufferGeometry;

  constructor(poolSize = 240) {
    this.positions = new Float32Array(poolSize * 3);
    for (let i = 0; i < poolSize; i++) {
      this.pool.push({ pos: new Vector3(0, HIDDEN_Y, 0), vel: new Vector3(), life: 0 });
      this.positions[i * 3 + 1] = HIDDEN_Y;
    }

    this.geometry = new BufferGeometry();
    this.geometry.setAttribute('position', new BufferAttribute(this.positions, 3));

    const material = new PointsMaterial({
      color: 0xffe6a8,
      size: 0.22,
      map: getSoftParticleTexture(),
      transparent: true,
      opacity: 0.9,
      blending: AdditiveBlending,
      depthWrite: false,
    });

    this.points = new Points(this.geometry, material);
    this.points.frustumCulled = false;
  }

  /** 指定地点から餌をばらまく。 */
  spawn(point: Vector3, amount = 24): void {
    let spawned = 0;
    for (const p of this.pool) {
      if (spawned >= amount) break;
      if (p.life > 0) continue;
      p.pos.set(
        point.x + (Math.random() - 0.5) * 1.5,
        point.y + (Math.random() - 0.5) * 1.0,
        point.z + (Math.random() - 0.5) * 1.5
      );
      p.vel.set((Math.random() - 0.5) * 0.3, -0.4 - Math.random() * 0.4, (Math.random() - 0.5) * 0.3);
      p.life = 6 + Math.random() * 3;
      spawned++;
    }
  }

  update(delta: number): void {
    const floor = -TANK.height / 2 + 0.3;
    for (let i = 0; i < this.pool.length; i++) {
      const p = this.pool[i];
      const ix = i * 3;
      if (p.life <= 0) {
        this.positions[ix + 1] = HIDDEN_Y;
        continue;
      }
      p.life -= delta;
      p.vel.x *= 0.98;
      p.vel.z *= 0.98;
      p.pos.addScaledVector(p.vel, delta);
      if (p.pos.y <= floor) {
        p.pos.y = floor;
        p.life = 0;
      }
      this.positions[ix] = p.pos.x;
      this.positions[ix + 1] = p.pos.y;
      this.positions[ix + 2] = p.pos.z;
    }
    (this.geometry.attributes.position as BufferAttribute).needsUpdate = true;
  }
}

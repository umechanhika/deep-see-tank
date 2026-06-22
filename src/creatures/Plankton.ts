import {
  AdditiveBlending,
  BufferAttribute,
  BufferGeometry,
  Color,
  Points,
  PointsMaterial,
  Vector3,
} from 'three';
import { getTankBounds } from '../core/constants';
import { noise3D } from '../core/noise';
import { getSoftParticleTexture } from '../core/textures';

/**
 * 微弱に発光しながら漂うプランクトン。
 * THREE.Points + Additive で群れの光を表現し、シンプレックスノイズで
 * ゆっくりランダムウォークさせる。ゲーム開始直後から常時表示。
 */
export class Plankton {
  readonly points: Points;

  private readonly count: number;
  private readonly positions: Float32Array;
  private readonly phase: Float32Array; // 個体ごとの明滅位相
  private readonly geometry: BufferGeometry;
  private readonly material: PointsMaterial;

  constructor(count = 4000) {
    this.count = count;
    this.positions = new Float32Array(count * 3);
    this.phase = new Float32Array(count);

    const bounds = getTankBounds(0.5);
    const size = bounds.getSize(new Vector3());
    const min = bounds.min;

    for (let i = 0; i < count; i++) {
      this.positions[i * 3] = min.x + Math.random() * size.x;
      this.positions[i * 3 + 1] = min.y + Math.random() * size.y;
      this.positions[i * 3 + 2] = min.z + Math.random() * size.z;
      this.phase[i] = Math.random() * Math.PI * 2;
    }

    this.geometry = new BufferGeometry();
    this.geometry.setAttribute(
      'position',
      new BufferAttribute(this.positions, 3)
    );

    this.material = new PointsMaterial({
      color: new Color(0x9fd4ff),
      size: 0.12,
      map: getSoftParticleTexture(),
      transparent: true,
      opacity: 0.7,
      blending: AdditiveBlending,
      depthWrite: false,
      sizeAttenuation: true,
    });

    this.points = new Points(this.geometry, this.material);
    this.points.frustumCulled = false;
  }

  update(delta: number, time: number): void {
    const pos = this.positions;
    const bounds = getTankBounds(0.5);
    const { min, max } = bounds;

    for (let i = 0; i < this.count; i++) {
      const ix = i * 3;
      const x = pos[ix];
      const y = pos[ix + 1];
      const z = pos[ix + 2];

      // 3軸それぞれ別のノイズ場でゆったり漂わせる
      const nx = noise3D(x * 0.08, y * 0.08, time * 0.05);
      const ny = noise3D(y * 0.08, z * 0.08, time * 0.05 + 100);
      const nz = noise3D(z * 0.08, x * 0.08, time * 0.05 + 200);

      pos[ix] += nx * delta * 0.5;
      pos[ix + 1] += (ny * 0.4 + 0.05) * delta * 0.5; // 僅かに上昇
      pos[ix + 2] += nz * delta * 0.5;

      // 範囲外に出たら反対側へ回り込ませて密度を保つ
      if (pos[ix] < min.x) pos[ix] = max.x;
      else if (pos[ix] > max.x) pos[ix] = min.x;
      if (pos[ix + 1] < min.y) pos[ix + 1] = max.y;
      else if (pos[ix + 1] > max.y) pos[ix + 1] = min.y;
      if (pos[ix + 2] < min.z) pos[ix + 2] = max.z;
      else if (pos[ix + 2] > max.z) pos[ix + 2] = min.z;
    }

    (this.geometry.attributes.position as BufferAttribute).needsUpdate = true;

    // 全体をゆっくり明滅
    this.material.opacity = 0.55 + Math.sin(time * 0.5) * 0.12;
  }
}

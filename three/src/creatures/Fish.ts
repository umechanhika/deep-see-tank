import {
  Box3,
  ConeGeometry,
  Color,
  InstancedMesh,
  MeshStandardMaterial,
  Object3D,
  Vector3,
} from 'three';
import { getTankBounds } from '../core/constants';

const MAX_SPEED = 3.2;
const MAX_FORCE = 0.08;
const PERCEPTION = 3.0;
const SEPARATION_DIST = 1.4;

/**
 * 1匹の魚の運動状態。古典的なBoidの3ルールで群れを作る。
 */
class Boid {
  position = new Vector3();
  velocity = new Vector3();
  private acceleration = new Vector3();

  constructor(bounds: Box3) {
    const size = bounds.getSize(new Vector3());
    this.position.set(
      bounds.min.x + Math.random() * size.x,
      bounds.min.y + Math.random() * size.y,
      bounds.min.z + Math.random() * size.z
    );
    this.velocity
      .set(Math.random() - 0.5, (Math.random() - 0.5) * 0.4, Math.random() - 0.5)
      .normalize()
      .multiplyScalar(MAX_SPEED * 0.6);
  }

  flock(boids: Boid[]): void {
    const sep = new Vector3();
    const ali = new Vector3();
    const coh = new Vector3();
    let sepCount = 0;
    let count = 0;

    for (const other of boids) {
      if (other === this) continue;
      const d = this.position.distanceTo(other.position);
      if (d > PERCEPTION) continue;

      ali.add(other.velocity);
      coh.add(other.position);
      count++;

      if (d < SEPARATION_DIST && d > 0) {
        const away = this.position
          .clone()
          .sub(other.position)
          .divideScalar(d * d);
        sep.add(away);
        sepCount++;
      }
    }

    if (count > 0) {
      ali.divideScalar(count);
      this.steerTo(ali, this.acceleration, 1.0);

      coh.divideScalar(count).sub(this.position);
      this.steerTo(coh, this.acceleration, 0.9);
    }
    if (sepCount > 0) {
      sep.divideScalar(sepCount);
      this.steerTo(sep, this.acceleration, 1.6);
    }
  }

  /** desired方向へ向かう操舵力を accumulator に足し込む。 */
  private steerTo(desired: Vector3, accumulator: Vector3, weight: number): void {
    if (desired.lengthSq() === 0) return;
    desired.normalize().multiplyScalar(MAX_SPEED);
    const steer = desired.sub(this.velocity);
    if (steer.length() > MAX_FORCE) steer.setLength(MAX_FORCE);
    accumulator.add(steer.multiplyScalar(weight));
  }

  /** 壁に近づいたら中心方向へ緩やかに押し戻す。 */
  private avoidWalls(bounds: Box3): void {
    const margin = 2.0;
    const push = 0.05;
    if (this.position.x < bounds.min.x + margin) this.acceleration.x += push;
    else if (this.position.x > bounds.max.x - margin) this.acceleration.x -= push;
    if (this.position.y < bounds.min.y + margin) this.acceleration.y += push;
    else if (this.position.y > bounds.max.y - margin) this.acceleration.y -= push;
    if (this.position.z < bounds.min.z + margin) this.acceleration.z += push;
    else if (this.position.z > bounds.max.z - margin) this.acceleration.z -= push;
  }

  /** 餌など外的な誘引点へ向かう力を加える。 */
  attractTo(target: Vector3, strength: number): void {
    const dir = target.clone().sub(this.position);
    const d = dir.length();
    if (d > 0.001) {
      dir.divideScalar(d).multiplyScalar(strength);
      this.acceleration.add(dir);
    }
  }

  update(delta: number, bounds: Box3): void {
    this.avoidWalls(bounds);
    this.velocity.add(this.acceleration.clone().multiplyScalar(delta * 60));
    if (this.velocity.length() > MAX_SPEED) this.velocity.setLength(MAX_SPEED);
    // 完全停止しないよう最低速度を保つ
    if (this.velocity.length() < MAX_SPEED * 0.25)
      this.velocity.setLength(MAX_SPEED * 0.25);

    this.position.addScaledVector(this.velocity, delta);

    // 万一はみ出したら境界内へクランプ
    this.position.clamp(bounds.min, bounds.max);
    this.acceleration.set(0, 0, 0);
  }
}

/**
 * 魚の群れ。InstancedMesh で多数を1ドローコール描画する。
 */
export class FishSchool {
  readonly mesh: InstancedMesh;

  private readonly boids: Boid[] = [];
  private readonly bounds: Box3;
  private readonly dummy = new Object3D();
  private readonly maxCount: number;
  private active = 0;

  constructor(maxCount = 30, color = 0xc9d8e0) {
    this.maxCount = maxCount;
    this.bounds = getTankBounds(2.0);

    // 魚ジオメトリ: コーンを-Z前方に向け、薄く成形
    const geo = new ConeGeometry(0.28, 1.1, 6);
    geo.rotateX(-Math.PI / 2);
    geo.scale(0.65, 0.5, 1);

    const mat = new MeshStandardMaterial({
      color: new Color(color),
      roughness: 0.6,
      metalness: 0.2,
      emissive: new Color(0x0a1a24),
    });

    this.mesh = new InstancedMesh(geo, mat, maxCount);
    this.mesh.count = 0;
    this.mesh.frustumCulled = false;
  }

  get count(): number {
    return this.active;
  }

  /** 群れの匹数を設定（増減）。 */
  setCount(n: number): void {
    const target = Math.max(0, Math.min(this.maxCount, Math.floor(n)));
    while (this.boids.length < target) this.boids.push(new Boid(this.bounds));
    if (this.boids.length > target) this.boids.length = target;
    this.active = target;
    this.mesh.count = target;
  }

  /** 餌の位置へ群れを引き寄せる。 */
  attract(target: Vector3, strength: number): void {
    for (const b of this.boids) b.attractTo(target, strength);
  }

  update(delta: number, _time: number): void {
    for (const b of this.boids) b.flock(this.boids);
    for (let i = 0; i < this.boids.length; i++) {
      const b = this.boids[i];
      b.update(delta, this.bounds);
      this.dummy.position.copy(b.position);
      this.dummy.lookAt(b.position.clone().add(b.velocity));
      this.dummy.updateMatrix();
      this.mesh.setMatrixAt(i, this.dummy.matrix);
    }
    if (this.boids.length > 0) this.mesh.instanceMatrix.needsUpdate = true;
  }
}

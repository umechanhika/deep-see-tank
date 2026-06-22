import {
  Color,
  Group,
  IcosahedronGeometry,
  Mesh,
  MeshStandardMaterial,
  PointLight,
  SphereGeometry,
  Vector3,
} from 'three';
import { getTankBounds } from '../core/constants';
import { noise3D } from '../core/noise';

const LURE_COLORS = [0x7affe0, 0x9fb0ff, 0xc9ff8f];

/**
 * 深海魚1体。暗い体に発光する誘導灯(ルアー)を持ち、
 * ノイズ場に沿ってゆっくり徘徊する。提灯アンコウのイメージ。
 */
export class DeepSeaFish {
  readonly group = new Group();
  readonly light: PointLight;

  private readonly bounds = getTankBounds(2.5);
  private readonly seed = Math.random() * 100;
  private readonly speed: number;
  private readonly lure: Mesh;
  private readonly heading = new Vector3(1, 0, 0);

  constructor(position: Vector3) {
    const scale = 1.1 + Math.random() * 0.7;
    const lureColor = new Color(
      LURE_COLORS[Math.floor(Math.random() * LURE_COLORS.length)]
    );

    // 体: 細長く潰したイコサヘドロン
    const bodyGeo = new IcosahedronGeometry(1, 1);
    // 進行方向(-Z)に長い体型にする
    bodyGeo.scale(0.8 * scale, 0.9 * scale, 1.8 * scale);
    const body = new Mesh(
      bodyGeo,
      new MeshStandardMaterial({
        color: 0x0a141c,
        roughness: 0.9,
        metalness: 0.1,
        emissive: new Color(0x05121a),
        flatShading: true,
      })
    );
    this.group.add(body);

    // 誘導灯: 体の前方に発光する小球
    this.lure = new Mesh(
      new SphereGeometry(0.16 * scale, 12, 12),
      new MeshStandardMaterial({
        color: lureColor,
        emissive: lureColor,
        emissiveIntensity: 2.5,
      })
    );
    // 頭部前方(-Z)の上に誘導灯を伸ばす
    this.lure.position.set(0, 0.7 * scale, -1.9 * scale);
    this.group.add(this.lure);

    this.light = new PointLight(lureColor, 1.2, 7 * scale, 2);
    this.lure.add(this.light);

    this.group.position.copy(position);
    this.speed = 0.5 + Math.random() * 0.4;
  }

  update(delta: number, time: number): void {
    const t = time * 0.06 + this.seed;
    const p = this.group.position;

    // ノイズで進行方向をなめらかに変える
    const nx = noise3D(p.x * 0.05, p.y * 0.05, t);
    const ny = noise3D(p.y * 0.05, p.z * 0.05, t + 50) * 0.4;
    const nz = noise3D(p.z * 0.05, p.x * 0.05, t + 100);
    const desired = new Vector3(nx, ny, nz);

    // 壁が近ければ中心へ向ける
    const center = new Vector3();
    this.bounds.getCenter(center);
    if (!this.bounds.containsPoint(p)) {
      desired.add(center.clone().sub(p).normalize());
    }

    if (desired.lengthSq() > 0) {
      desired.normalize();
      this.heading.lerp(desired, 1 - Math.pow(0.001, delta));
      this.heading.normalize();
    }

    p.addScaledVector(this.heading, this.speed * delta);
    p.clamp(this.bounds.min, this.bounds.max);

    // 進行方向を向く
    this.group.lookAt(p.clone().add(this.heading));

    // 誘導灯のゆらめき
    const flicker = 0.8 + Math.sin(time * 2 + this.seed) * 0.3;
    this.light.intensity = 1.0 + flicker;
    (this.lure.material as MeshStandardMaterial).emissiveIntensity =
      2.0 + flicker;
  }
}

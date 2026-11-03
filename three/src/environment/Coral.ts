import {
  Color,
  CylinderGeometry,
  Group,
  Matrix4,
  Mesh,
  MeshStandardMaterial,
  Quaternion,
  Vector3,
} from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';

const CORAL_COLORS = [0xff7fa8, 0xffa24f, 0xf0e6e0]; // ピンク / オレンジ / 白

interface Segment {
  start: Vector3;
  end: Vector3;
  depth: number;
}

/**
 * L-system ベースの珊瑚。成長度(0〜1)に応じて反復回数を変え、
 * 枝分かれするジオメトリを再構築する。
 */
export class Coral {
  readonly group = new Group();

  private growthLevel = 0;
  private readonly material: MeshStandardMaterial;
  private readonly angle = (22 + Math.random() * 10) * (Math.PI / 180);
  private readonly segLength: number;
  private readonly maxIter = 4;
  private mesh?: Mesh;

  constructor(position: Vector3, scale = 1) {
    const color = new Color(
      CORAL_COLORS[Math.floor(Math.random() * CORAL_COLORS.length)]
    );
    this.material = new MeshStandardMaterial({
      color,
      roughness: 0.45,
      metalness: 0.05,
      emissive: color.clone().multiplyScalar(0.12),
    });
    this.segLength = 0.55 * scale;
    this.group.position.copy(position);
    this.group.scale.setScalar(scale);
  }

  /** 成長度を加算して形状を作り直す。 */
  grow(amount: number): void {
    const next = Math.min(1, this.growthLevel + amount);
    if (Math.floor(next * this.maxIter) === Math.floor(this.growthLevel * this.maxIter)) {
      this.growthLevel = next;
      return; // 反復回数が変わらないなら再構築不要
    }
    this.growthLevel = next;
    this.rebuildGeometry();
  }

  /** ロード時などに成長度を直接設定する。 */
  setGrowth(level: number): void {
    this.growthLevel = Math.min(1, Math.max(0, level));
    this.rebuildGeometry();
  }

  /** L-system 文字列を生成する。A=成長点。 */
  private generate(iterations: number): string {
    let s = 'A';
    for (let i = 0; i < iterations; i++) {
      let next = '';
      for (const c of s) {
        next += c === 'A' ? 'F[+A][-A][&A]' : c;
      }
      s = next;
    }
    return s;
  }

  private rebuildGeometry(): void {
    // 既存メッシュを破棄
    if (this.mesh) {
      this.group.remove(this.mesh);
      this.mesh.geometry.dispose();
      this.mesh = undefined;
    }
    const iterations = Math.max(0, Math.floor(this.growthLevel * this.maxIter));
    if (iterations === 0) return;

    const segments = this.interpret(this.generate(iterations));
    if (segments.length === 0) return;

    const geos = segments.map((seg) => this.segmentGeometry(seg));
    const merged = mergeGeometries(geos, false);
    geos.forEach((g) => g.dispose());
    if (!merged) throw new Error('珊瑚ジオメトリのマージに失敗しました');

    this.mesh = new Mesh(merged, this.material);
    this.group.add(this.mesh);
  }

  /** タートルグラフィクスでL-system文字列を3Dの枝に変換する。 */
  private interpret(commands: string): Segment[] {
    const segments: Segment[] = [];
    const pos = new Vector3(0, 0, 0);
    const orient = new Quaternion(); // 初期前方は +Y
    const stack: Array<{ pos: Vector3; orient: Quaternion; depth: number }> = [];
    let depth = 0;

    const yaw = new Vector3(0, 0, 1);
    const pitch = new Vector3(1, 0, 0);
    const up = new Vector3(0, 1, 0);

    for (const c of commands) {
      switch (c) {
        case 'F': {
          const dir = up.clone().applyQuaternion(orient).multiplyScalar(this.segLength);
          const start = pos.clone();
          pos.add(dir);
          segments.push({ start, end: pos.clone(), depth });
          break;
        }
        case '+':
          orient.multiply(new Quaternion().setFromAxisAngle(yaw, this.angle));
          break;
        case '-':
          orient.multiply(new Quaternion().setFromAxisAngle(yaw, -this.angle));
          break;
        case '&':
          orient.multiply(new Quaternion().setFromAxisAngle(pitch, this.angle));
          break;
        case '[':
          stack.push({ pos: pos.clone(), orient: orient.clone(), depth });
          // 枝ごとにランダムなロールを加えて立体的に広げる
          orient.multiply(
            new Quaternion().setFromAxisAngle(up, Math.random() * Math.PI * 2)
          );
          depth++;
          break;
        case ']': {
          const s = stack.pop();
          if (s) {
            pos.copy(s.pos);
            orient.copy(s.orient);
            depth = s.depth;
          }
          break;
        }
      }
    }
    return segments;
  }

  /** 1本の枝を、太さが先細りする円柱ジオメトリにする。 */
  private segmentGeometry(seg: Segment): CylinderGeometry {
    const len = seg.start.distanceTo(seg.end);
    const baseR = 0.12 / (seg.depth + 1) + 0.02;
    const topR = baseR * 0.7;
    const geo = new CylinderGeometry(topR, baseR, len, 5, 1);
    // 円柱(初期+Y)を枝の向きに合わせて配置
    geo.translate(0, len / 2, 0);
    const dir = seg.end.clone().sub(seg.start).normalize();
    const quat = new Quaternion().setFromUnitVectors(new Vector3(0, 1, 0), dir);
    const m = new Matrix4().makeRotationFromQuaternion(quat);
    m.setPosition(seg.start);
    geo.applyMatrix4(m);
    return geo;
  }
}

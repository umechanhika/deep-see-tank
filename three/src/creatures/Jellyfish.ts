import {
  AdditiveBlending,
  BufferAttribute,
  Color,
  CylinderGeometry,
  DoubleSide,
  Group,
  Mesh,
  PointLight,
  ShaderMaterial,
  SphereGeometry,
  Vector3,
} from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import bellVert from '../shaders/jellyfish.vert.glsl';
import bellFrag from '../shaders/jellyfish.frag.glsl';

// 個体ごとの基調色候補（淡い発光色）
const PALETTE = [0x6ad1ff, 0xb58bff, 0xff8fcf, 0x7affd1, 0xffd07a];

const TENTACLE_VERT = /* glsl */ `
  attribute float aT;
  attribute float aPhase;
  uniform float uTime;
  varying float vT;
  void main() {
    vT = aT;
    vec3 p = position;
    float amp = aT * 0.4;
    p.x += sin(uTime * 1.4 + aPhase + aT * 3.0) * amp;
    p.z += cos(uTime * 1.05 + aPhase * 1.3 + aT * 4.0) * amp;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(p, 1.0);
  }
`;

const TENTACLE_FRAG = /* glsl */ `
  uniform vec3 uColor;
  varying float vT;
  void main() {
    float a = (1.0 - vT) * 0.45 + 0.05;
    gl_FragColor = vec4(uColor * (0.6 + (1.0 - vT) * 0.5), a);
  }
`;

/**
 * 発光クラゲ1体。半透明の傘＋揺れる触手＋追従ポイントライト。
 * ふわふわ上下しながらゆっくり漂う。
 */
export class Jellyfish {
  readonly group = new Group();
  readonly light: PointLight;

  private readonly bellMaterial: ShaderMaterial;
  private readonly tentacleMaterial: ShaderMaterial;

  private readonly baseY: number;
  private readonly bobSpeed: number;
  private readonly bobAmp: number;
  private readonly pulseSpeed: number;
  private readonly drift = new Vector3();
  private readonly seed = Math.random() * 100;

  constructor(position: Vector3) {
    const colorHex = PALETTE[Math.floor(Math.random() * PALETTE.length)];
    const color = new Color(colorHex);
    const scale = 0.7 + Math.random() * 0.6;

    // --- 傘 ---
    const bellRadius = 1.4 * scale;
    const bellGeo = new SphereGeometry(
      bellRadius,
      24,
      18,
      0,
      Math.PI * 2,
      0,
      Math.PI * 0.55
    );
    this.bellMaterial = new ShaderMaterial({
      vertexShader: bellVert,
      fragmentShader: bellFrag,
      transparent: true,
      depthWrite: false,
      side: DoubleSide,
      blending: AdditiveBlending,
      uniforms: {
        uPulse: { value: 0 },
        uColor: { value: color.clone() },
        uRimColor: { value: color.clone().lerp(new Color(0xffffff), 0.5) },
        uOpacity: { value: 0.85 },
      },
    });
    const bell = new Mesh(bellGeo, this.bellMaterial);
    this.group.add(bell);

    // --- 触手 (8本をマージして1ドローコール) ---
    this.tentacleMaterial = new ShaderMaterial({
      vertexShader: TENTACLE_VERT,
      fragmentShader: TENTACLE_FRAG,
      transparent: true,
      depthWrite: false,
      side: DoubleSide,
      blending: AdditiveBlending,
      uniforms: {
        uTime: { value: 0 },
        uColor: { value: color.clone() },
      },
    });
    const tentacles = new Mesh(
      this.buildTentacles(bellRadius, scale),
      this.tentacleMaterial
    );
    this.group.add(tentacles);

    // --- 追従ライト ---
    this.light = new PointLight(color, 1.4, 9 * scale, 1.8);
    this.group.add(this.light);

    // --- 動きパラメータ ---
    this.group.position.copy(position);
    this.baseY = position.y;
    this.bobSpeed = 0.3 + Math.random() * 0.3;
    this.bobAmp = 0.6 + Math.random() * 0.8;
    this.pulseSpeed = 0.8 + Math.random() * 0.5;
    this.drift.set(
      (Math.random() - 0.5) * 0.15,
      0,
      (Math.random() - 0.5) * 0.15
    );
  }

  private buildTentacles(bellRadius: number, scale: number) {
    const num = 8;
    const length = 3.5 * scale;
    const rim = bellRadius * 0.7;
    const geos = [];

    for (let i = 0; i < num; i++) {
      const geo = new CylinderGeometry(0.05 * scale, 0.015 * scale, length, 5, 10);
      geo.translate(0, -length / 2, 0); // 上端を原点に、下へ垂らす

      const posAttr = geo.attributes.position as BufferAttribute;
      const n = posAttr.count;
      const aT = new Float32Array(n);
      const aPhase = new Float32Array(n);
      const phase = (i / num) * Math.PI * 2 + Math.random();
      for (let v = 0; v < n; v++) {
        aT[v] = -posAttr.getY(v) / length; // 0:上端 → 1:先端
        aPhase[v] = phase;
      }
      geo.setAttribute('aT', new BufferAttribute(aT, 1));
      geo.setAttribute('aPhase', new BufferAttribute(aPhase, 1));

      const angle = (i / num) * Math.PI * 2;
      geo.translate(
        Math.cos(angle) * rim,
        -bellRadius * 0.15,
        Math.sin(angle) * rim
      );
      geos.push(geo);
    }

    const merged = mergeGeometries(geos, false);
    if (!merged) throw new Error('触手ジオメトリのマージに失敗しました');
    return merged;
  }

  update(_delta: number, time: number): void {
    const t = time + this.seed;

    // 脈動 0〜1
    const pulse = Math.pow(Math.sin(t * this.pulseSpeed) * 0.5 + 0.5, 1.5);
    this.bellMaterial.uniforms.uPulse.value = pulse;
    this.tentacleMaterial.uniforms.uTime.value = t;

    // 脈動と連動した推進＋ふわふわ上下
    this.group.position.y =
      this.baseY + Math.sin(t * this.bobSpeed) * this.bobAmp;
    this.group.position.x += this.drift.x * _delta;
    this.group.position.z += this.drift.z * _delta;

    // ライトの明滅
    this.light.intensity = 1.0 + pulse * 1.2;
  }
}

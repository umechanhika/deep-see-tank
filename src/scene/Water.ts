import {
  BackSide,
  BoxGeometry,
  Color,
  Mesh,
  ShaderMaterial,
} from 'three';
import { COLORS, TANK } from '../core/constants';
import vertexShader from '../shaders/water.vert.glsl';
import fragmentShader from '../shaders/water.frag.glsl';

/**
 * 水槽内部を満たす水のボリューム。
 * 箱の内側(BackSide)にグラデーション＋ゴッドレイのシェーダーを貼り、
 * 水中にいる雰囲気を作る。
 */
export class Water {
  readonly mesh: Mesh;
  private readonly material: ShaderMaterial;

  constructor() {
    const geometry = new BoxGeometry(TANK.width, TANK.height, TANK.depth);

    this.material = new ShaderMaterial({
      vertexShader,
      fragmentShader,
      transparent: true,
      depthWrite: false,
      side: BackSide,
      uniforms: {
        uTime: { value: 0 },
        uDeepColor: { value: new Color(COLORS.deep) },
        uLightColor: { value: new Color(COLORS.light) },
        uHeight: { value: TANK.height },
      },
    });

    this.mesh = new Mesh(geometry, this.material);
    this.mesh.renderOrder = -10; // 背景として最初に描く
  }

  update(time: number): void {
    this.material.uniforms.uTime.value = time;
  }
}

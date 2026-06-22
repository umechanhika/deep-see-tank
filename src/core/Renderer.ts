import {
  Color,
  FogExp2,
  PerspectiveCamera,
  Scene,
  Vector2,
  WebGLRenderer,
} from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { COLORS } from './constants';

/**
 * Three.js の WebGLRenderer / Scene / Camera / OrbitControls をまとめて管理する。
 */
export class Renderer {
  readonly renderer: WebGLRenderer;
  readonly scene: Scene;
  readonly camera: PerspectiveCamera;
  readonly controls: OrbitControls;
  readonly pointer = new Vector2();

  private readonly container: HTMLElement;
  private readonly resizeHandler = () => this.onResize();

  constructor(container: HTMLElement) {
    this.container = container;

    this.renderer = new WebGLRenderer({
      antialias: true,
      alpha: false,
      powerPreference: 'high-performance',
    });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.setClearColor(COLORS.fog, 1);
    container.appendChild(this.renderer.domElement);

    this.scene = new Scene();
    this.scene.background = new Color(COLORS.fog);
    // 深海の濁りを指数フォグで表現
    this.scene.fog = new FogExp2(COLORS.fog, 0.022);

    this.camera = new PerspectiveCamera(50, 1, 0.1, 200);
    this.camera.position.set(0, 1, 26);

    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;
    this.controls.rotateSpeed = 0.4;
    this.controls.minDistance = 12;
    this.controls.maxDistance = 40;
    this.controls.target.set(0, 0, 0);
    // 真上・真下からの回り込みを制限して水槽らしい視点を保つ
    this.controls.minPolarAngle = Math.PI * 0.25;
    this.controls.maxPolarAngle = Math.PI * 0.72;
    this.controls.autoRotate = true;
    this.controls.autoRotateSpeed = 0.25;

    this.onResize();
    window.addEventListener('resize', this.resizeHandler);

    // ユーザー操作中はオートローテーションを止める
    this.controls.addEventListener('start', () => {
      this.controls.autoRotate = false;
    });
  }

  /** ポインタ座標を正規化デバイス座標(-1〜1)に更新する。 */
  updatePointer(clientX: number, clientY: number): void {
    const rect = this.renderer.domElement.getBoundingClientRect();
    this.pointer.x = ((clientX - rect.left) / rect.width) * 2 - 1;
    this.pointer.y = -((clientY - rect.top) / rect.height) * 2 + 1;
  }

  update(): void {
    this.controls.update();
  }

  render(): void {
    this.renderer.render(this.scene, this.camera);
  }

  private onResize(): void {
    const w = this.container.clientWidth || window.innerWidth;
    const h = this.container.clientHeight || window.innerHeight;
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(w, h, false);
  }

  dispose(): void {
    window.removeEventListener('resize', this.resizeHandler);
    this.controls.dispose();
    this.renderer.dispose();
  }
}

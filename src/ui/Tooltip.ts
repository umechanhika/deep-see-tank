import { Camera, Object3D, Vector3 } from 'three';

export interface CreatureInfo {
  name: string;
  kind: string;
}

/**
 * 生き物ホバー時に名前とレベルを表示するHTMLツールチップ。
 * 対象の3Dワールド座標をスクリーン座標へ投影して追従させる。
 */
export class Tooltip {
  private readonly el: HTMLDivElement;
  private target: Object3D | null = null;
  private readonly worldPos = new Vector3();

  constructor() {
    this.el = document.createElement('div');
    this.el.className = 'creature-tooltip';
    this.el.style.cssText = `
      position: fixed; z-index: 30; pointer-events: none;
      padding: 6px 10px; border-radius: 6px;
      background: rgba(6,18,30,0.78); border: 1px solid rgba(127,212,255,0.35);
      color: #dff0ff; font-family: 'JetBrains Mono','Space Mono',monospace;
      font-size: 12px; letter-spacing: 0.06em; white-space: nowrap;
      transform: translate(-50%, -130%); opacity: 0;
      transition: opacity 0.18s ease; text-shadow: 0 0 6px rgba(0,0,0,0.7);
    `;
    document.body.appendChild(this.el);
  }

  /** 対象オブジェクトを設定（nullで非表示）。levelは任意の表示値。 */
  show(target: Object3D, info: CreatureInfo, level: number): void {
    this.target = target;
    this.el.innerHTML = `✦ ${info.name}<br><span style="color:#7fb6dd">レベル ${level}</span>`;
    this.el.style.opacity = '1';
  }

  hide(): void {
    this.target = null;
    this.el.style.opacity = '0';
  }

  /** 毎フレーム、対象のスクリーン位置にツールチップを追従させる。 */
  update(camera: Camera, width: number, height: number): void {
    if (!this.target) return;
    this.target.getWorldPosition(this.worldPos);
    const projected = this.worldPos.clone().project(camera);
    // カメラ背面に回ったら隠す
    if (projected.z > 1) {
      this.el.style.opacity = '0';
      return;
    }
    const x = (projected.x * 0.5 + 0.5) * width;
    const y = (-projected.y * 0.5 + 0.5) * height;
    this.el.style.left = `${x}px`;
    this.el.style.top = `${y}px`;
  }
}

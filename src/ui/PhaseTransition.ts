const PHASE_MESSAGES: Record<number, string> = {
  2: '新しい生き物が現れた… 発光クラゲ',
  3: '新しい生き物が現れた… 魚の群れ',
  4: '新しい生き物が現れた… 深海の住人',
  5: '水槽が豊かさに満ちた…',
};

/**
 * フェーズ移行時の暗転→光が差し込む演出とメッセージ表示。
 */
export class PhaseTransition {
  private readonly flash: HTMLDivElement;
  private readonly message: HTMLDivElement;

  constructor() {
    this.flash = document.createElement('div');
    this.flash.style.cssText = `
      position: fixed; inset: 0; z-index: 40; pointer-events: none;
      background: radial-gradient(circle at 50% 0%, rgba(90,160,220,0.45), rgba(1,6,15,0.0) 60%);
      opacity: 0; transition: opacity 1.2s ease;
    `;
    this.message = document.createElement('div');
    this.message.style.cssText = `
      position: fixed; top: 42%; left: 0; right: 0; z-index: 41;
      text-align: center; pointer-events: none;
      color: #e6f4ff; font-family: 'Space Mono','JetBrains Mono',monospace;
      font-size: clamp(16px, 3vw, 26px); letter-spacing: 0.18em;
      text-shadow: 0 0 18px rgba(127,200,255,0.7);
      opacity: 0; transition: opacity 1.0s ease; transform: translateY(0);
    `;
    document.body.appendChild(this.flash);
    document.body.appendChild(this.message);
  }

  play(phase: number): void {
    const text = PHASE_MESSAGES[phase];
    if (!text) return;

    this.flash.style.opacity = '1';
    this.message.textContent = text;
    this.message.style.opacity = '1';

    window.setTimeout(() => {
      this.flash.style.opacity = '0';
    }, 1600);
    window.setTimeout(() => {
      this.message.style.opacity = '0';
    }, 3600);
  }
}

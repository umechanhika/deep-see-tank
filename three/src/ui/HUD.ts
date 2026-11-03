import type { GameState } from '../core/GameState';
import { MAX_PHASE } from '../core/constants';

const PHASE_NAMES: Record<number, string> = {
  1: 'プランクトンの海',
  2: '発光クラゲの目覚め',
  3: '魚群の到来',
  4: '深海の住人',
  5: '豊穣の水槽',
};

function formatDuration(totalSeconds: number): string {
  const s = Math.floor(totalSeconds);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m ${sec}s`;
  return `${sec}s`;
}

/**
 * 画面オーバーレイのHUD。フェーズ名・豊かさゲージ・総経過時間を表示。
 */
export class HUD {
  private readonly root: HTMLDivElement;
  private readonly phaseLabel: HTMLDivElement;
  private readonly gaugeFill: HTMLDivElement;
  private readonly timeLabel: HTMLDivElement;

  constructor(private readonly state: GameState) {
    this.root = document.createElement('div');
    this.root.innerHTML = `
      <div class="hud-panel hud-topleft">
        <div class="hud-phase" data-phase></div>
        <div class="hud-gauge"><div class="hud-gauge-fill" data-gauge></div></div>
        <div class="hud-sub" data-richness></div>
      </div>
      <div class="hud-panel hud-bottomright">
        <div class="hud-time-label">total time</div>
        <div class="hud-time" data-time></div>
      </div>
    `;
    this.injectStyles();
    document.body.appendChild(this.root);

    this.phaseLabel = this.root.querySelector('[data-phase]')!;
    this.gaugeFill = this.root.querySelector('[data-gauge]')!;
    this.timeLabel = this.root.querySelector('[data-time]')!;
  }

  update(): void {
    const phase = this.state.data.phase;
    this.phaseLabel.textContent = `PHASE ${phase} / ${MAX_PHASE} — ${PHASE_NAMES[phase] ?? ''}`;
    this.gaugeFill.style.width = `${(this.state.phaseProgress * 100).toFixed(1)}%`;
    this.timeLabel.textContent = formatDuration(this.state.data.totalPlayTime);

    const richness = this.root.querySelector('[data-richness]');
    if (richness) {
      richness.textContent = `豊かさ ${(this.state.data.coralGrowth * 100).toFixed(0)}%`;
    }
  }

  private injectStyles(): void {
    const style = document.createElement('style');
    style.textContent = `
      .hud-panel {
        position: fixed;
        color: #aacbe6;
        font-family: 'JetBrains Mono','Space Mono',monospace;
        font-size: 12px;
        letter-spacing: 0.08em;
        text-shadow: 0 0 8px rgba(0,0,0,0.8);
        user-select: none;
        pointer-events: none;
        z-index: 20;
      }
      .hud-topleft { top: 20px; left: 22px; }
      .hud-bottomright { right: 22px; bottom: 20px; text-align: right; }
      .hud-phase { font-size: 13px; color: #cfe6ff; margin-bottom: 8px; }
      .hud-gauge {
        width: 200px; height: 4px; border-radius: 2px;
        background: rgba(120,170,210,0.18); overflow: hidden;
      }
      .hud-gauge-fill {
        height: 100%; width: 0%;
        background: linear-gradient(90deg,#2a6ea5,#7fd4ff);
        box-shadow: 0 0 10px rgba(127,212,255,0.6);
        transition: width 0.6s ease;
      }
      .hud-sub { margin-top: 6px; font-size: 11px; color: #6f9ec2; }
      .hud-time-label { font-size: 10px; color: #5f86a8; text-transform: uppercase; }
      .hud-time { font-size: 18px; color: #cfe6ff; }
    `;
    document.head.appendChild(style);
  }
}

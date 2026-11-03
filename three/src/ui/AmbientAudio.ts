/**
 * 深海の環境音。低い持続音 + ゆっくりした揺らぎでアンビエントを作る。
 * ブラウザの自動再生制限に従い、最初のユーザー操作で開始する。
 */
export class AmbientAudio {
  private ctx?: AudioContext;
  private started = false;
  private master?: GainNode;
  private muted = false;

  /** 最初のユーザー操作時に呼ぶ。多重起動はしない。 */
  start(): void {
    if (this.started) {
      // 一度サスペンドされていれば再開
      void this.ctx?.resume();
      return;
    }
    this.started = true;

    const Ctx = window.AudioContext;
    if (!Ctx) {
      // Web Audio 非対応環境では無音のまま続行する旨を明示
      console.warn('[AmbientAudio] AudioContext 非対応のため環境音を無効化します。');
      return;
    }
    this.ctx = new Ctx();
    const ctx = this.ctx;

    this.master = ctx.createGain();
    this.master.gain.value = 0.0;
    this.master.connect(ctx.destination);

    const filter = ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.value = 420;
    filter.Q.value = 0.7;
    filter.connect(this.master);

    // 低い持続音を2つ重ねてうねりを作る
    [55, 82.4].forEach((freq, i) => {
      const osc = ctx.createOscillator();
      osc.type = 'sine';
      osc.frequency.value = freq;
      const g = ctx.createGain();
      g.gain.value = i === 0 ? 0.5 : 0.3;
      osc.connect(g).connect(filter);
      osc.start();

      // ゆっくりした音量のうねり
      const lfo = ctx.createOscillator();
      lfo.frequency.value = 0.05 + i * 0.03;
      const lfoGain = ctx.createGain();
      lfoGain.gain.value = 0.15;
      lfo.connect(lfoGain).connect(g.gain);
      lfo.start();
    });

    // ふわっとフェードイン
    this.master.gain.linearRampToValueAtTime(0.18, ctx.currentTime + 3);
  }

  toggleMute(): boolean {
    if (!this.master || !this.ctx) return this.muted;
    this.muted = !this.muted;
    this.master.gain.linearRampToValueAtTime(
      this.muted ? 0 : 0.18,
      this.ctx.currentTime + 0.4
    );
    return this.muted;
  }
}

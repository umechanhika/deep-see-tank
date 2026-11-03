import { Clock, Plane, Raycaster, Vector3 } from 'three';
import { Renderer } from './core/Renderer';
import { GameState } from './core/GameState';
import { TimeManager } from './core/TimeManager';
import { getTankBounds } from './core/constants';
import { Tank } from './scene/Tank';
import { Water } from './scene/Water';
import { Lighting } from './scene/Lighting';
import { SeaFloor } from './environment/SeaFloor';
import { Bubbles } from './environment/Bubbles';
import { CoralGarden } from './environment/CoralGarden';
import { CreatureManager } from './creatures/CreatureManager';
import { HUD } from './ui/HUD';
import { Tooltip, type CreatureInfo } from './ui/Tooltip';
import { FeedEffect } from './ui/FeedEffect';
import { PhaseTransition } from './ui/PhaseTransition';
import { AmbientAudio } from './ui/AmbientAudio';

const AUTOSAVE_INTERVAL = 30; // 秒
const HUD_INTERVAL = 0.25; // 秒
const CLICK_MAX_MOVE = 6; // px: これ以下なら「クリック」とみなす

/**
 * ゲーム全体のオーケストレーター。
 * シーン構築・状態管理・更新ループ・入力・UI・セーブをまとめる。
 */
export class Game {
  private readonly renderer: Renderer;
  private readonly state: GameState;
  private readonly time: TimeManager;
  private readonly clock = new Clock();

  private readonly water: Water;
  private readonly bubbles: Bubbles;
  private readonly corals: CoralGarden;
  private readonly creatures: CreatureManager;

  private readonly hud: HUD;
  private readonly tooltip = new Tooltip();
  private readonly feed: FeedEffect;
  private readonly phaseFx = new PhaseTransition();
  private readonly audio = new AmbientAudio();

  private readonly raycaster = new Raycaster();
  private readonly feedPlane = new Plane(new Vector3(0, 0, 1), 0);
  private pointerActive = false;
  private downX = 0;
  private downY = 0;

  private rafId = 0;
  private running = false;
  private saveTimer = 0;
  private hudTimer = 0;

  private readonly onBeforeUnload = () => this.state.save();
  private readonly onVisibility = () => {
    if (document.visibilityState === 'visible') this.time.resetTick();
    else this.state.save();
  };

  constructor(container: HTMLElement) {
    this.renderer = new Renderer(container);
    this.state = new GameState();
    this.time = new TimeManager(this.state);

    // --- シーン構築 ---
    const tank = new Tank();
    this.water = new Water();
    const lighting = new Lighting();
    const seaFloor = new SeaFloor();
    this.bubbles = new Bubbles();
    this.corals = new CoralGarden(this.state);

    this.renderer.scene.add(
      tank.group,
      this.water.mesh,
      lighting.group,
      seaFloor.group,
      this.bubbles.points,
      this.corals.group
    );

    this.creatures = new CreatureManager(this.renderer.scene, this.state);
    this.feed = new FeedEffect();
    this.renderer.scene.add(this.feed.points);

    this.hud = new HUD(this.state);

    // フェーズ移行演出
    this.state.onPhaseChange((phase) => this.phaseFx.play(phase));

    // 放置時間を累計に反映してから生態系を現在へ追いつかせる
    const offline = this.time.getElapsedSinceLastSession();
    this.state.addPlayTime(offline);
    this.creatures.syncToTime(this.state.data.totalPlayTime);

    this.bindInput();
    window.addEventListener('beforeunload', this.onBeforeUnload);
    document.addEventListener('visibilitychange', this.onVisibility);

    this.hideLoading();
  }

  start(): void {
    if (this.running) return;
    this.running = true;
    this.time.resetTick();
    this.loop();
  }

  // --- 入力 ---
  private bindInput(): void {
    const dom = this.renderer.renderer.domElement;

    dom.addEventListener('pointerdown', (e) => {
      this.audio.start(); // 自動再生制限の解除を兼ねる
      this.pointerActive = true;
      this.downX = e.clientX;
      this.downY = e.clientY;
    });

    dom.addEventListener('pointermove', (e) => {
      this.renderer.updatePointer(e.clientX, e.clientY);
    });

    dom.addEventListener('pointerup', (e) => {
      if (!this.pointerActive) return;
      this.pointerActive = false;
      const moved = Math.hypot(e.clientX - this.downX, e.clientY - this.downY);
      if (moved <= CLICK_MAX_MOVE) {
        this.renderer.updatePointer(e.clientX, e.clientY);
        this.handleFeed();
      }
    });
  }

  /** クリック地点を水中の点へ変換し、餌をまく。 */
  private handleFeed(): void {
    this.raycaster.setFromCamera(this.renderer.pointer, this.renderer.camera);
    const hit = new Vector3();
    if (!this.raycaster.ray.intersectPlane(this.feedPlane, hit)) return;

    const b = getTankBounds(1.5);
    hit.clamp(b.min, b.max);

    this.feed.spawn(hit);
    this.creatures.feed(hit);
    this.corals.grow(0.01); // 餌やりで少し成長
    this.hud.update();
  }

  /** ホバー中の生き物を判定してツールチップを出す。 */
  private updateHover(): void {
    this.raycaster.setFromCamera(this.renderer.pointer, this.renderer.camera);
    const hits = this.raycaster.intersectObjects(this.creatures.interactables, true);
    if (hits.length === 0) {
      this.tooltip.hide();
      return;
    }
    // ヒットしたメッシュから creature 情報を持つ親を辿る
    let obj = hits[0].object;
    while (obj.parent && !obj.userData.creature) obj = obj.parent;
    const info = obj.userData.creature as CreatureInfo | undefined;
    if (!info) {
      this.tooltip.hide();
      return;
    }
    const level = 1 + Math.floor(this.state.data.coralGrowth * 4);
    this.tooltip.show(obj, info, level);
  }

  private loop = (): void => {
    if (!this.running) return;
    this.rafId = requestAnimationFrame(this.loop);

    const delta = this.time.tick();
    const elapsed = this.clock.getElapsedTime();

    this.state.addPlayTime(delta);
    this.update(delta, elapsed);

    this.renderer.update();
    this.renderer.render();

    // オートセーブ
    this.saveTimer += delta;
    if (this.saveTimer >= AUTOSAVE_INTERVAL) {
      this.saveTimer = 0;
      this.state.save();
    }
  };

  private update(delta: number, elapsed: number): void {
    this.water.update(elapsed);
    this.bubbles.update(delta, elapsed);
    this.corals.update(delta);
    this.creatures.update(delta, elapsed, this.state.data.totalPlayTime);
    this.feed.update(delta);

    this.updateHover();
    const dom = this.renderer.renderer.domElement;
    this.tooltip.update(this.renderer.camera, dom.clientWidth, dom.clientHeight);

    this.hudTimer += delta;
    if (this.hudTimer >= HUD_INTERVAL) {
      this.hudTimer = 0;
      this.hud.update();
    }
  }

  private hideLoading(): void {
    const el = document.getElementById('loading');
    if (el) {
      el.classList.add('hidden');
      window.setTimeout(() => el.remove(), 900);
    }
  }

  dispose(): void {
    this.running = false;
    cancelAnimationFrame(this.rafId);
    window.removeEventListener('beforeunload', this.onBeforeUnload);
    document.removeEventListener('visibilitychange', this.onVisibility);
    this.state.save();
    this.renderer.dispose();
  }
}

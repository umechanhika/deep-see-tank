import { Object3D, Scene, Vector3 } from 'three';
import { getTankBounds } from '../core/constants';
import type { GameState } from '../core/GameState';
import { Plankton } from './Plankton';
import { Jellyfish } from './Jellyfish';
import { FishSchool } from './Fish';
import { DeepSeaFish } from './DeepSeaFish';

const MAX_JELLYFISH = 5;
const MAX_FISH = 30;
const MAX_DEEPSEA = 4;

/** ランダムな遊泳開始位置を返す。 */
function randomSpawn(): Vector3 {
  const b = getTankBounds(2.5);
  const s = b.getSize(new Vector3());
  return new Vector3(
    b.min.x + Math.random() * s.x,
    b.min.y + Math.random() * s.y,
    b.min.z + Math.random() * s.z
  );
}

/**
 * 生き物の出現・更新を統括する。
 * 累計プレイ時間から各種の目標数を算出し、増減を反映する。
 */
export class CreatureManager {
  readonly plankton = new Plankton();
  readonly fishSchool = new FishSchool(MAX_FISH);

  private readonly jellyfish: Jellyfish[] = [];
  private readonly deepSeaFish: DeepSeaFish[] = [];
  private readonly scene: Scene;
  private readonly state: GameState;

  constructor(scene: Scene, state: GameState) {
    this.scene = scene;
    this.state = state;

    this.scene.add(this.plankton.points);
    this.scene.add(this.fishSchool.mesh);
  }

  /** 累計プレイ時間に応じて各生き物の目標数を返す。 */
  private targets(t: number): { jelly: number; fish: number; deep: number } {
    const jelly = t >= 300 ? Math.min(MAX_JELLYFISH, 1 + Math.floor((t - 300) / 300)) : 0;
    const fish = t >= 900 ? Math.min(MAX_FISH, 10 + Math.floor((t - 900) / 60)) : 0;
    const deep = t >= 1800 ? Math.min(MAX_DEEPSEA, 1 + Math.floor((t - 1800) / 300)) : 0;
    return { jelly, fish, deep };
  }

  /** 放置復帰時などに、現在の経過時間へ即座に個体数を合わせる。 */
  syncToTime(totalPlayTime: number): void {
    const { jelly, fish, deep } = this.targets(totalPlayTime);
    while (this.jellyfish.length < jelly) this.spawnJellyfish();
    while (this.deepSeaFish.length < deep) this.spawnDeepSeaFish();
    this.fishSchool.setCount(fish);
    this.writeCounts();
  }

  private spawnJellyfish(): void {
    const j = new Jellyfish(randomSpawn());
    j.group.userData.creature = { name: 'ミズクラゲ', kind: 'jellyfish' };
    this.jellyfish.push(j);
    this.scene.add(j.group);
  }

  private spawnDeepSeaFish(): void {
    const d = new DeepSeaFish(randomSpawn());
    d.group.userData.creature = { name: 'チョウチンアンコウ', kind: 'deepSeaFish' };
    this.deepSeaFish.push(d);
    this.scene.add(d.group);
  }

  private writeCounts(): void {
    this.state.data.creatureCounts = {
      jellyfish: this.jellyfish.length,
      fish: this.fishSchool.count,
      deepSeaFish: this.deepSeaFish.length,
    };
  }

  /** 餌やり: 指定座標へ生き物を引き寄せる。 */
  feed(point: Vector3): void {
    this.fishSchool.attract(point, 0.12);
  }

  update(delta: number, time: number, totalPlayTime: number): void {
    // 数分おきに目標数へ寄せる（毎フレームの新規生成チェックは軽いので常時実施）
    const { jelly, fish, deep } = this.targets(totalPlayTime);
    if (this.jellyfish.length < jelly) this.spawnJellyfish();
    if (this.deepSeaFish.length < deep) this.spawnDeepSeaFish();
    if (this.fishSchool.count !== fish) {
      this.fishSchool.setCount(fish);
      this.writeCounts();
    }

    this.plankton.update(delta, time);
    this.fishSchool.update(delta, time);
    for (const j of this.jellyfish) j.update(delta, time);
    for (const d of this.deepSeaFish) d.update(delta, time);
  }

  /** ホバー判定対象となるルートオブジェクト一覧。 */
  get interactables(): Object3D[] {
    return [
      ...this.jellyfish.map((j) => j.group),
      ...this.deepSeaFish.map((d) => d.group),
    ];
  }
}

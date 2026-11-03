import { Group, Vector3 } from 'three';
import { TANK } from '../core/constants';
import type { GameState } from '../core/GameState';
import { Coral } from './Coral';

/**
 * 海底に配置した複数の珊瑚をまとめて成長させる。
 * 成長度は GameState.coralGrowth に同期し、時間と餌やりで進む。
 */
export class CoralGarden {
  readonly group = new Group();

  private readonly corals: Coral[] = [];
  private readonly state: GameState;
  private appliedGrowth = -1;

  constructor(state: GameState) {
    this.state = state;

    const floor = -TANK.height / 2;
    const spots = 5;
    for (let i = 0; i < spots; i++) {
      const x = (Math.random() - 0.5) * (TANK.width - 6);
      const z = (Math.random() - 0.5) * (TANK.depth - 6);
      const scale = 1.4 + Math.random() * 1.0;
      const coral = new Coral(new Vector3(x, floor, z), scale);
      this.corals.push(coral);
      this.group.add(coral.group);
    }

    this.syncGrowth();
  }

  /** 餌やりなどで成長を進める。 */
  grow(amount: number): void {
    this.state.data.coralGrowth = Math.min(1, this.state.data.coralGrowth + amount);
    this.syncGrowth();
  }

  /** プレイ時間に応じた緩やかな自然成長（1時間でほぼ満開）。 */
  update(delta: number): void {
    if (this.state.data.coralGrowth < 1) {
      this.state.data.coralGrowth = Math.min(
        1,
        this.state.data.coralGrowth + delta / 3600
      );
      this.syncGrowth();
    }
  }

  /** 成長段階が変わったときだけジオメトリを作り直す。 */
  private syncGrowth(): void {
    const g = this.state.data.coralGrowth;
    // 4段階のしきい値をまたいだときのみ再構築（負荷抑制）
    const stage = Math.floor(g * 4);
    if (stage === this.appliedGrowth) return;
    this.appliedGrowth = stage;
    for (const c of this.corals) c.setGrowth(g);
  }
}

import {
  AmbientLight,
  DirectionalLight,
  Group,
  PointLight,
} from 'three';
import { COLORS, TANK } from '../core/constants';

/**
 * 深海の薄明かり。上方から差し込む弱い指向性光と、
 * 全体を持ち上げる僅かな環境光で構成する。
 */
export class Lighting {
  readonly group = new Group();

  constructor() {
    const ambient = new AmbientLight(COLORS.light, 0.35);
    this.group.add(ambient);

    // 水面から差し込む光
    const top = new DirectionalLight(0x3a6ea5, 1.1);
    top.position.set(2, TANK.height, 4);
    this.group.add(top);

    // 手前を僅かに照らす補助光
    const fill = new PointLight(0x1a4a7a, 0.6, TANK.width * 2, 1.5);
    fill.position.set(0, 2, TANK.depth);
    this.group.add(fill);
  }
}

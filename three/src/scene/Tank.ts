import {
  BoxGeometry,
  EdgesGeometry,
  LineBasicMaterial,
  LineSegments,
  Mesh,
  MeshPhysicalMaterial,
  Group,
} from 'three';
import { TANK } from '../core/constants';

/**
 * 水槽のガラス筐体。外側から見ると薄く反射するガラス、
 * 内側は透けて中の生態系が見える。
 */
export class Tank {
  readonly group = new Group();

  constructor() {
    const geometry = new BoxGeometry(TANK.width, TANK.height, TANK.depth);

    const glass = new MeshPhysicalMaterial({
      transmission: 1,
      thickness: 0.5,
      roughness: 0,
      metalness: 0,
      ior: 1.33, // 水のガラス越し
      transparent: true,
      opacity: 0.18,
      reflectivity: 0.2,
      clearcoat: 1,
      clearcoatRoughness: 0,
    });

    const shell = new Mesh(geometry, glass);
    this.group.add(shell);

    // 枠のエッジを淡く光らせて水槽の輪郭を出す
    const edges = new EdgesGeometry(geometry);
    const frame = new LineSegments(
      edges,
      new LineBasicMaterial({
        color: 0x2a4d6e,
        transparent: true,
        opacity: 0.35,
      })
    );
    this.group.add(frame);
  }
}

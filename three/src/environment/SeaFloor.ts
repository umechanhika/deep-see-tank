import {
  BufferAttribute,
  Color,
  Group,
  IcosahedronGeometry,
  Mesh,
  MeshStandardMaterial,
  PlaneGeometry,
} from 'three';
import { TANK } from '../core/constants';
import { noise3D } from '../core/noise';

/**
 * 砂地と岩。PlaneGeometry の頂点をノイズで持ち上げて凹凸を作り、
 * Icosahedron をいくつか散らして岩礁にする。
 */
export class SeaFloor {
  readonly group = new Group();

  constructor() {
    this.group.add(this.buildSand());
    this.buildRocks();
  }

  private buildSand(): Mesh {
    const segs = 64;
    const geometry = new PlaneGeometry(TANK.width, TANK.depth, segs, segs);
    geometry.rotateX(-Math.PI / 2);

    // 頂点を高さ方向にノイズ変位
    const pos = geometry.attributes.position as BufferAttribute;
    for (let i = 0; i < pos.count; i++) {
      const x = pos.getX(i);
      const z = pos.getZ(i);
      const h =
        noise3D(x * 0.12, z * 0.12, 0) * 0.6 +
        noise3D(x * 0.4, z * 0.4, 10) * 0.18;
      pos.setY(i, h);
    }
    pos.needsUpdate = true;
    geometry.computeVertexNormals();

    const material = new MeshStandardMaterial({
      color: new Color(0x14222e),
      roughness: 1,
      metalness: 0,
      flatShading: false,
    });

    const mesh = new Mesh(geometry, material);
    mesh.position.y = -TANK.height / 2 + 0.05;
    mesh.receiveShadow = true;
    return mesh;
  }

  private buildRocks(): void {
    const rockMat = new MeshStandardMaterial({
      color: 0x0d1820,
      roughness: 0.95,
      metalness: 0.05,
      flatShading: true,
    });

    const count = 7;
    for (let i = 0; i < count; i++) {
      const r = 0.7 + Math.random() * 1.8;
      const geo = new IcosahedronGeometry(r, 1);
      // 頂点を歪ませて自然な岩に
      const pos = geo.attributes.position as BufferAttribute;
      for (let j = 0; j < pos.count; j++) {
        const f = 1 + noise3D(pos.getX(j), pos.getY(j), pos.getZ(j)) * 0.35;
        pos.setXYZ(j, pos.getX(j) * f, pos.getY(j) * f, pos.getZ(j) * f);
      }
      pos.needsUpdate = true;
      geo.computeVertexNormals();

      const rock = new Mesh(geo, rockMat);
      const x = (Math.random() - 0.5) * (TANK.width - 4);
      const z = (Math.random() - 0.5) * (TANK.depth - 4);
      rock.position.set(x, -TANK.height / 2 + r * 0.4, z);
      rock.rotation.set(Math.random(), Math.random(), Math.random());
      rock.scale.y *= 0.7;
      this.group.add(rock);
    }
  }
}

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import type { PalSceneRecipe } from './palSceneRecipes';

/** 材質批次合併：物件仍有厚度、遮擋與透視，每個色材只需一次 draw。 */
class Props {
  readonly batches = new Map<string, THREE.BufferGeometry[]>();
  add(color: string, geometry: THREE.BufferGeometry, x: number, y: number, z: number, yaw = 0) {
    geometry.rotateY(yaw).translate(x, y, z);
    const items = this.batches.get(color) ?? [];
    items.push(geometry); this.batches.set(color, items);
  }
  box(c: string, x: number, y: number, z: number, sx: number, sy: number, sz: number, yaw = 0) {
    this.add(c, new THREE.BoxGeometry(sx, sy, sz), x, y, z, yaw);
  }
  rock(c: string, x: number, y: number, z: number, sx: number, sy: number, sz: number, seed: number) {
    const g = new THREE.IcosahedronGeometry(1, sx < .25 ? 0 : 1);
    const p = g.getAttribute('position');
    for (let i = 0; i < p.count; i++) {
      // Identical vertices use identical displacement, avoiding cracks between triangles.
      const dx = p.getX(i), dy = p.getY(i), dz = p.getZ(i);
      const v = 1 + .15 * Math.sin(dx * 19 + dy * 7 + dz * 13 + seed);
      p.setXYZ(i, dx * v, dy * v, dz * v);
    }
    g.computeVertexNormals(); g.scale(sx, sy, sz);
    this.add(c, g, x, y, z, seed);
  }
  beam(c: string, a: [number, number, number], b: [number, number, number], radius: number) {
    const start = new THREE.Vector3(...a), end = new THREE.Vector3(...b);
    const delta = end.clone().sub(start);
    const g = new THREE.CylinderGeometry(radius * .65, radius, delta.length(), 7, 1);
    g.applyQuaternion(new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 1, 0), delta.normalize()));
    const mid = start.add(end).multiplyScalar(.5);
    this.add(c, g, mid.x, mid.y, mid.z);
  }
  flush(group: THREE.Group) {
    for (const [color, geometries] of this.batches) {
      const converted = geometries.map(g => g.index ? g.toNonIndexed() : g);
      const merged = mergeGeometries(converted)!;
      // All temporary buffers, including conversions, are released after merging.
      for (const g of geometries) g.dispose();
      converted.forEach((g, i) => { if (g !== geometries[i]) g.dispose(); });
      const material = new THREE.MeshStandardMaterial({ color, roughness: 1, flatShading: false });
      material.onBeforeCompile = shader => {
        shader.vertexShader = shader.vertexShader.replace('#include <common>', '#include <common>\nvarying vec3 palPosition;');
        shader.vertexShader = shader.vertexShader.replace('#include <begin_vertex>', '#include <begin_vertex>\npalPosition = position;');
        shader.fragmentShader = shader.fragmentShader.replace('#include <common>', '#include <common>\nvarying vec3 palPosition;');
        shader.fragmentShader = shader.fragmentShader.replace('#include <color_fragment>', `#include <color_fragment>
          float palGrain=fract(sin(dot(floor(palPosition*180.),vec3(17.13,29.7,81.31)))*43758.5453);
          float palStain=sin(palPosition.x*22.+palPosition.y*15.+sin(palPosition.z*33.)*2.);
          diffuseColor.rgb*=.88+.13*palGrain+.055*palStain;`);
      };
      material.customProgramCacheKey = () => 'pal-weathered-v1';
      const mesh = new THREE.Mesh(merged, material);
      mesh.name = `pal-props-${color.slice(1)}`; mesh.receiveShadow = true;
      group.add(mesh);
    }
  }
}
const rand = (n: number) => { const v = Math.sin(n * 127.1 + 83.2) * 43758.5453; return v - Math.floor(v); };
const WOOD = '#493329', RED = '#71302a', GOLD = '#ab8e4b', DARK = '#272c26';

function rockRim(p: Props, r: PalSceneRecipe, dense = false) {
  for (let i = 0; i < 48; i++) {
    const left = i < 16, right = i >= 32;
    const x = left ? -5.4 + rand(i) * .7 : right ? 5.1 + rand(i) * .8 : (i - 16) * .72 - 5.8;
    const z = left || right ? (i % 16) * .63 - 5.2 : -3.9 - rand(i + 4) * .6;
    const size = .3 + rand(i + 8) * .5;
    p.rock(r.stone, x, .1, z, size, dense ? .4 + rand(i) * .7 : size * .65, size, i);
  }
}
function plants(p: Props, r: PalSceneRecipe, flowers = false) {
  const green = r.vegetation ?? '#345341';
  for (let i = 0; i < (flowers ? 100 : 35); i++) {
    const x = i % 3 === 0 ? -5 + rand(i) : i % 3 === 1 ? 4.3 + rand(i) : -5 + rand(i) * 10;
    const z = i % 3 === 2 ? -3.6 - rand(i + 3) : -3.4 + rand(i + 7) * 7;
    for (let leaf = 0; leaf < 3; leaf++) {
      p.rock(green, x + (leaf - 1) * .1, .07, z, .15, .12 + rand(i) * .08, .14, i + leaf);
    }
    if (flowers) {
      const c = ['#a45663', '#d2bd83', '#887fac'][i % 3]!;
      for (let petal = 0; petal < 5; petal++) p.rock(c, x + Math.sin(petal * 1.257) * .035, .21, z + Math.cos(petal * 1.257) * .035, .035, .015, .035, i);
      p.rock('#d2bd83', x, .225, z, .02, .018, .02, i);
    }
  }
}
function wall(p: Props, r: PalSceneRecipe, ornament = false) {
  // Rear wall remains behind both formations; no prop occupies a card target.
  p.box(r.stone, 0, .8, -4.3, 12, 1.6, .38);
  p.box(r.detail, 0, .13, -4.05, 12, .25, .28);
  for (let row = 0; row < 4; row++) for (let i = 0; i < 20; i++) {
    p.box(r.detail, -5.8 + i * .6 + (row % 2) * .28, row * .36 + .15, -4.098, .014, .31, .012);
  }
  for (let row = 0; row < 5; row++) p.box(r.detail, 0, row * .36 + .12, -4.09, 12, .014, .014);
  if (ornament) for (let i = 0; i < 9; i++) {
    const x = i * 1.3 - 5.2;
    p.box(r.ground, x, .88, -4.055, 1.1, 1.12, .07);
    p.box(r.stone, x, .88, -4.01, .88, .9, .08);
    for (let s = -1; s <= 1; s += 2) {
      p.box(r.detail, x + s * .34, .88, -3.965, .018, .7, .013);
      p.box(r.detail, x, .88 + s * .35, -3.965, .68, .018, .013);
    }
    for (let k = 0; k < 4; k++) p.box(r.detail, x + Math.sin(k * Math.PI / 2) * .18, .88 + Math.cos(k * Math.PI / 2) * .2, -3.956, .12, .12, .014, .4);
  }
}
function inn(p: Props, r: PalSceneRecipe) {
  p.box(RED, 0, .85, -4.15, 12, 1.7, .18);
  p.box(RED, 5.55, .85, -.4, .18, 1.7, 7.5);
  for (let i = 0; i < 10; i++) {
    const x = i * 1.2 - 5.4;
    p.box(WOOD, x, .84, -3.98, .12, 1.72, .13);
    p.box('#aaa18a', x + .57, 1.12, -4.045, .92, .92, .025);
    for (let k = 0; k < 5; k++) {
      p.box(RED, x + .17 + k * .2, 1.12, -4.015, .024, .92, .03);
      p.box(RED, x + .57, .74 + k * .19, -4.01, .92, .023, .03);
    }
  }
  p.box(WOOD, 0, 1.7, -4, 12, .14, .14);
  for (const x of [-3.6, 3.6]) {
    p.add(RED, new THREE.SphereGeometry(.18, 10, 7).scale(1, 1.45, 1), x, 1.22, -3.67);
    p.beam(GOLD, [x, .82, -3.67], [x, 1.65, -3.67], .018);
  }
  p.add(WOOD, new THREE.CylinderGeometry(.65, .65, .075, 24), -3.8, .56, 2.3);
  for (const x of [-4.15, -3.45]) for (const z of [1.95, 2.65]) p.box(WOOD, x, .26, z, .1, .52, .1);
  p.box(WOOD, 4.6, .35, 1.25, .35, .09, 1.4);
  for (const z of [.75, 1.75]) p.box(WOOD, 4.6, .15, z, .23, .3, .15);
  p.add(WOOD, new THREE.CylinderGeometry(.24, .18, .32, 10), 3.9, .16, -3.1);
  for (let i = 0; i < 5; i++) p.rock(r.vegetation!, 3.9 + Math.sin(i) * .17, .55 + rand(i) * .15, -3.1 + Math.cos(i) * .15, .23, .22, .2, i);
}
function roots(p: Props, r: PalSceneRecipe, giant: boolean) {
  for (let i = 0; i < 26; i++) {
    const x = i % 2 ? -4.6 : 5, z = -3.5 + (i % 13) * .55;
    for (let k = 0; k < 4; k++) {
      const a: [number, number, number] = [x + Math.sin(i + k) * .4, .05 + k * .015, z + k * .18];
      const b: [number, number, number] = [x + Math.sin(i + k + 1) * .4, .05, z + (k + 1) * .18];
      p.beam(r.stone, a, b, .04 + rand(i) * .055);
    }
  }
  const trees = giant ? [[5.4, -2.8, 1.15], [-5, -4, .6]] : [[-5.1, -3.5, .42], [4.9, -3, .5], [5.5, 1, .35], [-5.8, 1, .3]];
  for (const [x, z, radius] of trees) {
    p.beam(r.stone, [x!, 0, z!], [x! + .35, 2.7, z! - .2], radius!);
    for (let i = 0; i < 7; i++) {
      const a = i * .9;
      p.beam(r.stone, [x!, .35, z!], [x! + Math.sin(a) * radius! * 1.7, .04, z! + Math.cos(a) * radius! * 1.7], radius! * .25);
    }
    for (let i = 0; i < 3; i++) p.beam(r.detail, [x! + .15, 1.5, z!], [x! + (i - 1) * .7, 2.9, z! - .45], .055);
  }
  plants(p, r);
}

export function addPalProps(group: THREE.Group, r: PalSceneRecipe) {
  const p = new Props();
  switch (r.architecture) {
    case 'rocks': rockRim(p, r, true); if (r.vegetation) plants(p, r); break;
    case 'inn': inn(p, r); break;
    case 'wall': wall(p, r); break;
    case 'garden': if (r.surface === 'earth') rockRim(p, r); plants(p, r, r.surface === 'tiles'); break;
    case 'forest': case 'roots': roots(p, r, r.architecture === 'roots'); break;
    case 'tower': case 'temple':
      wall(p, r, true);
      for (const x of [-4.8, 4.8]) {
        p.box(r.stone, x, 1.2, -2.9, .7, 2.4, .7);
        p.box(r.detail, x, .14, -2.9, .95, .28, .95);
        p.box(r.ground, x, 2.36, -2.9, .9, .16, .9);
        if (r.architecture === 'tower') {
          p.box('#274c46', x, 1.1, -2.535, .4, 1.24, .025);
          for (let k = 0; k < 4; k++) p.box(GOLD, x - .15 + k * .1, 1.1, -2.515, .016, 1.24, .012);
        }
      } break;
    case 'palace': wall(p, r, true); break;
    case 'red': break; // 明王原作沒有屋頂、神殿或柱子；保留紅紋地面。
    case 'lava': rockRim(p, r); break;
    case 'graves':
      plants(p, r);
      for (let i = 0; i < 8; i++) {
        const x = i < 4 ? -4.9 : 4.9, z = -3.2 + (i % 4) * 1.65;
        p.box(r.stone, x, .28, z, .42, .56, .13, (rand(i) - .5) * .4);
        p.box(DARK, x + .3, -.25, z + .62, .6, .025, .9);
        for (const dz of [.15, 1.09]) p.box(r.detail, x + .3, -.11, z + dz, .7, .28, .08);
        for (const dx of [-.03, .63]) p.box(r.detail, x + dx, -.11, z + .62, .07, .28, .9);
      }
      p.box(WOOD, -4.3, .16, -2.1, .56, .3, 1.1, -.3); break;
    case 'arena':
      for (const x of [-5.3, 5.3]) {
        p.box(WOOD, x, -.02, .2, .2, .16, 8);
        p.box(GOLD, x - Math.sign(x) * .14, .008, .2, .024, .012, 7.8);
        for (const z of [-3.7, 4.1]) {
          p.box(RED, x, .44, z, .12, .9, .12);
          p.rock(RED, x, .7, z, .18, .12, .14, 3);
          p.beam(RED, [x, .7, z], [x + .1, .4, z + .1], .035);
        }
      }
      for (const z of [-3.7, 4.1]) {
        p.box(WOOD, 0, -.02, z, 10.6, .16, .2);
        p.box(GOLD, 0, .008, z - Math.sign(z) * .13, 10.3, .012, .024);
      } break;
    case 'quay':
      p.box('#233c3f', 6.2, .006, 0, 3, .015, 16);
      for (let i = 0; i < 16; i++) p.box(WOOD, 5.5, .05, -.9 + i * .15, 2.2, .08, .135);
      for (const x of [4.5, 6.4]) for (const z of [-1, 1.4]) {
        p.box(WOOD, x, .35, z, .11, .75, .11);
        p.beam(WOOD, [x, .56, -1], [x, .56, 1.4], .035);
      } break;
  }
  p.flush(group);
  if (r.architecture === 'inn') {
    // Move only the rear partitions forward: windows and lanterns must be visible
    // with the fixed PAL camera, while the table remains at the lower-left edge.
    for (const mesh of group.children) {
      if (!(mesh instanceof THREE.Mesh)) continue;
      const positions = mesh.geometry.getAttribute('position');
      for (let i = 0; i < positions.count; i++) if (positions.getZ(i) < -3.4) positions.setZ(i, positions.getZ(i) + 1.1);
      positions.needsUpdate = true; mesh.geometry.computeBoundingSphere();
    }
  }
}

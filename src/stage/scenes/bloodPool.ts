import * as THREE from "three";
import { BLOOD_POOL_SHORE, bloodWaterGeometry, instances, segment, shoreGeometry, skullGeometry, transform } from "./bloodPoolGeometry";
import { bloodBridgeMaterial, bloodRockMaterial, bloodWaterMaterial } from "./bloodPoolMaterials";

const v = (x: number, y: number, z: number) => new THREE.Vector3(x, y, z);

export interface BloodPoolScenery {
  group: THREE.Group;
  update: (elapsed: number, reducedMotion?: boolean) => void;
  dispose: () => void;
}

/**
 * 已確認的 PAL1 DOS 血池：完整 3D 水面、低岩岸、木橋、骨籬。
 * 只提供視覺，不改鏡頭、角色站位、場地 HP 或戰鬥規則。
 */
export function buildBloodPoolScenery(): BloodPoolScenery {
  const group = new THREE.Group();
  group.name = "blood_pool-environment";
  const waterMaterial = bloodWaterMaterial();
  const water = new THREE.Mesh(bloodWaterGeometry(), waterMaterial);
  water.name = "blood-sea-and-golden-vortex";
  water.rotation.x = -Math.PI / 2;
  water.position.y = -.34;
  group.add(water);

  const rockMaterial = bloodRockMaterial();
  const shore = new THREE.Mesh(shoreGeometry(BLOOD_POOL_SHORE), rockMaterial);
  shore.name = "party-rock-shore";
  group.add(shore);
  // 原作地圖的遠方扁岩島，沒有天空、宮殿或高祭壇柱。
  const island = new THREE.Mesh(shoreGeometry([
    [-5, -5.8], [-3.5, -6.6], [-.4, -6.1], [.4, -4.9], [-1, -4.3], [-4, -4.4],
  ], -.09, -.5), rockMaterial);
  island.name = "distant-flat-island";
  group.add(island);

  const rockMatrices = [
    [-4.7, -.24, .2, .4], [-3.8, -.25, 2.4, .28], [-.8, -.24, -3.2, .35],
    [4.75, -.25, -1.45, .48], [3.55, -.25, -4.0, .22], [.1, -.25, 3.6, .2],
  ].map(([x, y, z, size]) => transform(v(x!, y!, z!), v(size!, size! * .75, size!), new THREE.Euler(.2, x!, -.15)));
  group.add(instances("scattered-sharp-rocks", new THREE.DodecahedronGeometry(1, 0),
    new THREE.MeshStandardMaterial({ color: "#342222", roughness: 1, flatShading: true }), rockMatrices));

  const bone = new THREE.MeshStandardMaterial({ color: "#a08f6c", roughness: 1 });
  const dark = new THREE.MeshStandardMaterial({ color: "#221914", roughness: 1 });
  const wood = bloodBridgeMaterial();
  const boneSegments: THREE.Matrix4[] = [];
  const skulls: THREE.Matrix4[] = [];
  const sockets: THREE.Matrix4[] = [];
  // 放在岩岸外緣，最高 0.39m，不擋隊員身體／名字或血條。
  for (let i = 0; i < 8; i++) {
    const x = 1.0 + i * .36;
    const z = 2.46 - ((x - 2.2) / 1.3) ** 2 * .35;
    boneSegments.push(segment(v(x, -.02, z), v(x, .25, z), .028));
    if (i < 7) {
      const nextZ = 2.46 - ((x + .36 - 2.2) / 1.3) ** 2 * .35;
      boneSegments.push(segment(v(x, .11, z), v(x + .36, .14, nextZ), .02));
    }
    if (i % 2 === 0) {
      skulls.push(transform(v(x, .26, z), v(.75, .75, .75)));
      for (const side of [-1, 1]) sockets.push(transform(v(x + side * .035, .279, z + .073), v(.025, .03, .018)));
    }
  }
  // 左下小木橋是探索場景引用，保留主戰鬥中間的大面積血水。
  const bridgeStart = v(-3.9, -.11, 3.35);
  const bridgeEnd = v(.64, -.04, 2.16);
  const bridgeDelta = bridgeEnd.clone().sub(bridgeStart);
  const angle = -Math.atan2(bridgeDelta.z, bridgeDelta.x);
  const planks: THREE.Matrix4[] = [];
  for (let i = 0; i < 20; i++) {
    const p = bridgeStart.clone().lerp(bridgeEnd, i / 19);
    p.y += Math.sin(i * 2.1) * .006;
    planks.push(transform(p, v(.17, .075, .66), new THREE.Euler(0, angle + Math.sin(i) * .025, 0)));
  }
  group.add(instances("weathered-wooden-bridge", new THREE.BoxGeometry(1, 1, 1), wood, planks));
  const rails = [-.28, .28].map((offset) => {
    const perpendicular = v(-bridgeDelta.z, 0, bridgeDelta.x).normalize().multiplyScalar(offset);
    return segment(bridgeStart.clone().add(perpendicular).add(v(0, -.06, 0)), bridgeEnd.clone().add(perpendicular).add(v(0, -.06, 0)), .04);
  });
  group.add(instances("bridge-underbeams", new THREE.CylinderGeometry(1, 1, 1, 6), wood, rails));
  // 原作前景的彎肋骨籬：每節低矮弧形，合併為單一 draw。
  for (let rib = 0; rib < 5; rib++) {
    const center = v(-3.85 + rib * .28, -.02, 2.72 - rib * .076);
    let previous = center.clone().add(v(-.12, 0, 0));
    for (let joint = 1; joint <= 5; joint++) {
      const a = joint / 5 * Math.PI;
      const next = center.clone().add(v(-Math.cos(a) * .12, Math.sin(a) * .3, 0));
      boneSegments.push(segment(previous, next, .024));
      previous = next;
    }
  }
  group.add(instances("bone-fence-and-ribs", new THREE.CylinderGeometry(1, 1, 1, 6), bone, boneSegments));
  group.add(instances("skull-posts", skullGeometry(), bone, skulls));
  group.add(instances("skull-eye-sockets", new THREE.SphereGeometry(1, 6, 4), dark, sockets));

  let disposed = false;
  return {
    group,
    update: (elapsed, reducedMotion = false) => {
      waterMaterial.uniforms.time!.value = reducedMotion ? 0 : elapsed;
    },
    dispose: () => {
      if (disposed) return;
      disposed = true;
      const geometries = new Set<THREE.BufferGeometry>();
      const materials = new Set<THREE.Material>();
      group.traverse((n) => {
        if (!(n instanceof THREE.Mesh)) return;
        geometries.add(n.geometry);
        (Array.isArray(n.material) ? n.material : [n.material]).forEach((m) => materials.add(m));
        if (n instanceof THREE.InstancedMesh) n.dispose();
      });
      geometries.forEach((g) => g.dispose());
      materials.forEach((m) => m.dispose());
    },
  };
}

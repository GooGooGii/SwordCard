import { describe, expect, it, vi } from 'vitest';
import * as THREE from 'three';
import { PAL_SCENE_RECIPES, type PalSceneId } from '../../src/stage/scenes/palSceneRecipes';
import { buildPalScenery } from '../../src/stage/scenes/palScenery';
import { inspectSceneryBudget } from '../../src/stage/scenes/budget';
import { resolveBattleScene, BATTLE_SCENE_IDS } from '../../src/stage/scenes/catalog';
import { slotPosition } from '../../src/stage/formation';

describe('complete PAL1 environments', () => {
  for (const id of Object.keys(PAL_SCENE_RECIPES) as PalSceneId[]) {
    it(`${id}: full ground, clear formations, budget and idempotent resource cleanup`, () => {
      const scenery = buildPalScenery(id);
      expect(resolveBattleScene(id).environment).toBe(id);
      const report = inspectSceneryBudget(scenery.group);
      expect(report.withinBudget, JSON.stringify(report)).toBe(true);
      expect(PAL_SCENE_RECIPES[id].features.length).toBeGreaterThanOrEqual(3);
      scenery.group.updateMatrixWorld(true);
      const ray = new THREE.Raycaster();
      for (const side of ['party', 'enemy'] as const) for (let size = 1; size <= 3; size++) for (let slot = 0; slot < size; slot++) {
        const [x, , z] = slotPosition(side, slot, size);
        ray.set(new THREE.Vector3(x, 2, z), new THREE.Vector3(0, -1, 0));
        const hits = ray.intersectObject(scenery.group);
        expect(hits[0]?.object.name, `${side} ${size}/${slot} blocked by prop`).toBe('pal-ground');
        expect(hits[0]!.point.y).toBeCloseTo(-.012, 5);
      }
      const meshes = scenery.group.children as THREE.Mesh[];
      const spy = meshes.map(mesh => [vi.spyOn(mesh.geometry, 'dispose'), vi.spyOn(mesh.material as THREE.Material, 'dispose')]);
      scenery.dispose(); scenery.dispose();
      for (const pair of spy) for (const fn of pair) expect(fn).toHaveBeenCalledOnce();
    });
  }
  it('registers every scene exactly once and keeps the approved blood pool', () => {
    expect(Object.keys(PAL_SCENE_RECIPES)).toHaveLength(22);
    for (const id of BATTLE_SCENE_IDS) expect(resolveBattleScene(id).environment).toBe(id);
  });
});

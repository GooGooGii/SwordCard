import { describe, expect, it, vi } from "vitest";
import * as THREE from "three";
import { buildBloodPoolScenery } from "../../src/stage/scenes/bloodPool";
import { inspectSceneryBudget } from "../../src/stage/scenes/budget";
import { slotPosition } from "../../src/stage/formation";
import { resolveSceneEnvironment } from "../../src/stage/scenes/presentation";
import { resolveBattleScene } from "../../src/stage/scenes/catalog";
import { presentBossArt } from "../../src/stage/artCandidates";

describe("PAL1 blood pool candidate", () => {
  it("counts all instances within the 20 draw / 30k triangle budget", () => {
    const scenery = buildBloodPoolScenery();
    const report = inspectSceneryBudget(scenery.group);
    expect(report.withinBudget, report.violations.join(", ")).toBe(true);
    expect(report.mainDrawCalls).toBeGreaterThan(5);
    expect(report.triangles).toBeGreaterThan(2_000);
    expect(scenery.group.getObjectByName("blood-sea-and-golden-vortex")).toBeInstanceOf(THREE.Mesh);
    expect(scenery.group.getObjectByName("weathered-wooden-bridge")).toBeInstanceOf(THREE.InstancedMesh);
    scenery.dispose();
  });

  it("keeps every 1–3 member party on the same low rock shore without changing formation", () => {
    const scenery = buildBloodPoolScenery();
    scenery.group.updateMatrixWorld(true);
    const shore = scenery.group.getObjectByName("party-rock-shore")!;
    const ray = new THREE.Raycaster();
    for (let size = 1; size <= 3; size++) for (let slot = 0; slot < size; slot++) {
      const [x, , z] = slotPosition("party", slot, size);
      ray.set(new THREE.Vector3(x, 2, z), new THREE.Vector3(0, -1, 0));
      const hit = ray.intersectObject(shore)[0];
      expect(hit, `party ${size}/${slot} must stand on shore`).toBeDefined();
      expect(hit!.point.y).toBeCloseTo(-.012, 5);
    }
    scenery.dispose();
  });

  it("places the golden vortex under the original enemy formation center", () => {
    const scenery = buildBloodPoolScenery();
    const water = scenery.group.getObjectByName("blood-sea-and-golden-vortex") as THREE.Mesh<THREE.BufferGeometry, THREE.ShaderMaterial>;
    const [x, , z] = slotPosition("enemy", 0, 1);
    expect(water.material.uniforms.vortex!.value.toArray()).toEqual([x, z]);
    scenery.update(12);
    expect(water.material.uniforms.time!.value).toBe(12);
    scenery.update(18, true);
    expect(water.material.uniforms.time!.value).toBe(0);
    scenery.dispose();
  });

  it("anchors skull posts and the bridge landing to the rock, rather than empty water", () => {
    const scenery = buildBloodPoolScenery();
    scenery.group.updateMatrixWorld(true);
    const shore = scenery.group.getObjectByName("party-rock-shore")!;
    const ray = new THREE.Raycaster();
    const matrix = new THREE.Matrix4();
    const point = new THREE.Vector3();
    const skulls = scenery.group.getObjectByName("skull-posts") as THREE.InstancedMesh;
    const bridge = scenery.group.getObjectByName("weathered-wooden-bridge") as THREE.InstancedMesh;
    const anchors: THREE.Vector3[] = [];
    for (let i = 0; i < skulls.count; i++) {
      skulls.getMatrixAt(i, matrix);
      anchors.push(point.setFromMatrixPosition(matrix).clone());
    }
    bridge.getMatrixAt(bridge.count - 1, matrix);
    anchors.push(point.setFromMatrixPosition(matrix).clone());
    for (const anchor of anchors) {
      ray.set(new THREE.Vector3(anchor.x, 2, anchor.z), new THREE.Vector3(0, -1, 0));
      expect(ray.intersectObject(shore).length, `anchor ${anchor.x}/${anchor.z}`).toBeGreaterThan(0);
    }
    scenery.dispose();
  });

  it("disposes shared geometry and material once even after repeated cleanup", () => {
    const scenery = buildBloodPoolScenery();
    const shore = scenery.group.getObjectByName("party-rock-shore") as THREE.Mesh;
    const materialDispose = vi.spyOn(shore.material as THREE.Material, "dispose");
    const geometryDispose = vi.spyOn(shore.geometry, "dispose");
    scenery.dispose();
    scenery.dispose();
    expect(materialDispose).toHaveBeenCalledOnce();
    expect(geometryDispose).toHaveBeenCalledOnce();
  });
});

describe("approved blood pool environment", () => {
  const overrides = { explicitBackdrop: false, explicitScenery: false };
  it("automatically selects the approved scene and preserves other battle backgrounds", () => {
    expect(resolveSceneEnvironment(resolveBattleScene("blood_pool"), overrides)).toBe("blood_pool");
    expect(resolveSceneEnvironment(resolveBattleScene("graveyard"), overrides)).toBe("graveyard");
    expect(resolveSceneEnvironment(resolveBattleScene("unknown"), overrides)).toBe("shilipo");
  });
  it("honors both explicit scenery and painting overrides", () => {
    const bloodPool = resolveBattleScene("blood_pool");
    expect(resolveSceneEnvironment(bloodPool, { ...overrides, explicitBackdrop: true })).toBeNull();
    expect(resolveSceneEnvironment(bloodPool, { ...overrides, explicitScenery: true })).toBeNull();
  });
});

describe("approved DOS Red Ghost King presentation", () => {
  const options = { development: false, search: "?bossArt=red_ghost_king_dos", sceneId: "blood_pool" };
  it("keeps the approved crouched silhouette and readable intent in production", () => {
    const actor = { url: "/assets/enemies/red_ghost_king.webp", height: 2.6 };
    const displayed = presentBossArt(actor, options);
    expect(displayed.url).toBe(actor.url);
    expect(displayed.height).toBeLessThan(actor.height);
    expect(displayed.headOffset![0]).toBeLessThan(0);
  });
  it("preserves custom artwork, other enemies and explicit intent offsets", () => {
    for (const url of ["/custom/boss.webp", "/assets/enemies/leaf_sprite.webp"]) {
      const actor = { url, height: 2.6 };
      expect(presentBossArt(actor, options)).toBe(actor);
    }
    const actor = { url: "/assets/enemies/red_ghost_king.webp", height: 1.5, headOffset: [0, 1, 0] as [number, number, number] };
    const displayed = presentBossArt(actor, options);
    expect(displayed.height).toBe(actor.height);
    expect(displayed.headOffset).toEqual(actor.headOffset);
  });
});

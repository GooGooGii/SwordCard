import * as THREE from "three";
import { describe, expect, it } from "vitest";
import { BATTLE_SCENE_IDS, inspectSceneryBudget, isBattleSceneId, listBattleScenes, resolveBattleScene } from "../../src/stage/scenes";

describe("Codex → Claude 戰場交付介面", () => {
  it("有 23 個固定場景 ID，並區分未交付的素材", () => {
    expect(BATTLE_SCENE_IDS).toHaveLength(23);
    expect(new Set(BATTLE_SCENE_IDS).size).toBe(23);
    expect(listBattleScenes().find((scene) => scene.id === "shilipo")?.ready).toBe(true);
    expect(isBattleSceneId("constructor")).toBe(false);
  });
  it("十里坡沿用既有地面圖與全地面投影", () => {
    const scene = resolveBattleScene("shilipo");
    expect(scene.fallbackReason).toBe("none");
    expect(scene.backdropLayout).toEqual({ wallV: 0 });
    expect(scene.backdropUrl).toBe("/assets/backgrounds/shilipo_ground.jpg");
  });
  it("所有未交付場景保留要求的 ID，但只使用現成背景", () => {
    for (const { id } of listBattleScenes().filter((entry) => !entry.ready)) {
      const scene = resolveBattleScene(id);
      expect(scene.requestedId).toBe(id);
      expect(scene.renderedId).toBe("shilipo");
      expect(scene.fallbackReason).toBe("pending_art");
      expect(scene.backdropUrl).toBe(resolveBattleScene().backdropUrl);
    }
  });
  it("未知場景與空值安全回退，不把輸入當成資產路徑", () => {
    expect(resolveBattleScene("../../missing").fallbackReason).toBe("unknown_scene");
    expect(resolveBattleScene("constructor").renderedId).toBe("shilipo");
    expect(resolveBattleScene(null).fallbackReason).toBe("none");
    expect(resolveBattleScene("").requestedId).toBe("shilipo");
  });
});

describe("場景附加道具預算", () => {
  it("材質分組與一次陰影 pass 都計入繪製呼叫", () => {
    const mesh = new THREE.Mesh(new THREE.BoxGeometry(), Array.from({ length: 6 }, () => new THREE.MeshStandardMaterial()));
    mesh.castShadow = true;
    expect(inspectSceneryBudget(mesh)).toMatchObject({ mainDrawCalls: 6, shadowDrawCalls: 6, drawCalls: 12, triangles: 12, withinBudget: true });
  });
  it("instancing 不增加繪製呼叫，但會增加三角面，零個 instance 不繪製", () => {
    const mesh = new THREE.InstancedMesh(new THREE.BoxGeometry(), new THREE.MeshBasicMaterial(), 3000);
    expect(inspectSceneryBudget(mesh)).toMatchObject({ drawCalls: 1, triangles: 36_000, withinBudget: false });
    mesh.count = 0;
    expect(inspectSceneryBudget(mesh)).toMatchObject({ drawCalls: 0, triangles: 0, withinBudget: true });
  });
  it("雙面透明材質預設繪製兩次，forceSinglePass 才只算一次", () => {
    const material = new THREE.MeshBasicMaterial({ transparent: true, side: THREE.DoubleSide });
    const mesh = new THREE.Mesh(new THREE.PlaneGeometry(), material);
    mesh.castShadow = true;
    expect(inspectSceneryBudget(mesh)).toMatchObject({ mainDrawCalls: 2, shadowDrawCalls: 1, drawCalls: 3, triangles: 4 });
    material.forceSinglePass = true;
    expect(inspectSceneryBudget(mesh)).toMatchObject({ mainDrawCalls: 1, shadowDrawCalls: 1, drawCalls: 2, triangles: 2 });
  });
  it("隱藏父層和不可見材質都不計入預算", () => {
    const root = new THREE.Group();
    const hidden = new THREE.Group();
    hidden.visible = false;
    hidden.add(new THREE.Mesh(new THREE.BoxGeometry(), new THREE.MeshBasicMaterial()));
    const material = new THREE.MeshBasicMaterial();
    material.visible = false;
    root.add(hidden, new THREE.Mesh(new THREE.BoxGeometry(), material));
    expect(inspectSceneryBudget(root)).toMatchObject({ drawCalls: 0, triangles: 0 });
  });
  it("非索引網格的 drawRange 決定真正繪製的三角面", () => {
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute("position", new THREE.Float32BufferAttribute(new Float32Array(18), 3));
    geometry.setDrawRange(3, 3);
    const mesh = new THREE.Mesh(geometry, new THREE.MeshBasicMaterial());
    expect(inspectSceneryBudget(mesh)).toMatchObject({ drawCalls: 1, triangles: 1 });
    geometry.setDrawRange(12, 3);
    expect(inspectSceneryBudget(mesh)).toMatchObject({ drawCalls: 0, triangles: 0 });
  });
  it("粒子不算三角面，但仍佔繪製呼叫，超出 20 次就報告", () => {
    const root = new THREE.Group();
    const geometry = new THREE.BufferGeometry().setAttribute("position", new THREE.Float32BufferAttribute([0, 0, 0], 3));
    for (let i = 0; i < 21; i++) root.add(new THREE.Points(geometry, new THREE.PointsMaterial()));
    expect(inspectSceneryBudget(root)).toMatchObject({ drawCalls: 21, triangles: 0, withinBudget: false });
    expect(inspectSceneryBudget(root).violations).toHaveLength(1);
  });
});

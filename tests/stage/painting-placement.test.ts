import * as THREE from "three";
import { describe, expect, it } from "vitest";
import { paintingPointToGround } from "../../src/stage/scenes/paintingPlacement";

const image = { width: 1600, height: 896 };
function camera(aspect: number) {
  const result = new THREE.PerspectiveCamera(40, aspect, 0.1, 200);
  result.position.set(0, 8, 7);
  result.lookAt(0, 0, 0);
  result.updateMatrixWorld();
  result.updateProjectionMatrix();
  return result;
}

describe("背景畫的道具落腳點對齊", () => {
  it("原圖中心在桌機與手機比例皆投影到鏡頭看向的地面中心", () => {
    for (const aspect of [1280 / 720, 844 / 390]) {
      const anchor = paintingPointToGround(camera(aspect), image, { x: 800, y: 448 })!;
      expect(anchor.visible).toBe(true);
      expect(anchor.position[0]).toBeCloseTo(0);
      expect(anchor.position[1]).toBe(0);
      expect(anchor.position[2]).toBeCloseTo(0);
    }
  });
  it("多個可見錨點回投影後，仍位於各自的 cover 裁切畫面座標", () => {
    for (const aspect of [1280 / 720, 844 / 390, 1]) {
      const projector = camera(aspect);
      for (const point of [{ x: 640, y: 350 }, { x: 1000, y: 600 }]) {
        const anchor = paintingPointToGround(projector, image, point)!;
        const projected = new THREE.Vector3(...anchor.position).project(projector);
        expect(projected.x * 0.5 + 0.5).toBeCloseTo(anchor.screen.x);
        expect(-projected.y * 0.5 + 0.5).toBeCloseTo(anchor.screen.y);
        expect(anchor.position[1]).toBeCloseTo(0);
      }
    }
  });
  it("手機橫向 cover 裁掉原圖上下邊緣時，保留位置但標記不可見", () => {
    const anchor = paintingPointToGround(camera(844 / 390), image, { x: 800, y: 10 })!;
    expect(anchor.visible).toBe(false);
    expect(anchor.screen.y).toBeLessThan(0);
  });
  it("較窄畫面裁掉左右邊緣，不把道具擠回畫面中央", () => {
    const anchor = paintingPointToGround(camera(1), image, { x: 10, y: 448 })!;
    expect(anchor.visible).toBe(false);
    expect(anchor.screen.x).toBeLessThan(0);
  });
  it("無效尺寸、座標與比例不產生 NaN 或無窮座標", () => {
    const projector = camera(16 / 9);
    expect(paintingPointToGround(projector, { width: 0, height: 896 }, { x: 0, y: 0 })).toBeNull();
    expect(paintingPointToGround(projector, image, { x: NaN, y: 20 })).toBeNull();
    expect(paintingPointToGround(projector, image, { x: -1, y: 20 })).toBeNull();
    expect(paintingPointToGround(projector, image, { x: 10, y: 897 })).toBeNull();
    projector.aspect = Infinity;
    expect(paintingPointToGround(projector, image, { x: 10, y: 20 })).toBeNull();
  });
  it("視線朝向天空而打不到前方地面時回傳 null", () => {
    const projector = camera(16 / 9);
    projector.lookAt(0, 12, 0);
    projector.updateMatrixWorld();
    expect(paintingPointToGround(projector, image, { x: 800, y: 448 })).toBeNull();
  });
});

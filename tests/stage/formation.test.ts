import { describe, expect, it } from "vitest";
import { lungePoint, PAL_FORMATION, slotPosition, yawToward } from "../../src/stage/formation";

describe("仙劍一式斜向站位", () => {
  it("我方在右下（x>0、z>0），敵方在左上（x<0、z<0）", () => {
    for (let i = 0; i < 3; i++) {
      const p = slotPosition("party", i, 3);
      const e = slotPosition("enemy", i, 3);
      expect(p[0]).toBeGreaterThan(e[0]);
      expect(p[2]).toBeGreaterThan(e[2]);
    }
  });

  it("同一方排成斜線：右邊的人比較遠（畫面上由左下往右上）", () => {
    const right = slotPosition("party", 1, 3);
    const left = slotPosition("party", 2, 3);
    expect(right[0]).toBeGreaterThan(left[0]);
    expect(right[2]).toBeLessThan(left[2]);
  });

  it("相鄰站位的距離等於 spacing", () => {
    const a = slotPosition("enemy", 0, 3);
    const b = slotPosition("enemy", 1, 3);
    expect(Math.hypot(a[0] - b[0], a[2] - b[2])).toBeCloseTo(PAL_FORMATION.spacing, 5);
  });

  it("單人站在中心", () => {
    expect(slotPosition("party", 0, 1)).toEqual(PAL_FORMATION.partyCenter);
  });

  it("雙方互相面對：我方朝左上、敵方朝右下", () => {
    const p = slotPosition("party", 0, 1);
    const e = slotPosition("enemy", 0, 1);
    const partyYaw = yawToward(p, e);
    const enemyYaw = yawToward(e, p);
    expect(partyYaw).toBeLessThan(-90); // 往 -x、-z
    expect(enemyYaw).toBeGreaterThan(0); // 往 +x、+z
    expect(enemyYaw).toBeLessThan(90);
    expect(Math.abs(Math.abs(partyYaw - enemyYaw) - 180)).toBeLessThan(1e-9);
  });

  it("衝刺停在目標前 gap 公尺", () => {
    const from: [number, number, number] = [2, 0, 2];
    const to: [number, number, number] = [-2, 0, -1];
    const hit = lungePoint(from, to, 1);
    expect(Math.hypot(hit[0] - to[0], hit[2] - to[2])).toBeCloseTo(1, 5);
    expect(lungePoint([0, 0, 0], [0.5, 0, 0], 1)).toEqual([0, 0, 0]);
  });
});

import { describe, expect, it } from "vitest";
import { startBattle } from "../../src/core/battle";
import { soleTarget } from "../../src/ui/battle/targets";
import { db, setup } from "../core/fixtures";

describe("唯一合法目標快出", () => {
  it("只有一隻敵人時回傳它", () => {
    const state = startBattle(db, setup({ enemies: ["biter"], deckIds: Array(10).fill("strike") })).state;
    expect(soleTarget(db, state, state.hand[0]!.uid, "enemy")).toBe(0);
  });

  it("兩隻敵人要自己選；倒下一隻後就只剩另一隻", () => {
    const state = startBattle(db, setup({ enemies: ["biter", "biter"], deckIds: Array(10).fill("strike") })).state;
    const uid = state.hand[0]!.uid;
    expect(soleTarget(db, state, uid, "enemy")).toBeNull();
    state.enemies[0]!.dead = true;
    expect(soleTarget(db, state, uid, "enemy")).toBe(1);
  });

  it("不用選目標的牌回傳 null", () => {
    const state = startBattle(db, setup({ enemies: ["biter"], deckIds: Array(10).fill("strike") })).state;
    expect(soleTarget(db, state, state.hand[0]!.uid, null)).toBeNull();
  });
});

import { describe, expect, it } from "vitest";
import { GAME_DB } from "../../src/content";
import { addCardToRun, buyPotion, member, newRun } from "../../src/core/run";
import { archetypeWeight } from "../../src/core/run/rewards";

describe("流派加權與藥舖", () => {
  it("牌組裡同流派的牌越多，該流派越容易出現（最多三倍）；沒有流派固定 1", () => {
    const run = newRun(GAME_DB, 1, "standard");
    const base = archetypeWeight(GAME_DB, run, "shushan");
    for (let i = 0; i < 3; i++) addCardToRun(GAME_DB, run, "li_chain");
    expect(archetypeWeight(GAME_DB, run, "shushan")).toBeGreaterThan(base);
    for (let i = 0; i < 20; i++) addCardToRun(GAME_DB, run, "li_chain");
    expect(archetypeWeight(GAME_DB, run, "shushan")).toBe(3);
    expect(archetypeWeight(GAME_DB, run, undefined)).toBe(1);
    expect(member(run, "li_xiaoyao").deck.length).toBeGreaterThan(20);
  });

  it("買藥扣錢、放進空格；藥品欄滿了就不能買", () => {
    let run = newRun(GAME_DB, 1, "standard");
    run.coins = 999;
    run.pending = {
      kind: "inn", nodeId: "x", stock: [], rested: false, removed: 0, upgraded: 0,
      potions: [{ potion: "p_herb", price: 35, sold: false }, { potion: "p_rat_fruit", price: 35, sold: false }],
    };
    run.potions = [null, "p_herb", "p_herb"];
    run = buyPotion(GAME_DB, run, 0);
    expect(run.coins).toBe(964);
    expect(run.potions).toEqual(["p_herb", "p_herb", "p_herb"]);
    expect(() => buyPotion(GAME_DB, run, 1)).toThrow(/滿了/);
  });
});

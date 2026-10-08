import { describe, expect, it } from "vitest";
import { endTurn, startBattle } from "../../src/core/battle";
import type { BattleState } from "../../src/core/types";
import { db, setup } from "./fixtures";

const intentOf = (s: BattleState, i = 0) => s.enemies[i]!.intent?.moveId;

describe("敵人 AI", () => {
  it("滿血時不補血；血少時優先補血", () => {
    let s = startBattle(db, setup({ enemies: ["mender"], deckIds: Array(10).fill("guard") })).state;
    expect(intentOf(s)).toBe("bite");
    for (let k = 0; k < 4; k++) {
      s = endTurn(db, s).state;
      expect(intentOf(s)).toBe("bite");
    }
    s.enemies[0]!.hp = 10;
    s.enemies[0]!.intent = null;
    s = endTurn(db, s).state;
    expect(intentOf(s)).toBe("mend");
  });

  it("同一招不會連出三次（三招以上的一般敵人）", () => {
    for (let seed = 1; seed <= 15; seed++) {
      let s = startBattle(db, setup({ seed, enemies: ["trio"], deckIds: Array(10).fill("guard") })).state;
      const seq = [intentOf(s)];
      for (let k = 0; k < 12; k++) {
        s = endTurn(db, s).state;
        seq.push(intentOf(s));
      }
      for (let k = 2; k < seq.length; k++) expect(seq[k] === seq[k - 1] && seq[k] === seq[k - 2]).toBe(false);
    }
  });

  it("場上滿了不召喚", () => {
    const s = startBattle(db, setup({ enemies: ["summoner", "dummy", "dummy"], deckIds: Array(10).fill("guard") })).state;
    // 只有召喚一招、又不能用時退回原招，但召喚本身不會超過上限
    const after = endTurn(db, s).state;
    expect(after.enemies.filter((e) => !e.dead).length).toBeLessThanOrEqual(3);
  });

  it("targeting=weakest 會打血量比例最低的人", () => {
    const s = startBattle(db, setup({
      enemies: ["assassin"],
      party: [{ charId: "li_xiaoyao", hp: 50, maxHp: 50 }, { charId: "zhao_linger", hp: 12, maxHp: 50 }],
      deckIds: Array(10).fill("guard"),
    })).state;
    expect(s.enemies[0]!.intent!.target).toBe(1);
  });
});

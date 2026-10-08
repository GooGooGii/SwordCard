import { describe, expect, it } from "vitest";
import { canPlay, endTurn, playCard, startBattle } from "../../src/core/battle";
import type { BattleState } from "../../src/core/types";
import { db, setup } from "./fixtures";

const uidOf = (s: BattleState, defId: string) => s.hand.find((c) => c.defId === defId)!.uid;

describe("控制狀態：定身、昏睡、封印、混亂", () => {
  it("定身的敵人跳過這次行動，並消耗一層", () => {
    let s = startBattle(db, setup({ enemies: ["biter"], deckIds: ["stun_card", "strike", "strike", "strike", "strike"] })).state;
    s = playCard(db, s, uidOf(s, "stun_card"), 0).state;
    expect(s.enemies[0]!.status.stun).toBe(1);
    const hpBefore = s.party[0]!.hp;
    s = endTurn(db, s).state;
    expect(s.party[0]!.hp).toBe(hpBefore); // 沒被咬
    expect(s.enemies[0]!.status.stun).toBe(0);
  });

  it("昏睡的敵人受到傷害就醒", () => {
    let s = startBattle(db, setup({ enemies: ["biter"], deckIds: ["sleep_card", "strike", "strike", "strike", "strike"] })).state;
    s = playCard(db, s, uidOf(s, "sleep_card"), 0).state;
    expect(s.enemies[0]!.status.sleep).toBe(2);
    s = playCard(db, s, uidOf(s, "strike"), 0).state;
    expect(s.enemies[0]!.status.sleep).toBe(0);
  });

  it("封印的敵人不能用法術類招式（蓄勢），但仍會攻擊", () => {
    let s = startBattle(db, setup({ enemies: ["shaman"], deckIds: ["seal_card", "strike", "strike", "strike", "strike"] })).state;
    s = playCard(db, s, uidOf(s, "seal_card"), 0).state;
    s = endTurn(db, s).state;
    expect(s.enemies[0]!.status.strength).toBe(0);
  });

  it("被封印的隊員不能出仙術牌", () => {
    let s = startBattle(db, setup({ enemies: ["sealer"], deckIds: Array(10).fill("wind_slash") })).state;
    s = endTurn(db, s).state; // 敵人封印逍遙
    expect(s.party[0]!.status.seal).toBe(1);
    expect(canPlay(db, s, s.hand[0]!.uid, 0)).toContain("封印");
    // 自己的回合結束後解除
    s = endTurn(db, s).state;
    expect(s.party[0]!.status.seal).toBe(1); // 又被封了一次（敵人每回合都封）
  });

  it("被定身的隊員這回合不能出他的牌，回合結束後解除；淨化可以解除", () => {
    let s = startBattle(db, setup({
      enemies: ["stunner"],
      party: [{ charId: "li_xiaoyao", hp: 50, maxHp: 50 }, { charId: "zhao_linger", hp: 50, maxHp: 50 }],
      deckIds: ["strike", "strike", "strike", "cleanse", "cleanse", "cleanse", "strike", "strike", "cleanse", "strike"],
    })).state;
    s = endTurn(db, s).state;
    expect(s.party[0]!.status.stun).toBe(1);
    const strike = s.hand.find((c) => c.defId === "strike");
    if (strike) expect(canPlay(db, s, strike.uid, 0)).toContain("定身");
    // 靈兒也被定身，所以淨化也出不了；回合結束時 -1，並得到 1 回合抗性：敵人馬上再定身會無效（防鎖死）
    s = endTurn(db, s).state;
    expect(s.party[0]!.status.stun ?? 0).toBe(0);
    expect(s.party[0]!.status.steady).toBe(1);
    // 抗性過了才能再被定身
    s = endTurn(db, s).state;
    expect(s.party[0]!.status.stun).toBe(1);
  });

  it("淨化解除控制狀態；頭目不會被定身", () => {
    let s = startBattle(db, setup({ enemies: ["thunder_boss"], deckIds: Array(10).fill("stun_card") })).state;
    s = playCard(db, s, s.hand[0]!.uid, 0).state;
    expect(s.enemies[0]!.status.stun ?? 0).toBe(0);
    let t = startBattle(db, setup({
      enemies: ["dummy"],
      party: [{ charId: "li_xiaoyao", hp: 50, maxHp: 50 }, { charId: "zhao_linger", hp: 50, maxHp: 50 }],
      deckIds: Array(10).fill("cleanse"),
    })).state;
    t.party[0]!.status.seal = 2;
    t.party[0]!.status.confuse = 1;
    t = playCard(db, t, t.hand[0]!.uid, null).state;
    expect(t.party[0]!.status.seal ?? 0).toBe(0);
    expect(t.party[0]!.status.confuse ?? 0).toBe(0);
  });

  it("混亂的隊員出單體牌，目標可能變成別的敵人", () => {
    let s = startBattle(db, setup({ enemies: ["dummy", "dummy"], deckIds: Array(10).fill("strike") })).state;
    s.party[0]!.status.confuse = 1;
    const targets = new Set<number>();
    for (let seed = 1; seed <= 20; seed++) {
      const t = structuredClone(s);
      t.rng = seed * 97;
      const after = playCard(db, t, t.hand[0]!.uid, 0).state;
      after.enemies.forEach((e, i) => { if (e.hp < e.maxHp) targets.add(i); });
    }
    expect(targets.size).toBe(2);
  });
});

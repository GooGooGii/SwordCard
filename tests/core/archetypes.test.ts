import { describe, expect, it } from "vitest";
import { canPlay, endTurn, playCard, startBattle } from "../../src/core/battle";
import type { BattleState } from "../../src/core/types";
import { db, setup } from "./fixtures";

const uid = (s: BattleState, defId: string) => s.hand.find((c) => c.defId === defId)!.uid;
const play = (s: BattleState, defId: string, target: number | null = 0) => playCard(db, s, uid(s, defId), target).state;
const yueru = [{ charId: "lin_yueru" as const, hp: 50, maxHp: 50 }];
const anu = [{ charId: "anu" as const, hp: 50, maxHp: 50 }];

describe("流派機制", () => {
  it("指勁：累積層數，斬龍訣依層數加成後清空", () => {
    let s = startBattle(db, setup({ party: yueru, enemies: ["dummy"], deckIds: ["finger", "finger", "dragon_cut", "guard", "guard"] })).state;
    s.qi = 9;
    s = play(s, "finger");
    s = play(s, "finger");
    expect(s.stacks?.zhijin).toBe(2);
    const hp = s.enemies[0]!.hp;
    s = play(s, "dragon_cut", null);
    expect(hp - s.enemies[0]!.hp).toBe(10 + 2 * 3);
    expect(s.stacks?.zhijin).toBe(0);
  });

  it("銅錢鏢：花錢；錢不夠不能打；戰後帶回負的銅錢", () => {
    let s = startBattle(db, setup({ party: yueru, enemies: ["dummy"], deckIds: ["coin_dart", "coin_dart", "guard", "guard", "guard"] })).state;
    s.purse = 60;
    s = play(s, "coin_dart");
    expect(s.purse).toBe(10);
    expect(s.coinsGained).toBe(-50);
    expect(canPlay(db, s, uid(s, "coin_dart"), 0)).toContain("銅錢不足");
  });

  it("爆炸蠱：引爆中毒，造成 層數×倍率 傷害並清空中毒", () => {
    let s = startBattle(db, setup({ party: anu, enemies: ["dummy"], deckIds: ["bomb_gu", "guard", "guard", "guard", "guard"] })).state;
    s.enemies[0]!.status.poison = 6;
    s = play(s, "bomb_gu");
    expect(s.enemies[0]!.hp).toBe(40 - 12);
    expect(s.enemies[0]!.status.poison).toBe(0);
  });

  it("奪魂：殘血的一般敵人直接擊倒；頭目只受 fallback 傷害", () => {
    let s = startBattle(db, setup({ party: anu, enemies: ["dummy", "dummy"], deckIds: ["soul_take", "soul_take", "guard", "guard", "guard"] })).state;
    s.qi = 9;
    s.enemies[0]!.hp = 9; // 22.5%
    s = play(s, "soul_take", 0);
    expect(s.enemies[0]!.dead).toBe(true);
    let b = startBattle(db, setup({ party: anu, enemies: ["thunder_boss"], deckIds: ["soul_take", "guard", "guard", "guard", "guard"] })).state;
    b.enemies[0]!.hp = 10;
    b = play(b, "soul_take", 0);
    expect(b.enemies[0]!.dead).toBe(false);
  });

  it("靈葫咒：殘血的一般敵人收進葫蘆，得到一瓶藥；血太多無效", () => {
    let s = startBattle(db, setup({ enemies: ["dummy", "dummy"], deckIds: ["gourd", "gourd", "guard", "guard", "guard"] })).state;
    s.potions = [null, null, null];
    s.qi = 9;
    s = play(s, "gourd", 1);
    expect(s.enemies[1]!.dead).toBe(false);
    s.enemies[0]!.hp = 5;
    s = play(s, "gourd", 0);
    expect(s.enemies[0]!.dead).toBe(true);
    expect(s.potions!.filter(Boolean)).toHaveLength(1);
  });

  it("狀態牌：敵人塞進棄牌堆；不能打；回合結束還在手上就發作", () => {
    let s = startBattle(db, setup({ enemies: ["spider"], deckIds: ["guard", "guard", "guard", "guard", "guard"] })).state;
    s = endTurn(db, s).state;
    expect([...s.discard, ...s.draw, ...s.hand].filter((c) => c.defId === "silk")).toHaveLength(2);
    // 強制把纏絲放進手牌
    s.hand.push({ uid: 999, defId: "silk", upgraded: false });
    expect(canPlay(db, s, 999)).toBe("這張牌不能打出");
    const hp = s.party[0]!.hp;
    s = endTurn(db, s).state;
    expect(s.party[0]!.hp).toBeLessThanOrEqual(hp - 3);
  });
});

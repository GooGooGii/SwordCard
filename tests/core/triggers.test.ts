import { describe, expect, it } from "vitest";
import { endTurn, playCard, startBattle } from "../../src/core/battle";
import { describeCard } from "../../src/core/describe";
import type { BattleState } from "../../src/core/types";
import { cards, db, setup } from "./fixtures";

const play = (s: BattleState, defId: string, target: number | null = 0) =>
  playCard(db, s, s.hand.find((c) => c.defId === defId)!.uid, target).state;

describe("心法與觸發", () => {
  it("心法打出後常駐並移出牌堆；每打出第 2 張攻擊牌觸發一次", () => {
    let s = startBattle(db, setup({ enemies: ["dummy"], deckIds: ["sword_heart", "strike", "strike", "strike", "guard"] })).state;
    s.qi = 9;
    s = play(s, "sword_heart", null);
    expect(s.powers).toHaveLength(1);
    expect(s.exhaust.some((c) => c.defId === "sword_heart")).toBe(true);
    s = play(s, "strike");
    expect(s.enemies[0]!.hp).toBe(40 - 6);
    s = play(s, "strike");
    expect(s.enemies[0]!.hp).toBe(40 - 12 - 3); // 第 2 張觸發 3 點
    s = play(s, "guard", null); // 技能牌不算
    expect(s.enemies[0]!.hp).toBe(25);
  });

  it("中毒結算時觸發（打觸發來源）", () => {
    let s = startBattle(db, setup({
      enemies: ["dummy"],
      party: [{ charId: "li_xiaoyao", hp: 50, maxHp: 50 }, { charId: "anu", hp: 50, maxHp: 50 }],
      deckIds: ["venom_heart", "poison", "guard", "guard", "guard"],
    })).state;
    s.qi = 9;
    s = play(s, "venom_heart", null);
    s = play(s, "poison");
    s = endTurn(db, s).state; // 敵人回合開始中毒 3 → 再受 2
    expect(s.enemies[0]!.hp).toBe(40 - 3 - 2);
  });

  it("每回合開始時觸發（第一回合打出後，下回合起生效）", () => {
    let s = startBattle(db, setup({ enemies: ["dummy"], deckIds: ["rally_heart", "guard", "guard", "guard", "guard", "guard"] })).state;
    s = play(s, "rally_heart", null);
    s = endTurn(db, s).state;
    expect(s.party[0]!.block).toBe(4);
  });

  it("觸發連鎖有上限，不會無限迴圈", () => {
    let s = startBattle(db, setup({ enemies: ["summoner", "summoner", "summoner"], deckIds: ["loop_heart", "strike", "strike", "strike", "strike"] })).state;
    s.qi = 9;
    s = play(s, "loop_heart", null);
    s.enemies[0]!.hp = 1;
    s = play(s, "strike", 0);
    expect(s.outcome).toBe("won");
  });

  it("主人昏迷時心法不生效", () => {
    let s = startBattle(db, setup({
      enemies: ["dummy"],
      party: [{ charId: "li_xiaoyao", hp: 50, maxHp: 50 }, { charId: "anu", hp: 50, maxHp: 50 }],
      deckIds: ["venom_heart", "poison", "guard", "guard", "guard"],
    })).state;
    s.qi = 9;
    s = play(s, "venom_heart", null);
    s = play(s, "poison");
    s.party[1]!.downed = true;
    s.party[1]!.hp = 0;
    s = endTurn(db, s).state;
    expect(s.enemies[0]!.hp).toBe(40 - 3);
  });

  it("心法的牌面文字由觸發自動產生", () => {
    expect(describeCard(cards["sword_heart"]!, db)).toContain("每打出第 2 張攻擊牌時，對最前面的敵人造成 3 點傷害");
    expect(describeCard(cards["venom_heart"]!, db)).toContain("敵人每次中毒結算時，對那名敵人造成 2 點傷害");
  });
});

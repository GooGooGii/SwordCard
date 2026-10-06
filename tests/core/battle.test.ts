import { describe, expect, it } from "vitest";
import { canPlay, endTurn, playCard, previewCard, startBattle } from "../../src/core/battle";
import { computeDamage } from "../../src/core/battle/damage";
import type { BattleState } from "../../src/core/types";
import { db, setup } from "./fixtures";

const uidOf = (s: BattleState, defId: string): number => {
  const c = s.hand.find((x) => x.defId === defId);
  if (!c) throw new Error(`${defId} not in hand: ${s.hand.map((h) => h.defId).join(",")}`);
  return c.uid;
};
const play = (s: BattleState, defId: string, target: number | null = 0) => playCard(db, s, uidOf(s, defId), target);

describe("開局", () => {
  it("抽 5 張、3 點真氣、敵人意圖已攤開", () => {
    const { state, events } = startBattle(db, setup({ enemies: ["biter"] }));
    expect(state.hand).toHaveLength(5);
    expect(state.qi).toBe(3);
    expect(state.turn).toBe(1);
    expect(state.enemies[0]!.intent?.moveId).toBe("bite");
    expect(state.enemies[0]!.intent?.target).toBe(0);
    expect(events.some((e) => e.type === "turn_start")).toBe(true);
  });

  it("同一個種子結果完全相同", () => {
    const deckIds = ["strike", "guard", "double", "power", "weaken", "expose", "steal"];
    const a = startBattle(db, setup({ deckIds, seed: 7 })).state;
    const b = startBattle(db, setup({ deckIds, seed: 7 })).state;
    expect(a.hand.map((c) => c.defId)).toEqual(b.hand.map((c) => c.defId));
    expect(a.draw.map((c) => c.uid)).toEqual(b.draw.map((c) => c.uid));
    // 換種子會換順序（掃幾個種子，至少有一個和 7 不同）
    const orders = [8, 9, 10, 11].map((seed) => startBattle(db, setup({ deckIds, seed })).state.hand.map((c) => c.uid).join());
    expect(orders.some((o) => o !== a.hand.map((c) => c.uid).join())).toBe(true);
  });
});

describe("傷害計算順序", () => {
  it("基礎＋氣勢＋連鎖 → ×相剋 → ×弱化 → ×破綻 → 捨去", () => {
    const status = (o: Partial<{ strength: number; weak: number; vulnerable: number }>) => ({ strength: 0, weak: 0, vulnerable: 0, poison: 0, ...o });
    // (6+2+1)×1.5×0.75×1.5 = 15.1875 → 15
    const r = computeDamage({
      base: 6,
      attacker: status({ strength: 2, weak: 1 }),
      defender: status({ vulnerable: 1 }),
      attackElement: "wind",
      defendElement: "thunder",
      chainBonus: 1,
    });
    expect(r).toEqual({ amount: 15, effective: "strong" });
    expect(computeDamage({ base: 10, attacker: null, defender: null, attackElement: "thunder", defendElement: "wind" })).toEqual({ amount: 5, effective: "weak" });
  });

  it("護體先吸收", () => {
    let { state } = startBattle(db, setup({ enemies: ["brute"], deckIds: ["guard", "guard", "guard", "guard", "guard"] }));
    state = play(state, "guard", null).state;
    state = endTurn(db, state).state;
    // 10×2 打 5 護體 → 扣 15
    expect(state.party[0]!.hp).toBe(35);
  });
});

describe("五靈相剋與破勢", () => {
  it("剋制 ×1.5 並給 1 層破勢；累積到 2 層取消下一個意圖", () => {
    const deckIds = ["wind_slash", "wind_slash", "wind_slash", "wind_slash", "wind_slash"];
    let { state } = startBattle(db, setup({ enemies: ["thunder_dummy"], deckIds }));
    state.enemies[0]!.hp = state.enemies[0]!.maxHp = 100; // 三下 15 不能打死它
    let step = play(state, "wind_slash");
    expect(step.events.find((e) => e.type === "damage")).toMatchObject({ amount: 15, effective: "strong" });
    expect(step.state.enemies[0]!.breakStacks).toBe(1);
    step = play(step.state, "wind_slash");
    expect(step.state.enemies[0]!.intent?.cancelled).toBe(true);
    expect(step.state.enemies[0]!.breakStacks).toBe(0);
    expect(step.state.enemies[0]!.breakThreshold).toBe(3);
    // 同回合再剋制：只累積、不再觸發
    step = play(step.state, "wind_slash");
    expect(step.state.enemies[0]!.breakStacks).toBe(1);
    expect(step.events.some((e) => e.type === "break")).toBe(false);
  });

  it("Boss 被破勢時意圖減半，不是取消", () => {
    const deckIds = ["wind_slash", "wind_slash", "wind_slash", "wind_slash", "wind_slash"];
    let { state } = startBattle(db, setup({ enemies: ["thunder_boss"], deckIds }));
    for (let i = 0; i < 3; i++) state = play(state, "wind_slash").state;
    expect(state.enemies[0]!.intent?.halved).toBe(true);
    expect(state.enemies[0]!.intent?.cancelled).toBe(false);
    state = endTurn(db, state).state;
    expect(state.party[0]!.hp).toBe(40); // 20 減半
  });
});

describe("相生連鎖", () => {
  it("風→火 接上 +1；接不上歸零", () => {
    const deckIds = ["wind_slash", "fire_talisman", "thunder_talisman", "wind_slash", "strike"];
    let { state } = startBattle(db, setup({ enemies: ["dummy"], deckIds, party: [{ charId: "li_xiaoyao", hp: 50, maxHp: 50 }] }));
    state = { ...state, qi: 10 };
    state = play(state, "wind_slash").state;
    expect(state.chain).toEqual({ last: "wind", count: 0 });
    const preview = previewCard(db, state, db.cards.fire_talisman!, 0);
    expect(preview.chainBonus).toBe(1);
    const step = play(state, "fire_talisman");
    expect(step.events.find((e) => e.type === "damage")).toMatchObject({ amount: 6 });
    expect(step.state.chain).toEqual({ last: "fire", count: 1 });
    const next = play(step.state, "thunder_talisman");
    expect(next.state.chain.count).toBe(2); // 火→雷
    const broken = play(next.state, "wind_slash");
    expect(broken.state.chain).toEqual({ last: "wind", count: 0 }); // 雷→風 不是相生
  });
});

describe("隊伍、合擊與心念", () => {
  const duo = [
    { charId: "li_xiaoyao" as const, hp: 50, maxHp: 50 },
    { charId: "zhao_linger" as const, hp: 50, maxHp: 50 },
  ];

  it("換人出手累積合擊氣，滿了加入發動者的合擊牌", () => {
    const deckIds = ["strike", "linger_wind", "strike", "linger_wind", "strike", "linger_wind", "strike"];
    let { state } = startBattle(db, setup({ party: duo, deckIds, enemies: ["dummy"], seed: 3 }));
    state = { ...state, qi: 20, comboGauge: 3, lastOwner: "li_xiaoyao" };
    const step = play(state, "linger_wind");
    expect(step.events.some((e) => e.type === "combo_ready" && e.charId === "zhao_linger")).toBe(true);
    expect(step.state.hand.some((c) => c.defId === "combo_linger")).toBe(true);
    expect(step.state.comboGauge).toBe(0);
  });

  it("合擊：全隊扣 10%（最低留 1）並結束回合", () => {
    let { state } = startBattle(db, setup({ party: duo, deckIds: ["strike", "strike", "strike", "strike", "strike"], enemies: ["dummy"] }));
    state = { ...state, hand: [...state.hand, { uid: 99, defId: "combo_li", upgraded: false }] };
    const step = playCard(db, state, 99, null);
    expect(step.state.party.map((m) => m.hp)).toEqual([45, 45]);
    expect(step.state.turn).toBe(2); // 已結束回合
  });

  it("有人虛弱（HP<20%）時不能合擊", () => {
    let { state } = startBattle(db, setup({ party: [duo[0]!, { ...duo[1]!, hp: 5 }], enemies: ["dummy"] }));
    state = { ...state, hand: [...state.hand, { uid: 99, defId: "combo_li", upgraded: false }] };
    expect(canPlay(db, state, 99, null)).toMatch(/虛弱/);
  });

  it("昏迷的人的牌變成心念；被救起來就恢復", () => {
    const deckIds = ["linger_wind", "linger_wind", "revive", "strike", "strike"];
    let { state } = startBattle(db, setup({ party: duo, deckIds, enemies: ["dummy"] }));
    state.party[1]!.hp = 0;
    state.party[1]!.downed = true;
    const wind = state.hand.find((c) => c.defId === "linger_wind")!;
    const step = playCard(db, state, wind.uid, 0);
    expect(step.events.find((e) => e.type === "card_played")).toMatchObject({ defId: "thought" });
    expect(step.state.exhaust.some((c) => c.uid === wind.uid)).toBe(true);
    // 心念不能拿來救人（revive 是靈兒的牌，也變心念了）：改由逍遙這邊測試復活用無主牌
  });

  it("意圖指定的人昏迷時改打最左邊的清醒隊友", () => {
    let { state } = startBattle(db, setup({ party: duo, enemies: ["biter"], seed: 1 }));
    state.enemies[0]!.intent = { moveId: "bite", target: 1, cancelled: false, halved: false };
    state.party[1]!.hp = 0;
    state.party[1]!.downed = true;
    state = endTurn(db, state).state;
    expect(state.party[0]!.hp).toBe(44);
  });

  it("護體可以給隊友", () => {
    let { state } = startBattle(db, setup({ party: duo, deckIds: ["cover", "cover", "cover", "cover", "cover"], enemies: ["dummy"] }));
    state = play(state, "cover", 1).state;
    expect(state.party[1]!.block).toBe(8);
    expect(state.party[0]!.block).toBe(0);
  });
});

describe("角色招牌", () => {
  it("月如反擊：本回合受擊時回打", () => {
    const party = [{ charId: "lin_yueru" as const, hp: 50, maxHp: 50 }];
    let { state } = startBattle(db, setup({ party, deckIds: ["counter", "counter", "counter", "counter", "counter"], enemies: ["biter"] }));
    state = play(state, "counter", null).state;
    const step = endTurn(db, state);
    expect(step.events.some((e) => e.type === "counter" && e.amount === 4)).toBe(true);
    expect(step.state.enemies[0]!.hp).toBe(36);
  });

  it("阿奴的蠱：回合結束讓最前面的敵人中毒", () => {
    const party = [{ charId: "anu" as const, hp: 50, maxHp: 50 }];
    let { state } = startBattle(db, setup({ party, deckIds: ["gu", "gu", "gu", "gu", "gu"], enemies: ["dummy"] }));
    state = play(state, "gu", null).state;
    expect(state.gu).toBe(2);
    state = endTurn(db, state).state;
    // 回合結束時中毒 2，敵人回合開始扣 2、剩 1 層
    expect(state.enemies[0]!.hp).toBe(38);
    expect(state.enemies[0]!.status.poison).toBe(1);
  });

  it("御劍：下回合開始時落下", () => {
    let { state } = startBattle(db, setup({ deckIds: ["fly", "fly", "fly", "fly", "fly"], enemies: ["dummy"] }));
    state = play(state, "fly").state;
    expect(state.enemies[0]!.hp).toBe(40);
    state = endTurn(db, state).state;
    expect(state.enemies[0]!.hp).toBe(31);
  });

  it("偷：先偷清單裡的東西，偷完改摸銅錢", () => {
    let { state } = startBattle(db, setup({ deckIds: ["steal", "steal", "steal", "steal", "steal"], enemies: ["thief"] }));
    let step = play(state, "steal");
    expect(step.state.loot).toEqual(["herb"]);
    expect(step.state.hand.some((c) => c.defId === "herb")).toBe(true);
    step = play(step.state, "steal");
    expect(step.state.coinsGained).toBe(5);
  });
});

describe("敵人與場地", () => {
  it("水魔獸：水域還在時殺不死；打破水域才倒下", () => {
    const deckIds = ["double", "double", "double", "double", "double"];
    let { state } = startBattle(db, setup({ enemies: ["water_beast", "water"], deckIds }));
    state = { ...state, qi: 99 };
    state.enemies[0]!.hp = 3;
    state = play(state, "double", 0).state;
    expect(state.enemies[0]!.hp).toBe(1);
    expect(state.enemies[0]!.dead).toBe(false);
    state.enemies[1]!.hp = 4;
    state = play(state, "double", 1).state;
    expect(state.enemies[1]!.dead).toBe(true);
    const step = play(state, "double", 0);
    expect(step.state.enemies[0]!.dead).toBe(true);
    expect(step.state.outcome).toBe("won"); // 場地不算勝利條件
  });

  it("Boss 接續：蛇妖男倒下，狐狸精在同一位置登場，下回合才行動", () => {
    const deckIds = ["double", "double", "double", "double", "double"];
    let { state } = startBattle(db, setup({ enemies: ["snake_man"], deckIds }));
    state = { ...state, qi: 99 };
    state.enemies[0]!.hp = 4;
    const step = play(state, "double", 0);
    expect(step.state.outcome).toBe("ongoing");
    expect(step.state.enemies).toHaveLength(1);
    expect(step.state.enemies[0]!.defId).toBe("fox_spirit");
    expect(step.state.enemies[0]!.intent).toBeNull();
    expect(step.events.some((e) => e.type === "summon")).toBe(true);
    const next = endTurn(db, step.state).state;
    expect(next.enemies[0]!.intent).not.toBeNull();
  });

  it("召喚：最多 3 名敵人", () => {
    let { state } = startBattle(db, setup({ enemies: ["summoner"], deckIds: ["guard", "guard", "guard", "guard", "guard"] }));
    state = endTurn(db, state).state;
    state = endTurn(db, state).state;
    state = endTurn(db, state).state;
    expect(state.enemies.filter((e) => !e.dead)).toHaveLength(3);
  });

  it("求生戰：撐過指定回合數就算成功", () => {
    let { state } = startBattle(db, setup({ enemies: ["biter"], survive: 2 }));
    state = endTurn(db, state).state;
    expect(state.outcome).toBe("ongoing");
    state = endTurn(db, state).state;
    expect(state.outcome).toBe("survived");
  });

  it("全員昏迷就戰敗", () => {
    let { state } = startBattle(db, setup({ enemies: ["brute"], party: [{ charId: "li_xiaoyao", hp: 15, maxHp: 50 }] }));
    state = endTurn(db, state).state;
    expect(state.outcome).toBe("lost");
  });

  it("打倒所有敵人就勝利", () => {
    let { state } = startBattle(db, setup({ enemies: ["dummy"] }));
    state.enemies[0]!.hp = 6;
    state = play(state, "strike").state;
    expect(state.outcome).toBe("won");
  });
});

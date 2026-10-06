import { describe, expect, it } from "vitest";
import { endTurn } from "../../src/core/battle";
import {
  availableNodes,
  battleDeck,
  beginChapter,
  buyCard,
  canRemove,
  completeStory,
  concludeBattle,
  enterNode,
  flattenStory,
  leaveInn,
  newRun,
  removeCard,
  removePrice,
  rest,
  retryBattle,
  takeReward,
  updateBattle,
  upgradeCard,
  type GameDb,
  type RunState,
} from "../../src/core/run";
import { db as battleDb } from "./fixtures";

const rarityCards = Object.fromEntries(
  ["a", "b", "c", "d"].flatMap((x) => [
    [`li_${x}`, { ...battleDb.cards.strike!, id: `li_${x}`, rarity: "common" as const, upgrade: { effects: [{ kind: "damage" as const, amount: 9 }] } }],
    [`ling_${x}`, { ...battleDb.cards.linger_wind!, id: `ling_${x}`, rarity: "common" as const }],
  ]),
);

const db: GameDb = {
  ...battleDb,
  cards: { ...battleDb.cards, ...rarityCards },
  starters: {
    li_xiaoyao: ["li_a", "li_a", "li_a", "li_a", "li_b", "li_b", "li_b", "li_b", "li_c"],
    zhao_linger: ["ling_a", "ling_a", "ling_a", "ling_a", "ling_b", "ling_b", "ling_b", "ling_b"],
    lin_yueru: [],
    anu: [],
    wuhou: [],
  },
  relics: { pouch: { id: "pouch", name: "錦囊", text: "", canon: "", battleStart: [{ kind: "block", amount: 3, to: "party" }], afterBattleHeal: 2 } },
  stories: {
    opening: { id: "opening", bg: "x", steps: [{ narrate: "開場" }, { choice: [{ text: "帶她走", then: [{ join: "zhao_linger" }, { bond: "zhao_linger", amount: 1 }] }, { text: "不管", then: [] }] }] },
    pre: { id: "pre", bg: "x", steps: [{ say: "來了！", who: "li_xiaoyao" }] },
    post: { id: "post", bg: "x", steps: [{ reward: { coins: 7 } }] },
    farewell: { id: "farewell", bg: "x", steps: [{ leave: "zhao_linger", permanent: true }] },
  },
  chapters: [
    {
      id: "c0",
      title: "序",
      subtitle: "",
      map: "x",
      start: "s",
      end: "boss",
      rarity: { common: 1, uncommon: 0, rare: 0 },
      coins: { normal: 10, elite: 20, boss: 30 },
      nodes: [
        { id: "s", kind: "story", label: "開場", pos: [0, 0], next: ["fight"], story: "opening" },
        { id: "fight", kind: "battle", label: "山路", pos: [0, 0], next: ["inn"], battle: { enemies: ["biter"], ground: "g", intro: "pre", outro: "post" } },
        { id: "inn", kind: "inn", label: "客棧", pos: [0, 0], next: ["boss"], inn: { name: "客棧", shopSize: 3 } },
        { id: "boss", kind: "battle", label: "頭目", pos: [0, 0], next: [], battle: { enemies: ["brute"], ground: "g", boss: true, reward: { relic: "pouch" } } },
      ],
    },
    {
      id: "c1",
      title: "一",
      subtitle: "",
      map: "x",
      start: "bye",
      end: "bye",
      rarity: { common: 1, uncommon: 0, rare: 0 },
      coins: { normal: 10, elite: 20, boss: 30 },
      nodes: [{ id: "bye", kind: "story", label: "離別", pos: [0, 0], next: [], story: "farewell" }],
    },
  ],
};

function winBattle(run: RunState): RunState {
  if (run.pending.kind !== "battle") throw new Error("not in battle");
  const battle = structuredClone(run.pending.battle);
  battle.enemies.forEach((e) => {
    e.hp = 0;
    e.dead = true;
  });
  battle.outcome = "won";
  return concludeBattle(db, updateBattle(run, battle));
}

function toInn(): RunState {
  let run = beginChapter(newRun(db, 1, "standard"));
  run = completeStory(db, enterNode(db, run, "s"), [0]);
  run = completeStory(db, enterNode(db, run, "fight"), []);
  run = winBattle(run);
  if (run.pending.kind !== "reward") throw new Error("expected reward");
  run = takeReward(db, run, [run.pending.choices[0]![0]!]);
  run = completeStory(db, run, []);
  return enterNode(db, run, "inn");
}

describe("行程流程", () => {
  it("新遊戲：逍遙帶起始牌入隊，先看章節標題", () => {
    const run = newRun(db, 1, "standard");
    expect(run.party).toEqual(["li_xiaoyao"]);
    expect(run.members.li_xiaoyao!.deck).toHaveLength(9);
    expect(run.pending.kind).toBe("chapter_intro");
    expect(availableNodes(db, beginChapter(run)).map((n) => n.id)).toEqual(["s"]);
  });

  it("劇情選擇決定入隊；播完回地圖、下一個節點開放", () => {
    let run = beginChapter(newRun(db, 1, "standard"));
    run = enterNode(db, run, "s");
    expect(run.pending).toMatchObject({ kind: "story", storyId: "opening" });
    const skipped = completeStory(db, run, [1]);
    expect(skipped.party).toEqual(["li_xiaoyao"]);
    run = completeStory(db, run, [0]);
    expect(run.party).toEqual(["li_xiaoyao", "zhao_linger"]);
    expect(run.bonds.zhao_linger).toBe(1);
    expect(run.pending.kind).toBe("map");
    expect(availableNodes(db, run).map((n) => n.id)).toEqual(["fight"]);
    expect(() => enterNode(db, run, "boss")).toThrow();
  });

  it("flattenStory 依選擇展開", () => {
    const steps = db.stories.opening!.steps;
    expect(flattenStory(steps, [0])).toHaveLength(4);
    expect(flattenStory(steps, [1])).toHaveLength(2);
  });

  it("戰鬥：戰前劇情 → 戰鬥 → 選牌 → 戰後劇情 → 地圖", () => {
    let run = beginChapter(newRun(db, 1, "standard"));
    run = completeStory(db, enterNode(db, run, "s"), [0]);
    run = enterNode(db, run, "fight");
    expect(run.pending).toMatchObject({ kind: "story", storyId: "pre", then: "battle" });
    run = completeStory(db, run, []);
    expect(run.pending.kind).toBe("battle");
    if (run.pending.kind !== "battle") return;
    expect(battleDeck(run)).toHaveLength(17);
    expect(run.pending.battle.party).toHaveLength(2);
    run = winBattle(run);
    expect(run.pending.kind).toBe("reward");
    if (run.pending.kind !== "reward") return;
    expect(run.coins).toBe(10);
    expect(run.pending.choices[0]).toHaveLength(3);
    const pick = run.pending.choices[0]![0]!;
    run = takeReward(db, run, [pick]);
    expect(run.pending).toMatchObject({ kind: "story", storyId: "post" });
    run = completeStory(db, run, []);
    expect(run.coins).toBe(17);
    expect(run.pending.kind).toBe("map");
    const owner = db.cards[pick]!.owner!;
    expect(run.members[owner]!.deck.some((c) => c.defId === pick)).toBe(true);
  });

  it("戰敗：可重來，HP 至少回到 60%；可改用劇情難度", () => {
    let run = beginChapter(newRun(db, 1, "standard"));
    run = completeStory(db, enterNode(db, run, "s"), [1]);
    run = completeStory(db, enterNode(db, run, "fight"), []);
    if (run.pending.kind !== "battle") throw new Error();
    const lost = structuredClone(run.pending.battle);
    lost.outcome = "lost";
    lost.party[0]!.hp = 0;
    lost.party[0]!.downed = true;
    run = concludeBattle(db, updateBattle(run, lost));
    expect(run.pending.kind).toBe("battle_lost");
    run.members.li_xiaoyao!.hp = 3;
    run = retryBattle(db, run, true);
    expect(run.members.li_xiaoyao!.hp).toBe(Math.ceil(50 * 0.6));
    if (run.pending.kind !== "battle") throw new Error();
    expect(run.pending.battle.enemyHpScale).toBeCloseTo(0.6);
    expect(run.pending.attempt).toBe(1);
  });

  it("昏迷的隊員戰後回到 25%", () => {
    let run = beginChapter(newRun(db, 1, "standard"));
    run = completeStory(db, enterNode(db, run, "s"), [0]);
    run = completeStory(db, enterNode(db, run, "fight"), []);
    if (run.pending.kind !== "battle") throw new Error();
    const b = structuredClone(run.pending.battle);
    b.party[1]!.hp = 0;
    b.party[1]!.downed = true;
    run = winBattle(updateBattle(run, b));
    expect(run.members.zhao_linger!.hp).toBe(Math.ceil(50 * 0.25));
  });
});

describe("客棧", () => {
  it("休息回滿、只能一次", () => {
    let run = toInn();
    run.members.li_xiaoyao!.hp = 10;
    run = rest(run);
    expect(run.members.li_xiaoyao!.hp).toBe(50);
    expect(() => rest(run)).toThrow();
  });

  it("買牌扣錢、刪牌價格遞增、刪不到下限以下", () => {
    let run = toInn();
    run.coins = 500;
    if (run.pending.kind !== "inn") throw new Error();
    expect(run.pending.stock).toHaveLength(3);
    const price = run.pending.stock[0]!.price;
    run = buyCard(db, run, 0);
    expect(run.coins).toBe(500 - price);
    const p1 = removePrice(db, run);
    const ling = run.members.zhao_linger!.deck;
    const victim = run.members.li_xiaoyao!.deck[0]!.uid;
    run = removeCard(db, run, victim);
    expect(removePrice(db, run)).toBeGreaterThan(p1);
    // 靈兒只有 8 張（＋可能剛買的），刪到 8 張就不能再刪
    while (run.members.zhao_linger!.deck.length > 8) run = removeCard(db, run, run.members.zhao_linger!.deck[0]!.uid);
    expect(canRemove(run, run.members.zhao_linger!.deck[0]!.uid)).toMatch(/至少/);
    expect(ling.length).toBeGreaterThanOrEqual(8);
  });

  it("升級：同一張不能升兩次", () => {
    let run = toInn();
    run.coins = 500;
    const uid = run.members.li_xiaoyao!.deck.find((c) => c.defId === "li_a")!.uid;
    run = upgradeCard(db, run, uid);
    expect(run.members.li_xiaoyao!.deck.find((c) => c.uid === uid)!.upgraded).toBe(true);
    expect(() => upgradeCard(db, run, uid)).toThrow();
  });
});

describe("章節與離隊", () => {
  it("打倒章末頭目：拿法寶、進下一章，最大 HP +4 並回滿；永久離隊後牌不再出現", () => {
    let run = leaveInn(db, toInn());
    run = enterNode(db, run, "boss");
    run = winBattle(run);
    run = takeReward(db, run, [null]);
    expect(run.relics).toEqual(["pouch"]);
    expect(run.pending).toEqual({ kind: "chapter_intro", chapter: 1 });
    expect(run.members.li_xiaoyao!.maxHp).toBe(54);
    expect(run.members.li_xiaoyao!.hp).toBe(54);
    run = beginChapter(run);
    run = completeStory(db, enterNode(db, run, "bye"), []);
    expect(run.party).toEqual(["li_xiaoyao"]);
    expect(run.members.zhao_linger!.gone).toBe(true);
    expect(battleDeck(run).some((c) => c.defId.startsWith("ling_"))).toBe(false);
    expect(run.pending).toEqual({ kind: "ending" });
  });

  it("法寶：開場給全隊護體", () => {
    let run = leaveInn(db, toInn());
    run.relics = ["pouch"];
    run = enterNode(db, run, "boss");
    if (run.pending.kind !== "battle") throw new Error();
    expect(run.pending.battle.party.map((m) => m.block)).toEqual([3, 3]);
    // 開場護體在第一回合結束後的敵人回合才會被吸收；確認戰鬥仍可進行
    const step = endTurn(db, run.pending.battle);
    expect(step.state.turn).toBe(2);
  });
});

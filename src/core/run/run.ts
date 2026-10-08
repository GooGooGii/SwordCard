import { startBattle } from "../battle";
import { makeCtx, finish } from "../battle/context";
import { resolveEffects } from "../battle/effects";
import { actorFor } from "../battle/setup";
import { POTION_SLOTS } from "../battle/potions";
import { Rng } from "../rng";
import type { BattleEvent, BattleState, CardDef, CharId } from "../types";
import {
  battleDeck,
  chapterOf,
  CHAPTER_MAX_HP,
  DOWNED_RECOVERY,
  member,
  nodeOf,
  nodeSeed,
  relicsOf,
  RETRY_FLOOR,
  STORY_HP_SCALE,
  type GameDb,
} from "./db";
import { openInn } from "./inn";
import { addCardToRun, grantReward, rollCardChoices } from "./rewards";
import { applyStory, joinMember } from "./story";
import type { Difficulty, NodeDef, RunState } from "./types";

/**
 * 行程 reducer：每個函式接收舊的 RunState、回傳新的（不改原物件）。
 * pending 決定畫面現在該顯示什麼（地圖、劇情、戰鬥、獎勵、客棧…）。
 */

const clone = (run: RunState): RunState => structuredClone(run);

export function newRun(db: GameDb, seed: number, difficulty: Difficulty): RunState {
  const run: RunState = {
    version: 1,
    seed,
    difficulty,
    chapter: 0,
    visited: [],
    at: null,
    party: [],
    members: {},
    shared: [],
    coins: 0,
    relics: [],
    potions: Array(POTION_SLOTS).fill(null),
    bonds: {},
    flags: {},
    nextUid: 1,
    pending: { kind: "chapter_intro", chapter: 0 },
    losses: {},
    assisted: {},
    stats: { battles: 0, defeats: 0, cardsPlayed: 0, playMinutes: 0 },
  };
  joinMember(db, run, "li_xiaoyao");
  return run;
}

/** 章節標題卡看完 → 進入地圖 */
export function beginChapter(run: RunState): RunState {
  const next = clone(run);
  next.pending = { kind: "map" };
  return next;
}

/** 現在可以前往的節點 */
export function availableNodes(db: GameDb, run: RunState): NodeDef[] {
  const chapter = chapterOf(db, run);
  if (run.at === null) return [nodeOf(db, run, chapter.start)];
  return nodeOf(db, run, run.at)
    .next.filter((id) => !run.visited.includes(id))
    .map((id) => nodeOf(db, run, id));
}

export function enterNode(db: GameDb, run: RunState, nodeId: string): RunState {
  if (!availableNodes(db, run).some((n) => n.id === nodeId)) throw new Error(`node ${nodeId} not available`);
  const node = nodeOf(db, run, nodeId);
  const next = clone(run);
  switch (node.kind) {
    case "story":
    case "event":
      next.pending = { kind: "story", nodeId, storyId: node.story!, then: "map" };
      return next;
    case "battle":
      if (node.battle?.intro) {
        next.pending = { kind: "story", nodeId, storyId: node.battle.intro, then: "battle" };
        return next;
      }
      return beginBattle(db, next, nodeId, 0);
    case "inn":
      next.pending = openInn(db, next, nodeId);
      return next;
  }
}

/** 劇情播完：套用指令，然後依 then 繼續 */
export function completeStory(db: GameDb, run: RunState, choices: number[]): RunState {
  if (run.pending.kind !== "story") throw new Error("completeStory: not in story");
  const { nodeId, storyId, then } = run.pending;
  const next = clone(run);
  applyStory(db, next, storyId, choices);
  if (then === "battle") return beginBattle(db, next, nodeId, 0);
  return finishNode(db, next, nodeId);
}

export function beginBattle(db: GameDb, run: RunState, nodeId: string, attempt: number): RunState {
  const node = nodeOf(db, run, nodeId);
  const spec = node.battle;
  if (!spec) throw new Error(`${nodeId} is not a battle`);
  const next = clone(run);
  const storyMode = next.difficulty === "story" || next.assisted[nodeId];
  const relics = relicsOf(db, next);
  const { state } = startBattle(db, {
    seed: nodeSeed(next, nodeId, attempt),
    party: next.party.map((id) => ({ charId: id, hp: member(next, id).hp, maxHp: member(next, id).maxHp })),
    deck: battleDeck(next),
    enemies: spec.enemies,
    survive: spec.survive,
    enemyHpScale: storyMode ? STORY_HP_SCALE : 1,
  });
  // 法寶的常駐修正與開場效果
  state.handSize += relics.reduce((s, r) => s + (r.handSize ?? 0), 0);
  state.maxQi += relics.reduce((s, r) => s + (r.maxQi ?? 0), 0);
  state.comboMax = Math.max(2, state.comboMax + relics.reduce((s, r) => s + (r.comboMax ?? 0), 0));
  state.potions = [...(next.potions ?? Array(POTION_SLOTS).fill(null))];
  state.purse = next.coins;
  // 法寶的觸發效果：和心法一樣放進戰鬥狀態
  state.powers = relics
    .filter((r) => r.triggers?.length)
    .map((r) => ({ id: r.id, name: r.name, source: "relic" as const, owner: null, triggers: r.triggers!, counters: r.triggers!.map(() => 0) }));
  let battle = state;
  const starts = relics.flatMap((r) => r.battleStart ?? []);
  if (starts.length) battle = applyBattleStart(db, battle, starts);
  next.pending = { kind: "battle", nodeId, battle, attempt };
  return next;
}

/** 法寶的開場效果：當成一張無主牌結算（不花真氣、不進牌堆） */
function applyBattleStart(db: GameDb, battle: BattleState, effects: CardDef["effects"]): BattleState {
  const ctx = makeCtx(db, battle);
  const card: CardDef = { id: "relic", name: "法寶", owner: null, type: "skill", target: "none", rarity: "special", cost: 0, effects, motion: "cast", canon: "" };
  resolveEffects(ctx, { card, actor: actorFor(ctx.s, card), target: null, chainBonus: 0 });
  // 第一回合的真氣加成在 startBattle 之後才加上
  return finish(ctx).state;
}

/** 戰鬥中每一步都把新的戰鬥狀態寫回行程（存檔就存這個） */
export function updateBattle(run: RunState, battle: BattleState, cardsPlayed = 0): RunState {
  if (run.pending.kind !== "battle") throw new Error("updateBattle: not in battle");
  const next = clone(run);
  next.pending = { ...run.pending, battle };
  next.stats.cardsPlayed += cardsPlayed;
  return next;
}

/** 戰鬥結束：結算 HP、銅錢、戰利品，準備選牌（或進入戰敗畫面） */
export function concludeBattle(db: GameDb, run: RunState): RunState {
  if (run.pending.kind !== "battle") throw new Error("concludeBattle: not in battle");
  const { nodeId, battle, attempt } = run.pending;
  const outcome = battle.outcome;
  if (outcome === "ongoing") throw new Error("concludeBattle: battle still ongoing");
  const next = clone(run);
  next.stats.battles += 1;
  if (outcome === "lost") {
    next.stats.defeats += 1;
    next.losses[nodeId] = (next.losses[nodeId] ?? 0) + 1;
    next.pending = { kind: "battle_lost", nodeId, attempt };
    return next;
  }
  const node = nodeOf(db, next, nodeId);
  const chapter = chapterOf(db, next);
  const relics = relicsOf(db, next);
  for (const m of battle.party) {
    const rec = member(next, m.charId);
    rec.hp = m.downed ? Math.max(1, Math.ceil(rec.maxHp * DOWNED_RECOVERY)) : m.hp;
    const heal = relics.reduce((s, r) => s + (r.afterBattleHeal ?? 0), 0);
    if (!m.downed && heal) rec.hp = Math.min(rec.maxHp, rec.hp + heal);
  }
  const spec = node.battle!;
  const base = spec.boss ? chapter.coins.boss : spec.elite ? chapter.coins.elite : chapter.coins.normal;
  const failed = outcome === "survive_failed";
  const coins = Math.round((base + battle.coinsGained) * (failed ? 0.5 : 1)) + (spec.reward?.coins ?? 0);
  next.coins = Math.max(0, next.coins + coins);
  for (const id of battle.loot) addCardToRun(db, next, id);
  if (spec.reward) grantReward(db, next, { ...spec.reward, coins: 0, relic: undefined, cardChoices: 0 }, nodeId);
  const groups = failed ? 0 : (spec.reward?.cardChoices ?? 1);
  // 藥品：戰鬥中用掉的就沒了；勝利有機會掉一瓶（有空格才拿得到）
  next.potions = [...(battle.potions ?? next.potions ?? Array(POTION_SLOTS).fill(null))];
  const potion = failed ? null : rollPotionDrop(db, next, nodeId, spec.boss ? 1 : spec.elite ? 0.6 : 0.35);
  if (potion) next.potions[next.potions.indexOf(null)] = potion;
  next.pending = {
    kind: "reward",
    nodeId,
    coins,
    loot: battle.loot,
    choices: rollCardChoices(db, next, nodeId, groups),
    relic: spec.reward?.relic ?? (spec.elite && !failed ? rollRelicDrop(db, next, nodeId) : null),
    outcomeNote: outcome === "survived" ? "撐過來了" : failed ? "雖然倒下，故事仍繼續" : "勝利",
    potion,
  };
  delete next.losses[nodeId];
  return next;
}

const POTION_WEIGHT = { common: 6, uncommon: 3, rare: 1 } as const;

/** 精英戰掉落法寶：一般 75%、稀有 25%，不重複；都拿過了就沒有 */
function rollRelicDrop(db: GameDb, run: RunState, nodeId: string): string | null {
  const pool = Object.values(db.relics).filter((r) => (r.tier === "common" || r.tier === "rare") && !run.relics.includes(r.id));
  if (pool.length === 0) return null;
  const rng = new Rng(nodeSeed(run, nodeId, 0) ^ 0x2545f491);
  return rng.weighted(pool.map((r) => ({ value: r.id, weight: r.tier === "common" ? 3 : 1 }))) ?? null;
}

/** 戰後掉落藥品：依機率、稀有度加權；藥品欄滿了就沒有 */
function rollPotionDrop(db: GameDb, run: RunState, nodeId: string, chance: number): string | null {
  if (!run.potions?.includes(null)) return null;
  const pool = Object.values(db.potions ?? {});
  if (pool.length === 0) return null;
  const rng = new Rng(nodeSeed(run, nodeId, 0) ^ 0x5f3759df);
  if (rng.next() >= chance) return null;
  return rng.weighted(pool.map((p) => ({ value: p.id, weight: POTION_WEIGHT[p.rarity] })));
}

/** 戰敗後重來：HP 至少回到 60%；assist＝這場改用劇情難度 */
export function retryBattle(db: GameDb, run: RunState, assist: boolean): RunState {
  if (run.pending.kind !== "battle_lost") throw new Error("retryBattle: not lost");
  const { nodeId, attempt } = run.pending;
  const next = clone(run);
  for (const id of next.party) {
    const m = member(next, id);
    m.hp = Math.max(m.hp, Math.ceil(m.maxHp * RETRY_FLOOR));
  }
  if (assist) next.assisted[nodeId] = true;
  return beginBattle(db, next, nodeId, attempt + 1);
}

/** 選牌（每組選一張或跳過＝null），拿法寶，然後戰後劇情或回地圖 */
export function takeReward(db: GameDb, run: RunState, picks: (string | null)[]): RunState {
  if (run.pending.kind !== "reward") throw new Error("takeReward: not in reward");
  const { nodeId, choices, relic } = run.pending;
  const next = clone(run);
  picks.forEach((pick, g) => {
    if (pick === null) {
      next.coins += 10; // 跳過選牌換一點銅錢（REDESIGN §2）
      return;
    }
    if (!choices[g]?.includes(pick)) throw new Error(`takeReward: ${pick} not offered`);
    addCardToRun(db, next, pick);
  });
  if (relic && !next.relics.includes(relic)) next.relics.push(relic);
  const outro = nodeOf(db, next, nodeId).battle?.outro;
  if (outro) {
    next.pending = { kind: "story", nodeId, storyId: outro, then: "after_battle" };
    return next;
  }
  return finishNode(db, next, nodeId);
}

/** 節點完成：記錄、回地圖；章末節點 → 下一章（或結局） */
export function finishNode(db: GameDb, run: RunState, nodeId: string): RunState {
  const next = run;
  if (!next.visited.includes(nodeId)) next.visited.push(nodeId);
  next.at = nodeId;
  const chapter = chapterOf(db, next);
  if (nodeId !== chapter.end) {
    next.pending = { kind: "map" };
    return next;
  }
  return advanceChapter(db, next);
}

function advanceChapter(db: GameDb, run: RunState): RunState {
  run.chapter += 1;
  run.visited = [];
  run.at = null;
  run.losses = {};
  if (run.chapter >= db.chapters.length) {
    run.pending = { kind: "ending" };
    return run;
  }
  // 新的一章：全隊最大 HP +4 並回滿（REDESIGN §2.1）
  for (const id of Object.keys(run.members) as CharId[]) {
    const m = run.members[id]!;
    if (m.gone) continue;
    m.maxHp += CHAPTER_MAX_HP;
    m.hp = m.maxHp;
  }
  run.pending = { kind: "chapter_intro", chapter: run.chapter };
  return run;
}

export type { BattleEvent };

import { Rng } from "../rng";
import type { CharId } from "../types";
import { chapterOf, member, MIN_DECK_PER_MEMBER, nodeOf, nodeSeed, relicsOf, type GameDb } from "./db";
import { addCardToRun } from "./rewards";
import { finishNode } from "./run";
import type { Pending, RunState } from "./types";

/**
 * 客棧（REDESIGN §2）：休息回滿、買牌、刪牌、升級。每項都要花錢（休息除外），
 * 刪牌與升級價格隨次數上升，避免舊專案「躺著全買」的通膨。
 */
export const PRICES = {
  common: 45,
  uncommon: 70,
  rare: 105,
  removeBase: 50,
  removeStep: 25,
} as const;

type InnPending = Extract<Pending, { kind: "inn" }>;

function discount(db: GameDb, run: RunState): number {
  const pct = relicsOf(db, run).reduce((s, r) => s + (r.shopDiscount ?? 0), 0);
  return Math.max(0.5, 1 - pct / 100);
}

export function openInn(db: GameDb, run: RunState, nodeId: string): InnPending {
  const node = nodeOf(db, run, nodeId);
  const size = node.inn?.shopSize ?? 5;
  const rng = new Rng(nodeSeed(run, `shop:${nodeId}`, 0));
  const owners: CharId[] = run.party.length ? [...run.party] : ["li_xiaoyao"];
  const chapter = chapterOf(db, run);
  const stock: InnPending["stock"] = [];
  const seen = new Set<string>();
  for (let i = 0, guard = 0; stock.length < size && guard < 300; guard++, i++) {
    const owner = owners[i % owners.length]!;
    const rarity = rng.weighted([
      { value: "common" as const, weight: chapter.rarity.common },
      { value: "uncommon" as const, weight: chapter.rarity.uncommon },
      { value: "rare" as const, weight: chapter.rarity.rare },
    ]);
    const pool = Object.values(db.cards).filter((c) => c.owner === owner && c.rarity === rarity && !seen.has(c.id));
    if (pool.length === 0) continue;
    const card = rng.pick(pool);
    seen.add(card.id);
    stock.push({ card: card.id, price: Math.round(PRICES[rarity] * discount(db, run)), sold: false });
  }
  // 無主牌一張（殺戮尖塔商店的無色牌）：比同稀有度貴兩成
  const colorless = Object.values(db.cards).filter((c) => c.owner === null && ["common", "uncommon", "rare"].includes(c.rarity) && c.type !== "item");
  if (colorless.length > 0) {
    const c = rng.pick(colorless);
    stock.push({ card: c.id, price: Math.round(PRICES[c.rarity as "common" | "uncommon" | "rare"] * 1.2 * discount(db, run)), sold: false });
  }
  // 藥品兩瓶
  const potionPool = Object.values(db.potions ?? {});
  const potions: InnPending["potions"] = [];
  for (let k = 0; k < 2 && potionPool.length > 0; k++) {
    const p = rng.weighted(potionPool.map((x) => ({ value: x, weight: x.rarity === "common" ? 6 : x.rarity === "uncommon" ? 3 : 1 })));
    potions.push({ potion: p.id, price: Math.round(POTION_PRICES[p.rarity] * discount(db, run)), sold: false });
  }
  return { kind: "inn", nodeId, stock, rested: false, removed: 0, upgraded: 0, potions };
}

export const POTION_PRICES = { common: 35, uncommon: 55, rare: 85 } as const;

/** 買藥：藥品欄要有空格 */
export function buyPotion(db: GameDb, run: RunState, index: number): RunState {
  const next = structuredClone(run);
  const item = inn(next).potions?.[index];
  if (!item || item.sold) throw new Error("buyPotion: not available");
  if (next.coins < item.price) throw new Error("buyPotion: 銅錢不足");
  const slots = next.potions ?? [null, null, null];
  const free = slots.indexOf(null);
  if (free < 0) throw new Error("buyPotion: 藥品欄滿了");
  slots[free] = item.potion;
  next.potions = slots;
  next.coins -= item.price;
  item.sold = true;
  return next;
}

function inn(run: RunState): InnPending {
  if (run.pending.kind !== "inn") throw new Error("not at inn");
  return run.pending;
}

export function removePrice(db: GameDb, run: RunState): number {
  return Math.round((PRICES.removeBase + PRICES.removeStep * inn(run).removed) * discount(db, run));
}

/**
 * 客棧歇腳二選一（殺戮尖塔的營火，2026-10-08 使用者要求升級機制）：
 * 休息＝全隊回復最大生命的 30%；練功＝免費升級一張牌。兩者只能選一個（p.rested 表示今晚已經歇過）。
 */
export const REST_HEAL = 0.3;

export function rest(run: RunState): RunState {
  const next = structuredClone(run);
  const p = inn(next);
  if (p.rested) throw new Error("rest: 今晚已經歇過了");
  for (const id of next.party) {
    const m = member(next, id);
    m.hp = Math.min(m.maxHp, m.hp + Math.ceil(m.maxHp * REST_HEAL));
  }
  p.rested = true;
  return next;
}

/** 練功：免費升級一張牌（和休息二選一） */
export function train(db: GameDb, run: RunState, uid: number): RunState {
  const next = structuredClone(run);
  const p = inn(next);
  if (p.rested) throw new Error("train: 今晚已經歇過了");
  const card = [...next.party.flatMap((id) => member(next, id).deck), ...next.shared].find((c) => c.uid === uid);
  if (!card || card.upgraded || !db.cards[card.defId]?.upgrade) throw new Error("train: 這張牌不能升級");
  card.upgraded = true;
  p.upgraded += 1;
  p.rested = true;
  return next;
}

export function buyCard(db: GameDb, run: RunState, index: number): RunState {
  const next = structuredClone(run);
  const item = inn(next).stock[index];
  if (!item || item.sold) throw new Error("buyCard: not available");
  if (next.coins < item.price) throw new Error("buyCard: 銅錢不足");
  next.coins -= item.price;
  item.sold = true;
  addCardToRun(db, next, item.card);
  return next;
}

/** 刪牌：不能刪到該角色低於下限（REDESIGN §2.1） */
export function canRemove(run: RunState, uid: number): string | null {
  for (const id of run.party) {
    const deck = member(run, id).deck;
    if (deck.some((c) => c.uid === uid)) return deck.length <= MIN_DECK_PER_MEMBER ? `每人至少要留 ${MIN_DECK_PER_MEMBER} 張牌` : null;
  }
  if (run.shared.some((c) => c.uid === uid)) return null;
  return "找不到這張牌";
}

export function removeCard(db: GameDb, run: RunState, uid: number): RunState {
  const reason = canRemove(run, uid);
  if (reason) throw new Error(`removeCard: ${reason}`);
  const price = removePrice(db, run);
  if (run.coins < price) throw new Error("removeCard: 銅錢不足");
  const next = structuredClone(run);
  next.coins -= price;
  inn(next).removed += 1;
  for (const id of next.party) member(next, id).deck = member(next, id).deck.filter((c) => c.uid !== uid);
  next.shared = next.shared.filter((c) => c.uid !== uid);
  return next;
}

export function leaveInn(db: GameDb, run: RunState): RunState {
  const next = structuredClone(run);
  return finishNode(db, next, inn(next).nodeId);
}

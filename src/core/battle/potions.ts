import type { BattleState, CardDef, ContentDb, PotionDef } from "../types";
import { enemyRef, finish, makeCtx, partyRef, checkOutcome } from "./context";
import { resolveEffects } from "./effects";
import { actorFor } from "./setup";
import type { BattleStep } from "./turn";

export const POTION_SLOTS = 3;

function potionOf(db: ContentDb, state: BattleState, slot: number): PotionDef | null {
  const id = state.potions?.[slot];
  return id ? db.potions?.[id] ?? null : null;
}

/** 這瓶藥現在能不能用？可以回傳 null，不行回傳原因 */
export function canUsePotion(db: ContentDb, state: BattleState, slot: number, target: number | null = null): string | null {
  if (state.outcome !== "ongoing") return "戰鬥已經結束";
  const potion = potionOf(db, state, slot);
  if (!potion) return "這格沒有藥品";
  if (potion.target === "enemy") {
    const e = target !== null ? state.enemies[target] : undefined;
    if (!e || e.dead) return "請選擇一名敵人";
  }
  if (potion.target === "ally") {
    const m = target !== null ? state.party[target] : undefined;
    const revives = potion.effects.some((x) => x.kind === "revive");
    if (!m || (m.downed && !revives)) return "請選擇一名隊友";
  }
  return null;
}

/** 用藥：不花真氣、不進牌堆、不算出牌（不觸發連鎖、合擊氣與「打出牌時」的心法） */
export function usePotion(db: ContentDb, state: BattleState, slot: number, target: number | null = null): BattleStep {
  const reason = canUsePotion(db, state, slot, target);
  if (reason) throw new Error(`usePotion: ${reason}`);
  const ctx = makeCtx(db, state);
  const potion = potionOf(db, ctx.s, slot)!;
  ctx.s.potions![slot] = null;
  const card: CardDef = {
    id: potion.id, name: potion.name, owner: null, type: "item", target: potion.target, rarity: "special",
    cost: 0, effects: potion.effects, motion: "cast", canon: potion.canon,
  };
  const actor = actorFor(ctx.s, card);
  const ref = target === null ? null : potion.target === "ally" ? partyRef(target) : potion.target === "enemy" ? enemyRef(target) : null;
  ctx.events.push({ type: "potion", id: potion.id, actor: actor === null ? null : partyRef(actor), target: ref });
  resolveEffects(ctx, { card, actor, target, chainBonus: 0 });
  checkOutcome(ctx);
  return finish(ctx);
}

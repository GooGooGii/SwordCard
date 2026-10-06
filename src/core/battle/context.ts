import { Rng } from "../rng";
import type { BattleEvent, BattleState, ContentDb, Ref } from "../types";
import { aliveEnemies, aliveParty } from "./setup";

/** 一次 reducer 呼叫的工作環境：狀態是複製出來的，可以直接改。 */
export interface Ctx {
  db: ContentDb;
  s: BattleState;
  rng: Rng;
  events: BattleEvent[];
}

export function makeCtx(db: ContentDb, state: BattleState): Ctx {
  const s = structuredClone(state);
  return { db, s, rng: new Rng(s.rng), events: [] };
}

export function finish(ctx: Ctx): { state: BattleState; events: BattleEvent[] } {
  ctx.s.rng = ctx.rng.state;
  return { state: ctx.s, events: ctx.events };
}

export const partyRef = (index: number): Ref => ({ side: "party", index });
export const enemyRef = (index: number): Ref => ({ side: "enemy", index });

/** 判定勝負；已有結果時回傳 true（呼叫端應停止後續處理）。 */
export function checkOutcome(ctx: Ctx): boolean {
  const { s } = ctx;
  if (s.outcome !== "ongoing") return true;
  if (aliveEnemies(ctx.db, s).length === 0) {
    s.outcome = "won";
  } else if (aliveParty(s).length === 0) {
    s.outcome = s.survive !== null ? "survive_failed" : "lost";
  }
  if (s.outcome !== "ongoing") {
    ctx.events.push({ type: "outcome", outcome: s.outcome });
    return true;
  }
  return false;
}

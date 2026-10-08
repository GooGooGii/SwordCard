import { canPlay } from "../../core/battle";
import type { BattleState, ContentDb } from "../../core/types";

/**
 * 合法目標只有一個時回傳它（只剩一隻敵人、單人隊伍…），否則 null：要玩家自己選。
 * 同一張牌再點一次、或往上拖沒拖到目標時，用它直接出牌（FEEL-003）。
 * 頭目＋可攻擊的場地這種兩個目標的情況仍要選。
 */
export function soleTarget(db: ContentDb, battle: BattleState, uid: number, kind: "enemy" | "party" | null): number | null {
  if (!kind) return null;
  const count = kind === "enemy" ? battle.enemies.length : battle.party.length;
  const legal: number[] = [];
  for (let i = 0; i < count; i++) if (!canPlay(db, battle, uid, i)) legal.push(i);
  return legal.length === 1 ? legal[0]! : null;
}

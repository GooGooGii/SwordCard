import { matchup, STRONG_MULTIPLIER, WEAK_MULTIPLIER } from "../elements";
import type { Element, StatusBag } from "../types";

export const WEAK_FACTOR = 0.75;
export const VULNERABLE_FACTOR = 1.5;

export interface DamageInput {
  base: number;
  attacker: StatusBag | null;
  defender: StatusBag | null;
  attackElement?: Element;
  defendElement?: Element;
  /** 相生連鎖加成（只有帶屬性的牌） */
  chainBonus?: number;
  /** Boss 意圖被破勢減半 */
  halved?: boolean;
}

export interface DamageResult {
  amount: number;
  effective: "strong" | "weak" | "normal";
}

/**
 * 傷害計算順序（REDESIGN §4.2，卡面預測值也用這個）：
 * 基礎 + 氣勢 + 連鎖 → × 相剋 → × 弱化（攻方）→ × 破綻（守方）→ ×0.5（破勢減半）→ 無條件捨去
 * 扣護體在 applyDamage 做。
 */
export function computeDamage(input: DamageInput): DamageResult {
  let value = input.base + (input.attacker?.strength ?? 0) + (input.chainBonus ?? 0);
  const effective = matchup(input.attackElement, input.defendElement);
  if (effective === "strong") value *= STRONG_MULTIPLIER;
  if (effective === "weak") value *= WEAK_MULTIPLIER;
  if ((input.attacker?.weak ?? 0) > 0) value *= WEAK_FACTOR;
  if ((input.defender?.vulnerable ?? 0) > 0) value *= VULNERABLE_FACTOR;
  if (input.halved) value *= 0.5;
  return { amount: Math.max(0, Math.floor(value)), effective };
}

/** 先扣護體再扣 HP；回傳實際扣的 HP 與被護體擋下的量 */
export function absorb(target: { hp: number; block: number }, amount: number): { hpLoss: number; blocked: number } {
  const blocked = Math.min(target.block, amount);
  target.block -= blocked;
  const hpLoss = Math.min(target.hp, amount - blocked);
  target.hp -= hpLoss;
  return { hpLoss, blocked };
}

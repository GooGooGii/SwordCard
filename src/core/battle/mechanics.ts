import type { DebuffStatus, Element, StatusBag } from "../types";
import { checkOutcome, enemyRef, partyRef, type Ctx } from "./context";
import { absorb, computeDamage } from "./damage";
import { newEnemy } from "./setup";

export const HAND_LIMIT = 10;
export const GU_LIMIT = 5;

// ── 抽牌 ─────────────────────────────────────────────────────────────────────

export function drawCards(ctx: Ctx, count: number): number {
  const { s } = ctx;
  let drawn = 0;
  for (let i = 0; i < count; i++) {
    if (s.hand.length >= HAND_LIMIT) break;
    if (s.draw.length === 0) {
      if (s.discard.length === 0) break;
      s.draw = ctx.rng.shuffle(s.discard);
      s.discard = [];
    }
    s.hand.push(s.draw.pop()!);
    drawn++;
  }
  if (drawn > 0) ctx.events.push({ type: "draw", count: drawn });
  return drawn;
}

// ── 對敵人 ───────────────────────────────────────────────────────────────────

/** 場地還在嗎（水域、血池） */
export function fieldAlive(ctx: Ctx, fieldId: string): boolean {
  return ctx.s.enemies.some((e) => e.defId === fieldId && !e.dead);
}

export interface HitOptions {
  base: number;
  attacker: StatusBag | null;
  element?: Element;
  chainBonus?: number;
  sourceIndex: number | null;
}

/** 攻擊一名敵人；回傳相剋結果（強／弱／一般），敵人已死回傳 null。 */
export function hitEnemy(ctx: Ctx, index: number, opts: HitOptions): "strong" | "weak" | "normal" | null {
  const enemy = ctx.s.enemies[index];
  if (!enemy || enemy.dead) return null;
  const def = ctx.db.enemies[enemy.defId]!;
  const { amount, effective } = computeDamage({
    base: opts.base,
    attacker: opts.attacker,
    defender: enemy.status,
    attackElement: opts.element,
    defendElement: def.element,
    chainBonus: opts.chainBonus,
  });
  const { hpLoss, blocked } = absorb(enemy, amount);
  ctx.events.push({
    type: "damage",
    target: enemyRef(index),
    amount: hpLoss,
    blocked,
    effective,
    source: opts.sourceIndex === null ? null : partyRef(opts.sourceIndex),
  });
  settleEnemyHp(ctx, index);
  return effective;
}

/** 敵人 HP ≤ 0 時：有「場地保護」就留 1，否則死亡。 */
export function settleEnemyHp(ctx: Ctx, index: number): void {
  const enemy = ctx.s.enemies[index]!;
  if (enemy.dead || enemy.hp > 0) return;
  const def = ctx.db.enemies[enemy.defId]!;
  const guard = def.passives?.find((p) => p.kind === "undying_while");
  if (guard && guard.kind === "undying_while" && fieldAlive(ctx, guard.fieldId)) {
    enemy.hp = 1;
    return;
  }
  enemy.dead = true;
  enemy.intent = null;
  enemy.block = 0;
  ctx.events.push({ type: "enemy_died", target: enemyRef(index) });
  if (def.successor) {
    ctx.s.enemies[index] = newEnemy(ctx.db, def.successor, ctx.s.nextUid++, ctx.s.enemyHpScale);
    ctx.events.push({ type: "summon", target: enemyRef(index) });
  }
  checkOutcome(ctx);
}

export function addBreak(ctx: Ctx, index: number, stacks: number): void {
  const enemy = ctx.s.enemies[index];
  if (!enemy || enemy.dead) return;
  const def = ctx.db.enemies[enemy.defId]!;
  if (def.isField) return;
  enemy.breakStacks = Math.min(enemy.breakThreshold, enemy.breakStacks + stacks);
  ctx.events.push({ type: "status", target: enemyRef(index), status: "break", amount: enemy.breakStacks });
  if (enemy.breakStacks < enemy.breakThreshold || enemy.breakTriggeredThisTurn || !enemy.intent) return;
  // 防鎖死：每回合最多觸發一次，每次觸發門檻 +1（REDESIGN §4.2）
  if (def.isBoss) enemy.intent.halved = true;
  else enemy.intent.cancelled = true;
  enemy.breakStacks = 0;
  enemy.breakThreshold += 1;
  enemy.breakTriggeredThisTurn = true;
  ctx.events.push({ type: "break", target: enemyRef(index), result: def.isBoss ? "halved" : "cancelled" });
}

export function applyToEnemy(ctx: Ctx, index: number, status: DebuffStatus, amount: number): void {
  const enemy = ctx.s.enemies[index];
  if (!enemy || enemy.dead) return;
  if (status === "break") {
    addBreak(ctx, index, amount);
    return;
  }
  enemy.status[status] += amount;
  ctx.events.push({ type: "status", target: enemyRef(index), status, amount: enemy.status[status] });
}

// ── 對隊員 ───────────────────────────────────────────────────────────────────

/** 敵人攻擊隊員；隊員有反擊時回打。回傳實際扣的 HP。 */
export function hitMember(ctx: Ctx, memberIndex: number, base: number, enemyIndex: number, halved: boolean): number {
  const member = ctx.s.party[memberIndex];
  const enemy = ctx.s.enemies[enemyIndex];
  if (!member || member.downed || !enemy) return 0;
  const { amount } = computeDamage({ base, attacker: enemy.status, defender: member.status, halved });
  const { hpLoss, blocked } = absorb(member, amount);
  ctx.events.push({ type: "damage", target: partyRef(memberIndex), amount: hpLoss, blocked, effective: "normal", source: enemyRef(enemyIndex) });
  if (member.counter > 0 && !enemy.dead) {
    const counter = member.counter;
    const loss = absorb(enemy, counter);
    ctx.events.push({ type: "counter", actor: partyRef(memberIndex), target: enemyRef(enemyIndex), amount: loss.hpLoss });
    settleEnemyHp(ctx, enemyIndex);
  }
  settleMemberHp(ctx, memberIndex);
  return hpLoss;
}

export function settleMemberHp(ctx: Ctx, index: number): void {
  const member = ctx.s.party[index]!;
  if (member.downed || member.hp > 0) return;
  member.hp = 0;
  member.downed = true;
  member.block = 0;
  member.counter = 0;
  ctx.events.push({ type: "downed", target: partyRef(index) });
  checkOutcome(ctx);
}

/** 中毒：無視護體扣血，然後層數 -1。 */
export function tickPoison(ctx: Ctx, side: "party" | "enemy", index: number): void {
  const unit = side === "party" ? ctx.s.party[index] : ctx.s.enemies[index];
  if (!unit || unit.status.poison <= 0) return;
  if (side === "party" ? (unit as { downed: boolean }).downed : (unit as { dead: boolean }).dead) return;
  const amount = Math.min(unit.hp, unit.status.poison);
  unit.hp -= amount;
  unit.status.poison -= 1;
  const target = side === "party" ? partyRef(index) : enemyRef(index);
  ctx.events.push({ type: "damage", target, amount, blocked: 0, effective: "normal", source: null });
  if (side === "party") settleMemberHp(ctx, index);
  else settleEnemyHp(ctx, index);
}

/** 弱化、破綻在單位自己的回合結束時 -1 */
export function decayStatus(status: StatusBag): void {
  if (status.weak > 0) status.weak -= 1;
  if (status.vulnerable > 0) status.vulnerable -= 1;
}

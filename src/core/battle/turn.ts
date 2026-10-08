import { nextInChain } from "../elements";
import type { BattleEvent, BattleState, ContentDb } from "../types";
import { checkOutcome, enemyRef, finish, makeCtx, partyRef, type Ctx } from "./context";
import { resolveEffects } from "./effects";
import { applyPassives, chooseIntents, executeIntent } from "./enemy";
import { applyToEnemy, decayStatus, drawCards, hitEnemy, tickPoison } from "./mechanics";
import { actorFor, aliveEnemies, aliveParty, createBattle, effectiveCard, type BattleSetup } from "./setup";
import { THOUGHT_CARD_ID } from "../cards";
import { ctl } from "./control";
import { addPower, fireTriggers } from "./triggers";

export type BattleStep = { state: BattleState; events: BattleEvent[] };

/** 合擊條件（正史）：在場至少 2 人，而且沒有人虛弱（HP 低於 20%） */
export const WEAK_HP_RATIO = 0.2;

export function startBattle(db: ContentDb, setup: BattleSetup): BattleStep {
  const ctx = makeCtx(db, createBattle(db, setup));
  startPlayerTurn(ctx);
  return finish(ctx);
}

function startPlayerTurn(ctx: Ctx): void {
  const { s } = ctx;
  if (s.outcome !== "ongoing") return;
  s.turn += 1;
  // 求生戰：撐過指定回合數
  if (s.survive !== null && s.turn > s.survive) {
    s.outcome = "survived";
    ctx.events.push({ type: "outcome", outcome: "survived" });
    return;
  }
  ctx.events.push({ type: "turn_start", turn: s.turn });
  s.qi = s.maxQi;
  s.chain = { last: null, count: 0 };
  for (const m of s.party) {
    m.block = 0;
    m.counter = 0;
  }
  for (const i of aliveParty(s)) {
    tickPoison(ctx, "party", i);
    if (checkOutcome(ctx)) return;
  }
  for (const e of s.enemies) e.breakTriggeredThisTurn = false;
  applyPassives(ctx);
  // 御劍：上回合放出去的飛劍在這時落下
  const swords = s.flyingSwords;
  s.flyingSwords = [];
  for (const sword of swords) {
    const alive = aliveEnemies(ctx.db, s);
    if (alive.length === 0) break;
    let index = s.enemies.findIndex((e) => e.uid === sword.targetUid && !e.dead);
    if (index < 0) index = alive[0]!;
    ctx.events.push({ type: "fly_sword", target: enemyRef(index), amount: sword.amount });
    hitEnemy(ctx, index, { base: sword.amount, attacker: null, sourceIndex: null });
    if (checkOutcome(ctx)) return;
  }
  drawCards(ctx, s.handSize);
  fireTriggers(ctx, "turn_start");
  if (checkOutcome(ctx)) return;
  chooseIntents(ctx);
  checkOutcome(ctx);
}

/** 這張牌現在能不能打？可以回傳 null，不行回傳原因（給 UI 顯示）。 */
export function canPlay(db: ContentDb, state: BattleState, uid: number, target: number | null = null): string | null {
  if (state.outcome !== "ongoing") return "戰鬥已經結束";
  const card = state.hand.find((c) => c.uid === uid);
  if (!card) return "這張牌不在手上";
  const def = effectiveCard(db, state, card);
  if (def.unplayable) return "這張牌不能打出";
  if (def.cost > state.qi) return "真氣不足";
  const coins = def.effects.reduce((sum, e) => sum + (e.kind === "spend_coins" ? e.amount : 0), 0);
  if (coins > 0 && (state.purse ?? 0) < coins) return `銅錢不足（需要 ${coins} 文）`;
  // 控制狀態：牌的主人被定身／昏睡就不能出他的牌；被封印不能出仙術
  if (def.owner) {
    const m = state.party.find((p) => p.charId === def.owner);
    if (m && !m.downed) {
      const name = db.characters[def.owner]?.name ?? "";
      if (ctl(m.status, "stun") > 0) return `${name}被定身了`;
      if (ctl(m.status, "sleep") > 0) return `${name}昏睡中`;
      if (ctl(m.status, "seal") > 0 && def.type === "spell") return `${name}被封印，不能施展仙術`;
    }
  }
  if (def.type === "combo") {
    const alive = aliveParty(state);
    if (alive.length < 2) return "合擊需要至少兩人在場";
    if (alive.some((i) => state.party[i]!.hp < state.party[i]!.maxHp * WEAK_HP_RATIO)) return "有人太虛弱，無法合擊";
  }
  if (def.target === "enemy") {
    const e = target !== null ? state.enemies[target] : undefined;
    if (!e || e.dead) return "請選擇一名敵人";
  }
  if (def.target === "ally") {
    const m = target !== null ? state.party[target] : undefined;
    const revives = def.effects.some((x) => x.kind === "revive");
    if (!m || (m.downed && !revives)) return "請選擇一名隊友";
  }
  return null;
}

export function playCard(db: ContentDb, state: BattleState, uid: number, target: number | null = null): BattleStep {
  // target 可能因混亂改變（見下方），所以是 let 語意的參數
  const reason = canPlay(db, state, uid, target);
  if (reason) throw new Error(`playCard: ${reason}`);
  const ctx = makeCtx(db, state);
  const { s } = ctx;
  const handIndex = s.hand.findIndex((c) => c.uid === uid);
  const card = s.hand.splice(handIndex, 1)[0]!;
  const def = effectiveCard(db, s, card);
  const isThought = def.id === THOUGHT_CARD_ID;
  s.qi -= def.cost;
  const actor = actorFor(s, def);
  // 混亂：單體牌的目標隨機（可能打到別的敵人）
  if (actor !== null && def.target === "enemy" && ctl(s.party[actor]!.status, "confuse") > 0) {
    const pool = s.enemies.flatMap((e, i) => (e.dead ? [] : [i]));
    if (pool.length > 0) target = ctx.rng.pick(pool);
  }

  // 相生連鎖：接上前一張就 +1，接不上就從這張重新開始
  let chainBonus = 0;
  if (def.element && !isThought) {
    if (s.chain.last && def.element === nextInChain(s.chain.last)) {
      s.chain.count += 1;
      chainBonus = s.chain.count;
      ctx.events.push({ type: "chain", count: s.chain.count, element: def.element });
    } else {
      s.chain.count = 0;
    }
    s.chain.last = def.element;
  }

  const targetRef = target === null ? null : def.target === "ally" ? partyRef(target) : def.target === "enemy" ? enemyRef(target) : null;
  ctx.events.push({ type: "card_played", uid: card.uid, defId: def.id, actor: actor === null ? null : partyRef(actor), target: targetRef });
  const result = resolveEffects(ctx, { card: def, actor, target, chainBonus });

  // 心法：打出後整場常駐，牌本身移出（殺戮尖塔的能力牌）
  if (def.type === "power" && def.power) {
    addPower(ctx, { id: def.id, name: def.name, source: "card", owner: def.owner, triggers: def.power.triggers });
  }
  if (def.exhaust || def.type === "combo" || def.type === "power") s.exhaust.push(card);
  else s.discard.push(card);
  if (!isThought && s.outcome === "ongoing") fireTriggers(ctx, "play", { card: def });

  // 合擊氣：換人出手就 +1；滿了，最後出手的人的合擊牌加入手牌
  if (def.owner && !isThought && def.type !== "combo") {
    if (s.lastOwner && s.lastOwner !== def.owner) s.comboGauge = Math.min(s.comboMax, s.comboGauge + 1);
    s.lastOwner = def.owner;
  }
  if (s.comboGauge >= s.comboMax && def.owner && !isThought) {
    const comboId = db.characters[def.owner]?.comboCard;
    const holding = s.hand.some((c) => db.cards[c.defId]?.type === "combo");
    if (comboId && db.cards[comboId] && !holding) {
      s.hand.push({ uid: s.nextUid++, defId: comboId, upgraded: false });
      s.comboGauge = 0;
      ctx.events.push({ type: "combo_ready", charId: def.owner });
    }
  }

  if (!checkOutcome(ctx) && result.endTurn) endPlayerTurn(ctx);
  return finish(ctx);
}

export function endTurn(db: ContentDb, state: BattleState): BattleStep {
  if (state.outcome !== "ongoing") throw new Error("endTurn: 戰鬥已經結束");
  const ctx = makeCtx(db, state);
  endPlayerTurn(ctx);
  return finish(ctx);
}

function endPlayerTurn(ctx: Ctx): void {
  const { s } = ctx;
  fireTriggers(ctx, "turn_end");
  if (checkOutcome(ctx)) return;
  // 阿奴的蠱：每隻蠱讓最前面的敵人中毒 1 層
  if (s.gu > 0) {
    const front = aliveEnemies(ctx.db, s)[0];
    if (front !== undefined) {
      ctx.events.push({ type: "gu", count: s.gu });
      applyToEnemy(ctx, front, "poison", s.gu);
    }
  }
  // 狀態牌／詛咒牌：回合結束時還在手上就發作
  for (const c of s.hand) {
    const def = db(ctx, c.defId);
    if (!def?.inHandAtTurnEnd?.length) continue;
    const card = { ...def, owner: null, effects: def.inHandAtTurnEnd };
    resolveEffects(ctx, { card, actor: actorFor(s, card), target: null, chainBonus: 0 });
    if (checkOutcome(ctx)) return;
  }
  const kept = s.hand.filter((c) => db(ctx, c.defId)?.retain);
  s.discard.push(...s.hand.filter((c) => !db(ctx, c.defId)?.retain));
  s.hand = kept;
  for (const m of s.party) decayStatus(m.status, true);

  // 敵人回合：護體歸零 → 中毒 → 執行意圖
  for (let i = 0; i < s.enemies.length; i++) {
    const enemy = s.enemies[i]!;
    if (enemy.dead || ctx.db.enemies[enemy.defId]!.isField) continue;
    enemy.block = 0;
    tickPoison(ctx, "enemy", i);
    if (checkOutcome(ctx)) return;
    executeIntent(ctx, i);
    if (checkOutcome(ctx)) return;
  }
  for (const e of s.enemies) if (!e.dead) decayStatus(e.status);
  startPlayerTurn(ctx);
}

function db(ctx: Ctx, defId: string) {
  return ctx.db.cards[defId];
}

export type { BattleSetup };

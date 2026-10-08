import type { CardDef, Effect, EffectScope, StackBonus } from "../types";
import { enemyRef, partyRef, type Ctx } from "./context";
import { addBreak, applyToEnemy, drawCards, GU_LIMIT, HAND_LIMIT, hitEnemy, settleEnemyHp, settleMemberHp } from "./mechanics";
import { aliveEnemies, aliveParty } from "./setup";
import { clearControl } from "./control";

export interface PlayContext {
  card: CardDef;
  /** 出手的隊員 index（null＝沒人能出手，只有 draw 之類的效果） */
  actor: number | null;
  /** 選定目標：敵人 index（target=enemy）或隊員 index（target=ally） */
  target: number | null;
  /** 相生連鎖加成（本張牌） */
  chainBonus: number;
}

export interface EffectResult {
  endTurn: boolean;
}

/** 依序結算一張牌的效果。 */
export function resolveEffects(ctx: Ctx, play: PlayContext): EffectResult {
  const result: EffectResult = { endTurn: false };
  // 同一張牌對同一個敵人只算一次「剋制」破勢
  const brokeThisCard = new Set<number>();
  for (const effect of play.card.effects) {
    if (ctx.s.outcome !== "ongoing") break;
    resolveOne(ctx, play, effect, brokeThisCard, result);
  }
  return result;
}

function partyScope(ctx: Ctx, play: PlayContext, to: EffectScope | undefined): number[] {
  const scope = to ?? "self";
  if (scope === "party") return aliveParty(ctx.s);
  if (scope === "target") return play.target !== null ? [play.target] : [];
  return play.actor !== null ? [play.actor] : [];
}

function strike(ctx: Ctx, play: PlayContext, index: number, base: number, broke: Set<number>): void {
  const attacker = play.actor !== null ? ctx.s.party[play.actor]!.status : null;
  const effective = hitEnemy(ctx, index, {
    base,
    attacker,
    element: play.card.element,
    chainBonus: play.chainBonus,
    sourceIndex: play.actor,
  });
  if (effective === "strong" && !broke.has(index)) {
    broke.add(index);
    addBreak(ctx, index, 1);
  }
}

/** 傷害依流派層數加成（指勁、劍意…） */
/** 特殊 key「qi」＝目前剩下的真氣（酒神：用全身真氣爆發） */
function withStacks(ctx: Ctx, base: number, per: StackBonus | undefined): number {
  if (!per) return base;
  const n = per.key === "qi" ? ctx.s.qi : (ctx.s.stacks?.[per.key] ?? 0);
  return base + n * per.amount;
}

function consumeStacks(ctx: Ctx, per: StackBonus | undefined): void {
  if (per?.consume && per.key === "qi") {
    ctx.s.qi = 0;
    return;
  }
  if (per?.consume && ctx.s.stacks?.[per.key]) {
    ctx.s.stacks[per.key] = 0;
    ctx.events.push({ type: "stack", key: per.key, amount: 0 });
  }
}

const CAPTURE_POTIONS: readonly string[] = ["common", "uncommon"];

function resolveOne(ctx: Ctx, play: PlayContext, effect: Effect, broke: Set<number>, result: EffectResult): void {
  const { s } = ctx;
  switch (effect.kind) {
    case "damage": {
      const amount = withStacks(ctx, effect.amount, effect.per);
      for (let h = 0; h < (effect.hits ?? 1); h++) {
        const t = play.target;
        if (t === null || s.enemies[t]?.dead) break;
        strike(ctx, play, t, amount, broke);
      }
      consumeStacks(ctx, effect.per);
      return;
    }
    case "damage_all": {
      const amount = withStacks(ctx, effect.amount, effect.per);
      for (let h = 0; h < (effect.hits ?? 1); h++) {
        for (const i of aliveEnemies(ctx.db, s, true)) strike(ctx, play, i, amount, broke);
        if (s.outcome !== "ongoing") break;
      }
      consumeStacks(ctx, effect.per);
      return;
    }
    case "stack": {
      const stacks = (s.stacks ??= {});
      stacks[effect.key] = Math.max(0, (stacks[effect.key] ?? 0) + effect.amount);
      ctx.events.push({ type: "stack", key: effect.key, amount: stacks[effect.key]! });
      return;
    }
    case "gain_coins": {
      s.purse = (s.purse ?? 0) + effect.amount;
      s.coinsGained += effect.amount;
      return;
    }
    case "spend_coins": {
      s.purse = Math.max(0, (s.purse ?? 0) - effect.amount);
      s.coinsGained -= effect.amount;
      return;
    }
    case "detonate": {
      const t = play.target;
      const enemy = t !== null ? s.enemies[t] : undefined;
      if (t === null || !enemy || enemy.dead || enemy.status.poison <= 0) return;
      const amount = enemy.status.poison * effect.multiplier;
      enemy.status.poison = 0;
      ctx.events.push({ type: "status", target: enemyRef(t), status: "poison", amount: 0 });
      hitEnemy(ctx, t, { base: amount, attacker: null, sourceIndex: play.actor });
      return;
    }
    case "execute": {
      const t = play.target;
      const enemy = t !== null ? s.enemies[t] : undefined;
      if (t === null || !enemy || enemy.dead) return;
      const def = ctx.db.enemies[enemy.defId]!;
      if (!def.isBoss && !def.isField && enemy.hp * 100 < enemy.maxHp * effect.below) {
        ctx.events.push({ type: "damage", target: enemyRef(t), amount: enemy.hp, blocked: 0, effective: "normal", source: play.actor === null ? null : partyRef(play.actor) });
        enemy.hp = 0;
        settleEnemyHp(ctx, t);
      } else strike(ctx, play, t, effect.fallback, broke);
      return;
    }
    case "capture": {
      const t = play.target;
      const enemy = t !== null ? s.enemies[t] : undefined;
      if (t === null || !enemy || enemy.dead) return;
      const def = ctx.db.enemies[enemy.defId]!;
      if (def.isBoss || def.isField || enemy.hp * 100 > enemy.maxHp * effect.below) return;
      // 收進紫金葫蘆：擊倒，煉成一瓶藥（藥品欄有空格才拿得到）
      const pool = Object.values(ctx.db.potions ?? {}).filter((p) => CAPTURE_POTIONS.includes(p.rarity));
      const slot = s.potions?.indexOf(null) ?? -1;
      const potion = slot >= 0 && pool.length > 0 ? ctx.rng.pick(pool).id : null;
      if (potion !== null) s.potions![slot] = potion;
      ctx.events.push({ type: "capture", target: enemyRef(t), potion });
      enemy.hp = 0;
      settleEnemyHp(ctx, t);
      return;
    }
    case "block": {
      const bonus = play.card.element ? play.chainBonus : 0;
      for (const i of partyScope(ctx, play, effect.to)) {
        const m = s.party[i]!;
        if (m.downed) continue;
        m.block += effect.amount + bonus;
        ctx.events.push({ type: "block", target: partyRef(i), amount: effect.amount + bonus });
      }
      return;
    }
    case "heal": {
      for (const i of partyScope(ctx, play, effect.to)) {
        const m = s.party[i]!;
        if (m.downed) continue;
        const amount = Math.min(effect.amount, m.maxHp - m.hp);
        m.hp += amount;
        ctx.events.push({ type: "heal", target: partyRef(i), amount });
      }
      return;
    }
    case "draw":
      drawCards(ctx, effect.amount);
      return;
    case "gain_qi":
      s.qi += effect.amount;
      return;
    case "apply": {
      const targets = effect.to === "all_enemies" ? aliveEnemies(ctx.db, s) : play.target !== null ? [play.target] : [];
      for (const i of targets) applyToEnemy(ctx, i, effect.status, effect.amount);
      return;
    }
    case "strength": {
      for (const i of partyScope(ctx, play, effect.to)) {
        const m = s.party[i]!;
        m.status.strength += effect.amount;
        ctx.events.push({ type: "status", target: partyRef(i), status: "strength", amount: m.status.strength });
      }
      return;
    }
    case "cleanse": {
      for (const i of partyScope(ctx, play, effect.to)) {
        const st = s.party[i]!.status;
        st.weak = 0;
        st.vulnerable = 0;
        st.poison = 0;
        clearControl(st);
        ctx.events.push({ type: "status", target: partyRef(i), status: "poison", amount: 0 });
      }
      // 手上的狀態牌（纏絲、屍毒）一併移除
      const junk = s.hand.filter((c) => ctx.db.cards[c.defId]?.unplayable);
      if (junk.length) {
        s.hand = s.hand.filter((c) => !junk.includes(c));
        s.exhaust.push(...junk);
      }
      return;
    }
    case "steal": {
      const t = play.target;
      if (t === null) return;
      const enemy = s.enemies[t]!;
      const pool = ctx.db.enemies[enemy.defId]!.stealable ?? [];
      const cardId = pool[enemy.stolen] ?? null;
      if (cardId) {
        enemy.stolen += 1;
        s.loot.push(cardId);
        if (s.hand.length < HAND_LIMIT) s.hand.push({ uid: s.nextUid++, defId: cardId, upgraded: false });
        ctx.events.push({ type: "steal", target: enemyRef(t), card: cardId, coins: 0 });
      } else {
        // 偷不到東西：摸到幾枚銅錢（固定值，不靠運氣）
        s.coinsGained += 5;
        ctx.events.push({ type: "steal", target: enemyRef(t), card: null, coins: 5 });
      }
      return;
    }
    case "counter": {
      if (play.actor === null) return;
      s.party[play.actor]!.counter += effect.amount;
      return;
    }
    case "summon_gu": {
      s.gu = Math.min(GU_LIMIT, s.gu + effect.amount);
      ctx.events.push({ type: "gu", count: s.gu });
      return;
    }
    case "fly_sword": {
      const targetUid = play.target !== null ? s.enemies[play.target]!.uid : null;
      s.flyingSwords.push({ amount: effect.amount, targetUid });
      return;
    }
    case "revive": {
      const t = play.target;
      if (t === null) return;
      const m = s.party[t]!;
      if (m.downed) {
        m.downed = false;
        m.hp = Math.min(m.maxHp, effect.amount);
        ctx.events.push({ type: "revived", target: partyRef(t) });
      } else {
        const amount = Math.min(effect.amount, m.maxHp - m.hp);
        m.hp += amount;
        ctx.events.push({ type: "heal", target: partyRef(t), amount });
      }
      return;
    }
    case "combo_gauge":
      s.comboGauge = Math.min(s.comboMax, s.comboGauge + effect.amount);
      return;
    case "self_damage": {
      const targets = effect.to === "party" ? aliveParty(s) : play.actor !== null ? [play.actor] : [];
      for (const i of targets) {
        const m = s.party[i]!;
        const raw = effect.percent ? Math.ceil((m.maxHp * effect.amount) / 100) : effect.amount;
        const loss = Math.min(raw, m.hp - 1); // 最低留 1，不會因此昏迷
        if (loss <= 0) continue;
        m.hp -= loss;
        ctx.events.push({ type: "damage", target: partyRef(i), amount: loss, blocked: 0, effective: "normal", source: null });
        settleMemberHp(ctx, i);
      }
      return;
    }
    case "end_turn":
      result.endTurn = true;
      return;
    case "add_card": {
      for (let n = 0; n < (effect.count ?? 1); n++) {
        if (s.hand.length >= HAND_LIMIT) break;
        s.hand.push({ uid: s.nextUid++, defId: effect.card, upgraded: false });
      }
      return;
    }
    case "upgrade_hand": {
      for (const c of s.hand) if (ctx.db.cards[c.defId]?.upgrade) c.upgraded = true;
      return;
    }
  }
}

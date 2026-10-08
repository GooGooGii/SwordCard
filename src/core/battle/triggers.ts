import type { ActivePower, CardDef, Trigger, TriggerOn } from "../types";
import { partyRef, type Ctx } from "./context";
import { resolveEffects } from "./effects";
import { aliveEnemies, memberIndex, actorFor } from "./setup";

/**
 * 觸發引擎：心法牌與法寶共用（殺戮尖塔「能力」與「遺物」的觸發寫法）。
 * 觸發只看資料（ActivePower.triggers），新流派的牌不用改程式。
 * 觸發效果裡再觸發（例：擊倒 → 傷害 → 又擊倒）最多連鎖 4 層，避免無限迴圈。
 */
const MAX_DEPTH = 4;
let depth = 0;

export interface TriggerInfo {
  /** play：打出的牌 */
  card?: CardDef;
  /** 觸發來源的敵人（kill／hurt 的攻擊者／poison_tick／counter） */
  enemyIndex?: number;
  /** hurt：受傷的隊員 */
  memberIndex?: number;
}

function matches(trigger: Trigger, on: TriggerOn, info: TriggerInfo): boolean {
  if (trigger.on !== on) return false;
  if (on !== "play") return true;
  const card = info.card;
  if (!card) return false;
  if (trigger.type && card.type !== trigger.type) return false;
  if (trigger.element && card.element !== trigger.element) return false;
  if (trigger.owner && card.owner !== trigger.owner) return false;
  return true;
}

function pickTarget(ctx: Ctx, trigger: Trigger, info: TriggerInfo): number | null {
  const alive = aliveEnemies(ctx.db, ctx.s, true);
  if (alive.length === 0) return null;
  if (trigger.target === "source" && info.enemyIndex !== undefined && !ctx.s.enemies[info.enemyIndex]?.dead) return info.enemyIndex;
  if (trigger.target === "random") return ctx.rng.pick(alive);
  // 預設與 front：最前面的非場地敵人
  return aliveEnemies(ctx.db, ctx.s)[0] ?? alive[0]!;
}

function fire(ctx: Ctx, power: ActivePower, trigger: Trigger, info: TriggerInfo): void {
  const card: CardDef = {
    id: power.id,
    name: power.name,
    owner: power.owner,
    type: "skill",
    target: "enemy",
    rarity: "special",
    cost: 0,
    effects: trigger.effects,
    motion: "cast",
    canon: "",
  };
  const ownerIndex = power.owner ? memberIndex(ctx.s, power.owner) : -1;
  const actor = ownerIndex >= 0 && !ctx.s.party[ownerIndex]!.downed ? ownerIndex : actorFor(ctx.s, { ...card, owner: null });
  // 心法的主人昏迷了就不生效（法寶照常）
  if (power.source === "card" && power.owner && (ownerIndex < 0 || ctx.s.party[ownerIndex]!.downed)) return;
  const target = pickTarget(ctx, trigger, info);
  ctx.events.push({ type: "power", id: power.id, name: power.name, actor: actor === null ? null : partyRef(actor) });
  resolveEffects(ctx, { card, actor, target, chainBonus: 0 });
}

export function fireTriggers(ctx: Ctx, on: TriggerOn, info: TriggerInfo = {}): void {
  const powers = ctx.s.powers;
  if (!powers || powers.length === 0 || ctx.s.outcome !== "ongoing") return;
  if (depth >= MAX_DEPTH) return;
  depth++;
  try {
    // 複製一份清單：觸發中新增的心法不在這一輪生效
    for (const power of [...powers]) {
      power.triggers.forEach((trigger, k) => {
        if (ctx.s.outcome !== "ongoing" || !matches(trigger, on, info)) return;
        power.counters[k] = (power.counters[k] ?? 0) + 1;
        if (trigger.every && power.counters[k]! % trigger.every !== 0) return;
        fire(ctx, power, trigger, info);
      });
    }
  } finally {
    depth--;
  }
}

export function addPower(ctx: Ctx, power: Omit<ActivePower, "counters">): void {
  (ctx.s.powers ??= []).push({ ...power, counters: power.triggers.map(() => 0) });
}

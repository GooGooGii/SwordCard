import type { MoveDef, MoveTargeting } from "../types";
import { enemyRef, partyRef, type Ctx } from "./context";
import { ctl, grantSteady } from "./control";
import { applyToMember, fieldAlive, hitEnemy, hitMember } from "./mechanics";
import { aliveEnemies, aliveParty, MAX_ENEMIES, newEnemy } from "./setup";

export function moveDef(ctx: Ctx, enemyIndex: number, moveId: string): MoveDef {
  const def = ctx.db.enemies[ctx.s.enemies[enemyIndex]!.defId]!;
  const move = def.moves.find((m) => m.id === moveId);
  if (!move) throw new Error(`${def.id}: unknown move ${moveId}`);
  return move;
}

/** 目前可用的招式：進入第二階段後只用 phase2 列出的招式 */
function movePool(ctx: Ctx, enemyIndex: number): MoveDef[] {
  const enemy = ctx.s.enemies[enemyIndex]!;
  const def = ctx.db.enemies[enemy.defId]!;
  const phase2 = def.passives?.find((p) => p.kind === "phase2");
  if (enemy.phase2 && phase2 && phase2.kind === "phase2") {
    return phase2.moves.map((id) => def.moves.find((m) => m.id === id)!).filter(Boolean);
  }
  const phase2Ids = new Set(phase2 && phase2.kind === "phase2" ? phase2.moves : []);
  return def.moves.filter((m) => !phase2Ids.has(m.id));
}

// ── 敵人 AI（2026-10-08 強化）────────────────────────────────────────────────
// 1. 看情況：滿血不補血、場上滿了不召喚、氣勢已經很高不再蓄勢
// 2. 不連出同一招三次（殺戮尖塔的慣例；只剩一招時例外）
// 3. 三招以上、沒有「蓄力→大招」腳本的一般敵人改成加權隨機（意圖仍提前攤開）
// 4. 血量低於三成的有補血招就優先補
// 5. 單體招式依 targeting 挑人；沒寫的：有隊員血量低於三成時一半機率集火他

const HEAL_BELOW = 0.6;
const URGENT_HEAL_BELOW = 0.3;
const MAX_STRENGTH = 8;
const FOCUS_BELOW = 0.3;
const CASTERS = new Set(["zhao_linger", "anu", "wuhou"]);

function usable(ctx: Ctx, enemyIndex: number, move: MoveDef): boolean {
  const enemy = ctx.s.enemies[enemyIndex]!;
  switch (move.intent) {
    case "heal":
      return enemy.hp <= enemy.maxHp * HEAL_BELOW;
    case "summon":
      return aliveEnemies(ctx.db, ctx.s, true).length < MAX_ENEMIES;
    case "buff":
      return enemy.status.strength < MAX_STRENGTH;
    default:
      return true;
  }
}

function repeatedTwice(history: string[] | undefined, move: MoveDef): boolean {
  return !!history && history.length >= 2 && history[0] === move.id && history[1] === move.id;
}

export function pickMove(ctx: Ctx, enemyIndex: number, pool: MoveDef[]): MoveDef {
  const enemy = ctx.s.enemies[enemyIndex]!;
  const def = ctx.db.enemies[enemy.defId]!;
  // 「能用」優先於「不重複」：滿血的補血招不會因為要避免連招而被選上
  const fit = pool.filter((m) => usable(ctx, enemyIndex, m));
  const fresh = fit.filter((m) => !repeatedTwice(enemy.history, m));
  const candidates = fresh.length > 0 ? fresh : fit.length > 0 ? fit : pool;

  const heal = candidates.find((m) => m.intent === "heal");
  if (heal && enemy.hp <= enemy.maxHp * URGENT_HEAL_BELOW) return heal;

  const scripted = pool.some((m) => m.intent === "charge");
  const randomized = def.pattern === "weighted" || (!def.isBoss && !scripted && pool.length >= 3 && !enemy.phase2);
  if (randomized) {
    const weights = def.weights;
    return ctx.rng.weighted(candidates.map((m) => ({ value: m, weight: weights?.[def.moves.indexOf(m)] ?? 1 })));
  }
  // 依序輪流；輪到不能用的就往下找
  for (let k = 0; k < pool.length; k++) {
    const move = pool[enemy.moveCursor % pool.length]!;
    enemy.moveCursor += 1;
    if (candidates.includes(move)) return move;
  }
  return pool[0]!;
}

export function pickTarget(ctx: Ctx, targeting: MoveTargeting | undefined): number | null {
  const { s } = ctx;
  const alive = aliveParty(s);
  if (alive.length === 0) return null;
  const ratio = (i: number) => s.party[i]!.hp / Math.max(1, s.party[i]!.maxHp);
  const weakest = () => alive.reduce((best, i) => (ratio(i) < ratio(best) ? i : best), alive[0]!);
  switch (targeting) {
    case "weakest":
      return weakest();
    case "strongest":
      return alive.reduce((best, i) => (s.party[i]!.hp > s.party[best]!.hp ? i : best), alive[0]!);
    case "front":
      return alive[0]!;
    case "caster": {
      const casters = alive.filter((i) => CASTERS.has(s.party[i]!.charId));
      return casters.length > 0 ? ctx.rng.pick(casters) : ctx.rng.pick(alive);
    }
    case "random":
      return ctx.rng.pick(alive);
    default: {
      const w = weakest();
      if (alive.length > 1 && ratio(w) < FOCUS_BELOW && ctx.rng.next() < 0.5) return w;
      return ctx.rng.pick(alive);
    }
  }
}

/** 為每個活著的敵人決定下一個意圖（玩家回合開始時攤開）。 */
export function chooseIntents(ctx: Ctx): void {
  const { s } = ctx;
  for (const i of aliveEnemies(ctx.db, s)) {
    const enemy = s.enemies[i]!;
    const def = ctx.db.enemies[enemy.defId]!;
    const phase2 = def.passives?.find((p) => p.kind === "phase2");
    if (phase2 && !enemy.phase2 && enemy.hp * 2 < enemy.maxHp) {
      enemy.phase2 = true;
      enemy.moveCursor = 0;
    }
    const pool = movePool(ctx, i);
    if (pool.length === 0) continue;
    const move = pickMove(ctx, i, pool);
    enemy.history = [move.id, ...(enemy.history ?? [])].slice(0, 2);
    const needsTarget = move.intent === "attack" || (move.intent === "debuff" && move.apply?.to === "target");
    enemy.intent = {
      moveId: move.id,
      target: needsTarget ? pickTarget(ctx, move.targeting) : null,
      cancelled: false,
      halved: false,
    };
  }
}

/** 意圖指定的隊員昏迷了：改打最左邊還清醒的隊友（REDESIGN §4.1） */
function retarget(ctx: Ctx, target: number | null): number | null {
  const alive = aliveParty(ctx.s);
  if (alive.length === 0) return null;
  if (target !== null && !ctx.s.party[target]!.downed) return target;
  return alive[0]!;
}

/** 封印中只能攻擊或防禦 */
const SEALABLE = new Set(["buff", "debuff", "summon", "heal"]);

export function executeIntent(ctx: Ctx, enemyIndex: number): void {
  const { s } = ctx;
  const enemy = s.enemies[enemyIndex]!;
  const intent = enemy.intent;
  if (!intent || enemy.dead) return;
  enemy.intent = null;
  if (intent.cancelled) return;
  const move = moveDef(ctx, enemyIndex, intent.moveId);

  // 控制狀態：定身、昏睡跳過這次行動（並消耗一層）；封印擋下法術類招式
  for (const status of ["stun", "sleep"] as const) {
    if (ctl(enemy.status, status) > 0) {
      enemy.status[status]! -= 1;
      grantSteady(enemy.status);
      ctx.events.push({ type: "status", target: enemyRef(enemyIndex), status, amount: enemy.status[status]! });
      return;
    }
  }
  if (ctl(enemy.status, "seal") > 0 && SEALABLE.has(move.intent)) {
    ctx.events.push({ type: "status", target: enemyRef(enemyIndex), status: "seal", amount: ctl(enemy.status, "seal") });
    return;
  }

  const half = intent.halved;
  const scale = (n: number) => (half ? Math.floor(n / 2) : n);
  const target = retarget(ctx, intent.target);
  ctx.events.push({
    type: "enemy_move",
    actor: enemyRef(enemyIndex),
    moveId: move.id,
    target: move.intent === "attack" && target !== null ? partyRef(target) : null,
  });
  switch (move.intent) {
    case "attack": {
      for (let h = 0; h < (move.hits ?? 1); h++) {
        if (enemy.dead) break;
        // 混亂：每一擊有一半機率打到自己人
        if (ctl(enemy.status, "confuse") > 0 && ctx.rng.next() < 0.5) {
          const allies = aliveEnemies(ctx.db, s).filter((j) => j !== enemyIndex);
          const victim = allies.length > 0 ? ctx.rng.pick(allies) : enemyIndex;
          hitEnemy(ctx, victim, { base: scale(move.damage ?? 0), attacker: enemy.status, sourceIndex: null });
          if (s.outcome !== "ongoing") return;
          continue;
        }
        const t = retarget(ctx, target);
        if (t === null) break;
        hitMember(ctx, t, move.damage ?? 0, enemyIndex, half);
        if (s.outcome !== "ongoing") return;
      }
      break;
    }
    case "attack_all": {
      for (let h = 0; h < (move.hits ?? 1); h++) {
        for (const t of aliveParty(s)) {
          if (enemy.dead) break;
          hitMember(ctx, t, move.damage ?? 0, enemyIndex, half);
          if (s.outcome !== "ongoing") return;
        }
      }
      break;
    }
    case "block":
      enemy.block += scale(move.block ?? 0);
      ctx.events.push({ type: "block", target: enemyRef(enemyIndex), amount: scale(move.block ?? 0) });
      break;
    case "buff":
      enemy.status.strength += scale(move.strength ?? 0);
      ctx.events.push({ type: "status", target: enemyRef(enemyIndex), status: "strength", amount: enemy.status.strength });
      break;
    case "debuff": {
      if (!move.apply) break;
      const targets = move.apply.to === "party" ? aliveParty(s) : target !== null ? [target] : [];
      const amount = Math.max(1, scale(move.apply.amount));
      for (const t of targets) applyToMember(ctx, t, move.apply.status, amount);
      if (move.damage) {
        for (const t of targets) hitMember(ctx, t, move.damage, enemyIndex, half);
      }
      break;
    }
    case "heal": {
      const amount = Math.min(scale(move.heal ?? 0), enemy.maxHp - enemy.hp);
      enemy.hp += amount;
      ctx.events.push({ type: "heal", target: enemyRef(enemyIndex), amount });
      break;
    }
    case "summon": {
      if (!move.summon) break;
      if (aliveEnemies(ctx.db, s, true).length >= MAX_ENEMIES) break;
      // 重用已死的位置（畫面站位不跳動）；沒有就加在後面
      const slot = s.enemies.findIndex((e) => e.dead);
      const fresh = newEnemy(ctx.db, move.summon, s.nextUid++, s.enemyHpScale);
      const index = slot >= 0 ? slot : s.enemies.length;
      s.enemies[index] = fresh;
      ctx.events.push({ type: "summon", target: enemyRef(index) });
      break;
    }
    case "charge":
      break;
  }
  // 把狀態牌塞進我方棄牌堆（纏絲、屍毒…）
  if (move.addCard && s.outcome === "ongoing") {
    for (let n = 0; n < move.addCard.count; n++) s.discard.push({ uid: s.nextUid++, defId: move.addCard.card, upgraded: false });
  }
}

/** 回合開始的被動：再生（血池） */
export function applyPassives(ctx: Ctx): void {
  const { s } = ctx;
  s.enemies.forEach((enemy, i) => {
    if (enemy.dead) return;
    const def = ctx.db.enemies[enemy.defId]!;
    for (const p of def.passives ?? []) {
      if (p.kind !== "regen") continue;
      if (p.fieldId && !fieldAlive(ctx, p.fieldId)) continue;
      const amount = Math.min(p.amount, enemy.maxHp - enemy.hp);
      if (amount <= 0) continue;
      enemy.hp += amount;
      ctx.events.push({ type: "heal", target: enemyRef(i), amount });
    }
  });
}

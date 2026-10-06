import type { MoveDef } from "../types";
import { enemyRef, partyRef, type Ctx } from "./context";
import { fieldAlive, hitMember } from "./mechanics";
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
    let move: MoveDef;
    if (def.pattern === "weighted" && !enemy.phase2) {
      const weights = def.weights ?? pool.map(() => 1);
      move = ctx.rng.weighted(pool.map((m, k) => ({ value: m, weight: weights[k] ?? 1 })));
    } else {
      move = pool[enemy.moveCursor % pool.length]!;
      enemy.moveCursor += 1;
    }
    const needsTarget = move.intent === "attack" || (move.intent === "debuff" && move.apply?.to === "target");
    const alive = aliveParty(s);
    enemy.intent = {
      moveId: move.id,
      target: needsTarget && alive.length > 0 ? ctx.rng.pick(alive) : null,
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

export function executeIntent(ctx: Ctx, enemyIndex: number): void {
  const { s } = ctx;
  const enemy = s.enemies[enemyIndex]!;
  const intent = enemy.intent;
  if (!intent || enemy.dead) return;
  enemy.intent = null;
  if (intent.cancelled) return;
  const move = moveDef(ctx, enemyIndex, intent.moveId);
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
        const t = retarget(ctx, target);
        if (t === null || enemy.dead) break;
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
      for (const t of targets) {
        const m = s.party[t]!;
        if (move.apply.status === "break") continue; // 破勢只用在敵人身上
        m.status[move.apply.status] += amount;
        ctx.events.push({ type: "status", target: partyRef(t), status: move.apply.status, amount: m.status[move.apply.status] });
      }
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

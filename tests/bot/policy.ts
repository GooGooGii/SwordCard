import { canPlay, computeDamage, effectiveCard, endTurn, playCard } from "../../src/core/battle";
import type { BattleState, ContentDb, EnemyState } from "../../src/core/types";

/**
 * 自動通關 bot 的出牌策略（BALANCE-001）：一步前瞻的貪婪法。
 * 每次把手上每張能出的牌、每個合法目標都試打一次，用局面分數挑最好的；
 * 沒有比「不出」更好的牌就結束回合。不是最強打法，是「普通玩家」的基準。
 */

/** 敵人這回合的意圖，預估會打掉我方多少 HP（扣掉護體） */
function incomingDamage(db: ContentDb, s: BattleState): number {
  const blocks = s.party.map((m) => m.block);
  let total = 0;
  for (const e of s.enemies) {
    if (e.dead || !e.intent || e.intent.cancelled) continue;
    const move = db.enemies[e.defId]!.moves.find((m) => m.id === e.intent!.moveId);
    if (!move || move.damage === undefined) continue;
    const hits = move.hits ?? 1;
    const targets =
      move.intent === "attack_all" || (move.intent === "debuff" && move.apply?.to === "party")
        ? s.party.map((_, i) => i).filter((i) => !s.party[i]!.downed)
        : e.intent.target !== null
          ? [e.intent.target]
          : [];
    for (const t of targets) {
      const m = s.party[t]!;
      const per = computeDamage({ base: move.damage, attacker: e.status, defender: m.status, halved: e.intent.halved }).amount;
      for (let h = 0; h < hits; h++) {
        const absorbed = Math.min(blocks[t]!, per);
        blocks[t]! -= absorbed;
        total += per - absorbed;
      }
    }
  }
  return total;
}

/** 接續登場的敵人（蛇妖男→狐狸精、七神龍）總 HP：算進去，bot 才不會為了「不讓下一隻出來」而不敢收尾 */
function successorHp(db: ContentDb, id: string): number {
  let total = 0;
  for (let next = db.enemies[id]?.successor; next; next = db.enemies[next]?.successor) total += db.enemies[next]!.maxHp;
  return total;
}

function enemyValue(db: ContentDb, e: EnemyState): number {
  if (e.dead) return 0;
  const def = db.enemies[e.defId]!;
  // 場地（血池、水域）讓 Boss 不死或再生：打破它很值得
  const weight = def.isField ? 1.4 : 1;
  return (e.hp + e.block * 0.5 + successorHp(db, e.defId)) * weight + (def.isBoss ? 0 : 6);
}

export function score(db: ContentDb, s: BattleState): number {
  if (s.outcome === "won" || s.outcome === "survived") return 1e6;
  if (s.outcome === "lost") return -1e6;
  const enemyHp = s.enemies.reduce((sum, e) => sum + enemyValue(db, e), 0);
  const partyHp = s.party.reduce((sum, m) => sum + (m.downed ? -40 : m.hp), 0);
  const incoming = incomingDamage(db, s);
  const debuffs = s.enemies.reduce((sum, e) => (e.dead ? sum : sum + e.status.weak * 2 + e.status.vulnerable * 2 + e.status.poison * 1.5 + e.breakStacks * 3), 0);
  const buffs = s.party.reduce((sum, m) => sum + m.status.strength * 4 + m.counter, 0);
  return -enemyHp * 1.2 + partyHp - incoming * 1.1 + debuffs + buffs + s.comboGauge * 2 + s.gu * 3 + s.flyingSwords.reduce((n, f) => n + f.amount, 0) * 0.8 + s.hand.length * 0.5;
}

function targetsFor(db: ContentDb, s: BattleState, uid: number): (number | null)[] {
  const card = s.hand.find((c) => c.uid === uid)!;
  const def = effectiveCard(db, s, card);
  if (def.target === "enemy") return s.enemies.map((e, i) => (e.dead ? -1 : i)).filter((i) => i >= 0);
  if (def.target === "ally") return s.party.map((_, i) => i);
  return [null];
}

/** 打完一整個回合（出到沒有好牌為止），回傳回合結束後的狀態 */
export function playTurn(db: ContentDb, start: BattleState): { state: BattleState; played: number } {
  let s = start;
  let played = 0;
  for (let guard = 0; guard < 20 && s.outcome === "ongoing"; guard++) {
    const base = score(db, s);
    let best: { state: BattleState; value: number } | null = null;
    for (const card of s.hand) {
      for (const target of targetsFor(db, s, card.uid)) {
        if (canPlay(db, s, card.uid, target)) continue;
        const next = playCard(db, s, card.uid, target).state;
        const value = score(db, next);
        if (!best || value > best.value) best = { state: next, value };
      }
    }
    // 0 費牌或有好處就打；完全沒好處（例如手上只剩不划算的牌）就停
    if (!best || best.value <= base - 0.5) break;
    s = best.state;
    played++;
  }
  if (s.outcome !== "ongoing") return { state: s, played };
  return { state: endTurn(db, s).state, played };
}

/** 打完一整場戰鬥 */
export function playBattle(db: ContentDb, start: BattleState, maxTurns = 40): { state: BattleState; turns: number; played: number } {
  let s = start;
  let turns = 0;
  let played = 0;
  while (s.outcome === "ongoing" && turns < maxTurns) {
    const r = playTurn(db, s);
    s = r.state;
    played += r.played;
    turns++;
  }
  return { state: s, turns, played };
}

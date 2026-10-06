import { cardDef, THOUGHT_CARD } from "../cards";
import { Rng } from "../rng";
import type { BattleState, CardDef, CardInstance, CharId, ContentDb, EnemyState, PartyMemberState, StatusBag } from "../types";

export const QI_PER_TURN = 3;
export const HAND_SIZE = 5;
export const COMBO_MAX = 4;
export const MAX_ENEMIES = 3;
export const BREAK_THRESHOLD = { normal: 2, boss: 3 } as const;

export interface BattleSetup {
  seed: number;
  party: { charId: CharId; hp: number; maxHp: number }[];
  deck: CardInstance[];
  enemies: string[];
  /** 求生戰：撐過幾回合就算勝利 */
  survive?: number;
  enemyHpScale?: number;
}

export function emptyStatus(): StatusBag {
  return { strength: 0, weak: 0, vulnerable: 0, poison: 0 };
}

export function newEnemy(db: ContentDb, defId: string, uid: number, hpScale: number): EnemyState {
  const def = db.enemies[defId];
  if (!def) throw new Error(`unknown enemy: ${defId}`);
  const maxHp = Math.max(1, Math.round(def.maxHp * (def.isField ? 1 : hpScale)));
  return {
    uid,
    defId,
    hp: maxHp,
    maxHp,
    block: 0,
    status: emptyStatus(),
    breakStacks: 0,
    breakThreshold: def.isBoss ? BREAK_THRESHOLD.boss : BREAK_THRESHOLD.normal,
    breakTriggeredThisTurn: false,
    intent: null,
    moveCursor: 0,
    phase2: false,
    stolen: 0,
    dead: false,
  };
}

/** 建立戰鬥（尚未開始第一回合；呼叫 startPlayerTurn 開始）。 */
export function createBattle(db: ContentDb, setup: BattleSetup): BattleState {
  const rng = new Rng(setup.seed);
  const party: PartyMemberState[] = setup.party.map((p) => ({
    charId: p.charId,
    hp: p.hp,
    maxHp: p.maxHp,
    block: 0,
    status: emptyStatus(),
    counter: 0,
    downed: p.hp <= 0,
  }));
  let nextUid = Math.max(0, ...setup.deck.map((c) => c.uid)) + 1;
  const hpScale = setup.enemyHpScale ?? 1;
  const enemies = setup.enemies.map((id) => newEnemy(db, id, nextUid++, hpScale));
  const draw = rng.shuffle(setup.deck.map((c) => ({ ...c })));
  return {
    rng: rng.state,
    turn: 0,
    qi: 0,
    maxQi: QI_PER_TURN,
    handSize: HAND_SIZE,
    draw,
    hand: [],
    discard: [],
    exhaust: [],
    nextUid,
    party,
    enemies,
    chain: { last: null, count: 0 },
    comboGauge: 0,
    comboMax: COMBO_MAX,
    lastOwner: null,
    gu: 0,
    flyingSwords: [],
    loot: [],
    coinsGained: 0,
    survive: setup.survive ?? null,
    outcome: "ongoing",
    enemyHpScale: hpScale,
  };
}

/** 實際打出時的卡牌定義：主人昏迷就變成「心念」。 */
export function effectiveCard(db: ContentDb, state: BattleState, card: CardInstance): CardDef {
  const def = cardDef(db, card);
  if (def.owner && isDowned(state, def.owner)) return THOUGHT_CARD;
  return def;
}

export function isDowned(state: BattleState, charId: CharId): boolean {
  const member = state.party.find((m) => m.charId === charId);
  return !member || member.downed;
}

export function memberIndex(state: BattleState, charId: CharId): number {
  return state.party.findIndex((m) => m.charId === charId);
}

export function aliveParty(state: BattleState): number[] {
  return state.party.flatMap((m, i) => (m.downed ? [] : [i]));
}

/** 活著、而且不是場地的敵人 */
export function aliveEnemies(db: ContentDb, state: BattleState, includeFields = false): number[] {
  return state.enemies.flatMap((e, i) => (e.dead || (!includeFields && db.enemies[e.defId]?.isField) ? [] : [i]));
}

/** 無主牌由當下 HP 最高的清醒隊員出手 */
export function actorFor(state: BattleState, def: CardDef): number | null {
  if (def.owner) {
    const i = memberIndex(state, def.owner);
    if (i >= 0 && !state.party[i]!.downed) return i;
  }
  const alive = aliveParty(state);
  if (alive.length === 0) return null;
  return alive.reduce((best, i) => (state.party[i]!.hp > state.party[best]!.hp ? i : best), alive[0]!);
}

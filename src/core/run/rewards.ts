import { Rng } from "../rng";
import type { CharId, Rarity } from "../types";
import { chapterOf, member, newCard, nodeSeed, type GameDb } from "./db";
import type { Reward, RunState } from "./types";

/** 直接給的獎勵（劇情、支線）：銅錢、牌、法寶、升級、最大 HP。選牌另外處理。 */
export function grantReward(db: GameDb, run: RunState, reward: Reward, salt: string): void {
  if (reward.coins) run.coins += reward.coins;
  for (const id of reward.cards ?? []) addCardToRun(db, run, id);
  if (reward.relic && !run.relics.includes(reward.relic)) run.relics.push(reward.relic);
  if (reward.maxHp) {
    for (const id of run.party) {
      const m = member(run, id);
      m.maxHp += reward.maxHp;
      m.hp += reward.maxHp;
    }
  }
  if (reward.upgrades) upgradeRandom(db, run, reward.upgrades, salt);
}

/** 牌加進主人的牌組；無主牌放進共用區。主人不在隊上（或不存在）也放共用區。 */
export function addCardToRun(db: GameDb, run: RunState, defId: string, upgraded = false): void {
  const def = db.cards[defId];
  if (!def) throw new Error(`no card ${defId}`);
  const owner = def.owner ? run.members[def.owner] : undefined;
  if (owner && !owner.gone) owner.deck.push(newCard(run, defId, upgraded));
  else run.shared.push(newCard(run, defId, upgraded));
}

export function upgradeRandom(db: GameDb, run: RunState, count: number, salt: string): void {
  const rng = new Rng(nodeSeed(run, `upgrade:${salt}`, run.nextUid));
  const candidates = run.party.flatMap((id) => member(run, id).deck).filter((c) => !c.upgraded && db.cards[c.defId]?.upgrade);
  rng.shuffle(candidates);
  for (const c of candidates.slice(0, count)) c.upgraded = true;
}

const REWARD_RARITIES: Rarity[] = ["common", "uncommon", "rare"];

/**
 * 流派加權（殺戮尖塔的「越拿越容易成形」）：牌組裡同流派的牌越多，這個流派的牌越容易出現；
 * 每張 +0.35，最多三倍，沒有流派的牌固定 1。
 */
export function archetypeWeight(db: GameDb, run: RunState, archetype: string | undefined): number {
  if (!archetype) return 1;
  const owned = run.party.flatMap((id) => member(run, id).deck).filter((c) => db.cards[c.defId]?.archetype === archetype).length;
  return Math.min(3, 1 + owned * 0.35);
}

/** 戰後選牌：每組 3 張不重複，主人輪流取自在場隊員，稀有度依本章權重。 */
export function rollCardChoices(db: GameDb, run: RunState, nodeId: string, groups: number): string[][] {
  const chapter = chapterOf(db, run);
  const rng = new Rng(nodeSeed(run, `cards:${nodeId}`, 0));
  const owners: CharId[] = run.party.length ? [...run.party] : ["li_xiaoyao"];
  const out: string[][] = [];
  for (let g = 0; g < groups; g++) {
    const picked: string[] = [];
    let guard = 0;
    while (picked.length < 3 && guard++ < 200) {
      const owner = owners[(g * 3 + picked.length + guard) % owners.length]!;
      const rarity = rng.weighted(REWARD_RARITIES.map((r) => ({ value: r, weight: chapter.rarity[r as "common" | "uncommon" | "rare"] })));
      const pool = Object.values(db.cards).filter((c) => c.owner === owner && c.rarity === rarity && !picked.includes(c.id));
      if (pool.length === 0) continue;
      picked.push(rng.weighted(pool.map((c) => ({ value: c.id, weight: archetypeWeight(db, run, c.archetype) }))));
    }
    out.push(picked);
  }
  return out;
}

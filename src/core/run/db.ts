import type { CardInstance, CharId, ContentDb } from "../types";
import type { ChapterDef, MemberRecord, NodeDef, RelicDef, RunState, StoryDef } from "./types";

export interface GameDb extends ContentDb {
  chapters: ChapterDef[];
  stories: Record<string, StoryDef>;
  relics: Record<string, RelicDef>;
  /** 第一次入隊時帶的牌（依入隊章節預先組好，REDESIGN §2.2） */
  starters: Record<CharId, string[]>;
}

export const PARTY_LIMIT = 3;
/** 每位角色牌數下限：客棧刪牌刪不到這以下（REDESIGN §2.1） */
export const MIN_DECK_PER_MEMBER = 8;
/** 昏迷的人戰後回到最大 HP 的 25% */
export const DOWNED_RECOVERY = 0.25;
/** 戰敗重來時，全隊 HP 至少回到 60% */
export const RETRY_FLOOR = 0.6;
/** 劇情難度：敵人 HP −40% */
export const STORY_HP_SCALE = 0.6;
/** 每進一章，全隊最大 HP +4 */
export const CHAPTER_MAX_HP = 4;

export function chapterOf(db: GameDb, run: RunState): ChapterDef {
  const chapter = db.chapters[run.chapter];
  if (!chapter) throw new Error(`no chapter ${run.chapter}`);
  return chapter;
}

export function nodeOf(db: GameDb, run: RunState, nodeId: string): NodeDef {
  const node = chapterOf(db, run).nodes.find((n) => n.id === nodeId);
  if (!node) throw new Error(`no node ${nodeId} in ${chapterOf(db, run).id}`);
  return node;
}

export function member(run: RunState, charId: CharId): MemberRecord {
  const m = run.members[charId];
  if (!m) throw new Error(`no member ${charId}`);
  return m;
}

/** 戰鬥用的整副牌：在場隊員各自的牌＋無主牌 */
export function battleDeck(run: RunState): CardInstance[] {
  return [...run.party.flatMap((id) => member(run, id).deck), ...run.shared];
}

export function newCard(run: RunState, defId: string, upgraded = false): CardInstance {
  return { uid: run.nextUid++, defId, upgraded };
}

/** 一個節點、一次嘗試的固定種子 */
export function nodeSeed(run: RunState, nodeId: string, salt: number): number {
  let h = run.seed ^ 0x9e3779b9;
  const text = `${run.chapter}:${nodeId}:${salt}`;
  for (let i = 0; i < text.length; i++) h = Math.imul(h ^ text.charCodeAt(i), 16777619);
  return h | 0;
}

export function relicsOf(db: GameDb, run: RunState): RelicDef[] {
  return run.relics.map((id) => db.relics[id]).filter((r): r is RelicDef => !!r);
}

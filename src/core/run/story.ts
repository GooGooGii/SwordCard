import type { CharId } from "../types";
import { CHAPTER_MAX_HP, member, newCard, PARTY_LIMIT, type GameDb } from "./db";
import { grantReward } from "./rewards";
import type { RunState, StoryStep } from "./types";

/**
 * 劇本：畫面只負責播放並記下玩家的選擇；播完後由 applyStory 依同一組選擇
 * 重新走一次劇本、套用指令（入隊、離隊、獎勵…）。中途離開不會重複發獎。
 */

/**
 * 依選擇與旗標展開成實際會播的步驟（選項的 then 接在選擇之後）。
 * `when` 分支本身不輸出，只輸出走到的那一邊。
 */
export function flattenStory(steps: StoryStep[], choices: number[], flags: Record<string, boolean> = {}): StoryStep[] {
  const out: StoryStep[] = [];
  const local = { ...flags };
  let cursor = 0;
  const walk = (list: StoryStep[]) => {
    for (const step of list) {
      if ("when" in step) {
        walk(local[step.when] ? step.then : (step.otherwise ?? []));
        continue;
      }
      out.push(step);
      if ("flag" in step) local[step.flag] = step.value ?? true;
      if ("choice" in step) {
        const pick = choices[cursor++] ?? 0;
        walk(step.choice[pick]?.then ?? []);
      }
    }
  };
  walk(steps);
  return out;
}

export function joinMember(db: GameDb, run: RunState, charId: CharId): void {
  const existing = run.members[charId];
  if (existing?.gone) return;
  if (!existing) {
    // 後期才入隊的人，最大 HP 比照已經走過的章數（每章 +4）
    const maxHp = db.characters[charId].maxHp + CHAPTER_MAX_HP * run.chapter;
    run.members[charId] = {
      hp: maxHp,
      maxHp,
      deck: (db.starters[charId] ?? []).map((id) => newCard(run, id)),
      joined: true,
    };
  } else {
    existing.joined = true;
  }
  if (!run.party.includes(charId) && run.party.length < PARTY_LIMIT) run.party.push(charId);
}

export function leaveMember(run: RunState, charId: CharId, permanent: boolean): void {
  run.party = run.party.filter((id) => id !== charId);
  const m = run.members[charId];
  if (!m) return;
  m.joined = false;
  if (permanent) m.gone = true;
}

export function applyStory(db: GameDb, run: RunState, storyId: string, choices: number[]): void {
  const story = db.stories[storyId];
  if (!story) throw new Error(`no story ${storyId}`);
  for (const step of flattenStory(story.steps, choices, run.flags)) {
    if ("join" in step) joinMember(db, run, step.join);
    else if ("leave" in step) leaveMember(run, step.leave, step.permanent ?? false);
    else if ("reward" in step) grantReward(db, run, step.reward, `${storyId}:${choices.join(",")}`);
    else if ("bond" in step) run.bonds[step.bond] = (run.bonds[step.bond] ?? 0) + step.amount;
    else if ("flag" in step) run.flags[step.flag] = step.value ?? true;
    else if ("heal" in step) for (const id of run.party) member(run, id).hp = member(run, id).maxHp;
  }
}

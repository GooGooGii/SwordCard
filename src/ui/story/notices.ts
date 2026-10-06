import type { StoryStep } from "../../core/run";
import { CHARACTERS } from "../../content/characters";
import { game } from "../../game/store";

/** 劇本裡畫面不會停的指令（入隊、獎勵、情誼…）轉成提示文字，讓玩家知道發生了什麼 */
export function noticesOf(steps: StoryStep[]): string[] {
  const out: string[] = [];
  const name = (id: string) => (CHARACTERS as Record<string, { name: string }>)[id]?.name ?? id;
  for (const s of steps) {
    if ("join" in s) out.push(`${name(s.join)} 加入了隊伍`);
    else if ("leave" in s) out.push(s.permanent ? `${name(s.leave)} 永遠離開了隊伍` : `${name(s.leave)} 離開了隊伍`);
    else if ("bond" in s) out.push(`與${name(s.bond)}的情誼 +${s.amount}`);
    else if ("heal" in s) out.push("全隊恢復了元氣");
    else if ("reward" in s) {
      const r = s.reward;
      if (r.coins) out.push(`銅錢 +${r.coins}`);
      for (const id of r.cards ?? []) out.push(`獲得：${game.db.cards[id]?.name ?? id}`);
      if (r.relic) out.push(`獲得法寶：${game.db.relics[r.relic]?.name ?? r.relic}`);
      if (r.maxHp) out.push(`全隊最大生命 +${r.maxHp}`);
      if (r.upgrades) out.push(`${r.upgrades} 張牌升級了`);
    }
  }
  return out;
}

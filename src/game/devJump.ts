import {
  availableNodes,
  addCardToRun,
  beginChapter,
  completeStory,
  concludeBattle,
  enterNode,
  leaveInn,
  newRun,
  retryBattle,
  takeReward,
  updateBattle,
  type GameDb,
  type RunState,
} from "../core/run";
import { beginBattle } from "../core/run/run";

/**
 * 開發用：網址 ?dev=<章>（例如 ?dev=6）直接跳到某一章的開頭；?dev=3:c3_bloodpool 跳到該節點（只在 npm run dev 有效）。
 * 用自動通關 bot 以正式規則一路打過去，所以牌組、HP、隊伍都是真的。
 */
export async function devJump(db: GameDb, chapter: number, node?: string, visualQa = false): Promise<RunState> {
  const { playBattle } = await import("../../tests/bot/policy");
  let run = newRun(db, 20261005, "standard");
  for (let step = 0; step < 5000; step++) {
    const p = run.pending;
    if (run.chapter >= chapter && !node) break;
    // 指定節點：走到它可以進入時就停在那裡（進入後交給畫面）
    if (run.chapter === chapter && node && p.kind === "map" && availableNodes(db, run).some((n) => n.id === node)) {
      if (!visualQa) return enterNode(db, run, node);
      // DEV only：正式 BattleScreen 的擁擠 UI 驗收。沿用現有藥牌／法寶，不修改內容或規則。
      run.relics = ["wine_gourd", "jade_buddha", "wind_pearl", "thunder_pearl", "earth_pearl", "seven_star_sword"];
      const medicines = Object.values(db.cards).filter((c) => c.type === "item" && c.effects.some((e) => e.kind === "heal" || e.kind === "cleanse" || e.kind === "gain_qi")).slice(0, 3);
      for (const c of medicines) addCardToRun(db, run, c.id);
      run = beginBattle(db, run, node, 1);
      if (run.pending.kind === "battle") {
        const b = run.pending.battle;
        const all = [...b.hand, ...b.draw];
        const medicineIds = new Set(medicines.map((c) => c.id));
        const items = medicines.map((m) => all.find((c) => c.defId === m.id)!);
        const other = all.filter((c) => !medicineIds.has(c.defId));
        b.hand = [...other.slice(0, 3), ...items, ...other.slice(3, 5)];
        const ids = new Set(b.hand.map((c) => c.uid));
        b.draw = all.filter((c) => !ids.has(c.uid));
      }
      return run;
    }
    if (p.kind === "chapter_intro") run = beginChapter(run);
    else if (p.kind === "map") run = enterNode(db, run, availableNodes(db, run)[0]!.id);
    else if (p.kind === "story") run = completeStory(db, run, []);
    else if (p.kind === "battle") run = concludeBattle(db, updateBattle(run, playBattle(db, p.battle, 60).state));
    else if (p.kind === "battle_lost") run = retryBattle(db, run, true);
    else if (p.kind === "reward") run = takeReward(db, run, p.choices.map((g) => g[0] ?? null));
    else if (p.kind === "inn") run = leaveInn(db, run);
    else break;
  }
  return run;
}

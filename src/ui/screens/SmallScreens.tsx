import { useEffect } from "react";
import { beginChapter, nodeOf, retryBattle, type RunState } from "../../core/run";
import { CHARACTERS } from "../../content/characters";
import { game } from "../../game/store";
import { playMusic } from "../../platform/audio";

/** 戰敗：從這場戰鬥前重來（HP 至少回到 60%）；連敗兩次可改用劇情難度（REDESIGN §2.1） */
export function BattleLostScreen({ run }: { run: RunState }) {
  const p = run.pending as Extract<RunState["pending"], { kind: "battle_lost" }>;
  const node = nodeOf(game.db, run, p.nodeId);
  const losses = run.losses[p.nodeId] ?? 0;
  useEffect(() => playMusic("sad"), []);
  return (
    <div className="lost">
      <h1>敗北</h1>
      <p>「{node.label}」這一戰沒能撐住。</p>
      <p className="lost-note">重來時，全隊的傷勢至少會恢復到六成。</p>
      <div className="lost-actions">
        <button type="button" className="ui-btn primary" onClick={() => game.update((db, r) => retryBattle(db, r, false))}>
          重整旗鼓，再戰一次
        </button>
        {losses >= 2 ? (
          <button type="button" className="ui-btn" onClick={() => game.update((db, r) => retryBattle(db, r, true))}>
            這一戰改用劇情難度（敵人生命 −40%）
          </button>
        ) : null}
      </div>
    </div>
  );
}

/** 章節標題卡 */
export function ChapterIntroScreen({ run }: { run: RunState }) {
  const chapter = game.db.chapters[run.chapter]!;
  useEffect(() => {
    if (chapter.music) playMusic(chapter.music);
  }, [chapter.music]);
  const go = () => game.update((_, r) => beginChapter(r));
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => (e.key === "Enter" || e.key === " ") && go();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  });
  return (
    <div className="chapter-intro" onClick={go}>
      <div className="chapter-intro-map" style={{ backgroundImage: `url(${chapter.map})` }} />
      <h1>{chapter.title}</h1>
      <p>{chapter.subtitle}</p>
      {chapter.epigraph ? <blockquote className="chapter-epigraph">{chapter.epigraph}</blockquote> : null}
      <small>點擊繼續</small>
    </div>
  );
}

/** 結局：通關紀錄 */
export function EndingScreen({ run }: { run: RunState }) {
  useEffect(() => playMusic("ending"), []);
  const bonds = Object.entries(run.bonds).sort((a, b) => b[1] - a[1]);
  return (
    <div className="ending">
      <h1>全劇終</h1>
      <p>謝謝你陪逍遙走完這段旅程。</p>
      <dl>
        <dt>戰鬥</dt>
        <dd>{run.stats.battles} 場（敗北 {run.stats.defeats} 次）</dd>
        <dt>出牌</dt>
        <dd>{run.stats.cardsPlayed} 張</dd>
        <dt>遊玩時間</dt>
        <dd>{Math.round(run.stats.playMinutes)} 分鐘</dd>
        <dt>情誼</dt>
        <dd>{bonds.map(([id, v]) => `${CHARACTERS[id as keyof typeof CHARACTERS]?.name ?? id} ${v}`).join("、") || "—"}</dd>
      </dl>
      <p className="ending-note">本作為仙劍奇俠傳（大宇資訊）的私人同人作品，不公開散佈、不營利。</p>
      <button type="button" className="ui-btn primary" onClick={() => game.quit()}>
        回到標題
      </button>
    </div>
  );
}

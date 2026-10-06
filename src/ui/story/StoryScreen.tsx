import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { flattenStory, type StoryStep } from "../../core/run";
import { STORY_BACKGROUNDS } from "../../content/backgrounds";
import { CHARACTERS, NPCS } from "../../content/characters";
import { game } from "../../game/store";
import { useSettings } from "../../game/settings";
import { playMusic } from "../../platform/audio";
import { GameMenu } from "../common/GameMenu";
import { useMenuRequest } from "../common/useEscape";
import { noticesOf } from "./notices";
import { Portrait } from "./Portrait";

/**
 * 劇情畫面（REDESIGN §5：2D 視覺小說式）。
 * 播放 flattenStory 展開的步驟；遇到選擇就等玩家選，選完重新展開（後面的分支會變）。
 * 播完把整串選擇交給 core 的 completeStory，由 core 統一套用入隊、獎勵等指令。
 */
interface Props {
  storyId: string;
  flags: Record<string, boolean>;
  onDone: (choices: number[]) => void;
}

type Spoken = Extract<StoryStep, { say: string }>;

/** Reserve the complete sentence so revealing characters cannot move or rewrap it. */
function StoryText({ text, shown }: { text: string; shown: number }) {
  return <>{text.slice(0, shown)}<span className="story-unrevealed" aria-hidden="true">{text.slice(shown)}</span></>;
}

function speakerName(who: string): string {
  return (CHARACTERS as Record<string, { name: string }>)[who]?.name ?? NPCS[who]?.name ?? "";
}

/** 從第 index 步往回找目前該顯示的背景 */
function backgroundAt(initial: string, steps: StoryStep[], index: number): string {
  let bg = initial;
  for (let i = 0; i <= index && i < steps.length; i++) {
    const s = steps[i]!;
    if ("bg" in s) bg = s.bg;
  }
  return bg;
}

/** 畫面上要停下來的步驟：台詞、旁白、選擇。其他指令（入隊、獎勵…）直接略過 */
const isStop = (s: StoryStep) => "say" in s || "narrate" in s || "choice" in s;

export function StoryScreen({ storyId, flags, onDone }: Props) {
  const story = game.db.stories[storyId]!;
  const settings = useSettings();
  const [choices, setChoices] = useState<number[]>([]);
  const steps = useMemo(() => flattenStory(story.steps, choices, flags), [story, choices, flags]);
  const [index, setIndex] = useState(() => steps.findIndex(isStop));
  const [shown, setShown] = useState(0);
  const [log, setLog] = useState<{ who: string; text: string }[]>([]);
  const [showLog, setShowLog] = useState(false);
  const [menu, setMenu] = useState(false);
  useMenuRequest(useCallback(() => setMenu(true), []));
  const finished = useRef(false);

  const step = index >= 0 ? steps[index] : undefined;
  const text = step && "say" in step ? step.say : step && "narrate" in step ? step.narrate : "";
  const typing = shown < text.length;

  // 背景音樂：播到目前為止最後一個指定的曲子（沒指定就沿用章節的，不切換）
  const musicId = useMemo(() => {
    let m = story.music ?? null;
    for (let i = 0; i <= index && i < steps.length; i++) {
      const s = steps[i]!;
      if ("music" in s) m = s.music;
    }
    return m;
  }, [story.music, steps, index]);
  useEffect(() => {
    if (musicId) playMusic(musicId);
  }, [musicId]);

  // 打字機效果
  useEffect(() => {
    setShown(settings.textSpeed <= 0 ? text.length : 0);
  }, [index, text, settings.textSpeed]);
  useEffect(() => {
    if (!typing || settings.textSpeed <= 0) return;
    const id = window.setInterval(() => setShown((n) => Math.min(text.length, n + 1)), 1000 / settings.textSpeed);
    return () => window.clearInterval(id);
  }, [typing, text, settings.textSpeed]);

  const finish = useCallback(
    (final: number[]) => {
      if (finished.current) return;
      finished.current = true;
      onDone(final);
    },
    [onDone],
  );

  // 入隊、獎勵、情誼等提示：前進時把跳過的指令步驟顯示出來；劇本最後有提示就先停在提示面板
  const [notes, setNotes] = useState<{ key: number; text: string }[]>([]);
  const [ending, setEnding] = useState<{ choices: number[]; notes: string[] } | null>(null);
  const noteKey = useRef(0);
  const announce = useCallback((list: StoryStep[]) => {
    const texts = noticesOf(list);
    if (!texts.length) return;
    const fresh = texts.map((text) => ({ key: noteKey.current++, text }));
    setNotes((n) => [...n, ...fresh]);
    window.setTimeout(() => setNotes((n) => n.filter((x) => !fresh.includes(x))), 3200);
  }, []);
  /** 從 from（不含）走到 to（不含）；to < 0 表示劇本結束 */
  const moveTo = useCallback(
    (list: StoryStep[], from: number, to: number, final: number[]) => {
      const passed = list.slice(from + 1, to < 0 ? undefined : to);
      if (to >= 0) {
        announce(passed);
        setIndex(to);
        return;
      }
      const texts = noticesOf(passed);
      if (texts.length) setEnding({ choices: final, notes: texts });
      else finish(final);
    },
    [announce, finish],
  );

  /** 前進到下一個要停的步驟；沒有了就結束 */
  const advance = useCallback(() => {
    if (ending) return finish(ending.choices);
    if (!step) return;
    if (typing) {
      setShown(text.length);
      return;
    }
    if ("choice" in step) return;
    if ("say" in step || "narrate" in step) setLog((l) => [...l, { who: "say" in step ? speakerName(step.who) : "", text }]);
    const next = steps.findIndex((s, i) => i > index && isStop(s));
    moveTo(steps, index, next, choices);
  }, [ending, step, typing, text, steps, index, choices, finish, moveTo]);

  const pick = (option: number) => {
    if (!step || !("choice" in step)) return;
    const picked = [...choices, option];
    const label = step.choice[option]!.text;
    setLog((l) => [...l, { who: "", text: `▸ ${label}` }]);
    setChoices(picked);
    // 選完之後的步驟要用新的選擇重新展開；index 之前的步驟不受影響
    const after = flattenStory(story.steps, picked, flags);
    const next = after.findIndex((s, i) => i > index && isStop(s));
    moveTo(after, index, next, picked);
  };

  /** 跳過：一路前進到下一個選擇或結尾（途中的獎勵、入隊仍會提示） */
  const skip = () => {
    if (ending) return finish(ending.choices);
    const next = steps.findIndex((s, i) => i > index && "choice" in s);
    moveTo(steps, index, next, choices);
  };

  // 自動播放：字打完後停一下自動前進
  useEffect(() => {
    if (!settings.autoPlay || typing || !step || "choice" in step) return;
    const id = window.setTimeout(advance, 1200 + text.length * 25);
    return () => window.clearTimeout(id);
  }, [settings.autoPlay, typing, step, text, advance]);

  // 鍵盤：空白、Enter 前進
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (menu) return;
      if (showLog) {
        if (e.key === "Escape") setShowLog(false);
        return;
      }
      if (e.key === " " || e.key === "Enter") {
        e.preventDefault();
        advance();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [advance, showLog, menu]);

  // 沒有任何台詞的劇本（只有指令）：直接結束
  useEffect(() => {
    if (index < 0) finish(choices);
  }, [index, choices, finish]);

  const bgId = backgroundAt(story.bg, steps, index);
  const bg = STORY_BACKGROUNDS[bgId];
  const speaking = step && "say" in step ? (step as Spoken) : null;
  const isHero = speaking ? speaking.who in CHARACTERS : false;

  return (
    <div className="story" onClick={advance}>
      {/* 背景圖還沒交付時，退回 CSS 漸層底色 */}
      <div className="story-bg" style={bg ? { backgroundImage: `url(${bg.image}), var(--story-fallback)` } : undefined} data-tint={bg?.tint ?? "none"} />
      {speaking ? <Portrait key={speaking.who} who={speaking.who} expr={speaking.expr} side={isHero ? "left" : "right"} /> : null}
      {step && "narrate" in step ? (
        <div className="story-narration">
          <p><StoryText text={text} shown={shown} /></p>
        </div>
      ) : null}
      {speaking ? (
        <div className="story-box">
          <div className="story-name">{speakerName(speaking.who)}</div>
          <p className="story-line"><StoryText text={text} shown={shown} /></p>
          {!typing ? <span className="story-next">▾</span> : null}
        </div>
      ) : null}
      {step && "choice" in step ? (
        <div className="story-choices" onClick={(e) => e.stopPropagation()}>
          {step.choice.map((c, i) => (
            <button key={i} type="button" className="story-choice-btn" onClick={() => pick(i)}>
              {c.text}
            </button>
          ))}
        </div>
      ) : null}
      <div className="story-tools" onClick={(e) => e.stopPropagation()}>
        <button type="button" onClick={() => setShowLog(true)}>回看</button>
        <button type="button" onClick={skip}>略過</button>
        <button type="button" onClick={() => setMenu(true)}>選單</button>
      </div>
      <div className="story-notes">
        {notes.map((n) => (
          <div key={n.key} className="story-note">
            {n.text}
          </div>
        ))}
      </div>
      {ending ? (
        <div className="story-ending">
          <div className="story-ending-panel">
            {ending.notes.map((t, i) => (
              <p key={i}>{t}</p>
            ))}
            <button type="button" className="ui-btn primary">
              繼續
            </button>
          </div>
        </div>
      ) : null}
      {menu ? (
        <div onClick={(e) => e.stopPropagation()}>
          <GameMenu onClose={() => setMenu(false)} />
        </div>
      ) : null}
      {showLog ? (
        <div className="story-log" onClick={(e) => (e.stopPropagation(), setShowLog(false))}>
          <div className="story-log-inner" onClick={(e) => e.stopPropagation()}>
            {log.map((l, i) => (
              <p key={i}>
                {l.who ? <b>{l.who}：</b> : null}
                {l.text}
              </p>
            ))}
            <button type="button" onClick={() => setShowLog(false)}>關閉</button>
          </div>
        </div>
      ) : null}
    </div>
  );
}

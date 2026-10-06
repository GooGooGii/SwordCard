import { useState } from "react";
import { CHARACTERS } from "../content/characters";
import type { Difficulty } from "../core/run";
import { importSave, listSaves, SLOT_COUNT, type SaveMeta } from "../platform/save";
import { game } from "../game/store";
import { useEscape } from "./common/useEscape";
import "./ui.css";

/** 存檔欄位（3 格）：開新故事選要寫到哪一格；讀檔選要接續哪一格 */
export function SlotPicker({ mode, onPick, onClose }: { mode: "new" | "load"; onPick: (slot: number, difficulty: Difficulty) => void; onClose: () => void }) {
  useEscape(onClose);
  const saves = listSaves();
  const [confirm, setConfirm] = useState<number | null>(null);
  const [difficulty, setDifficulty] = useState<Difficulty>("standard");
  const [importText, setImportText] = useState("");
  const [importNote, setImportNote] = useState<string | null>(null);
  const label = (s: SaveMeta) => {
    const chapter = game.db.chapters[s.chapter];
    const party = s.party.map((id) => CHARACTERS[id as keyof typeof CHARACTERS]?.name ?? id).join("、");
    const date = new Date(s.savedAt).toLocaleString("zh-TW", { month: "numeric", day: "numeric", hour: "2-digit", minute: "2-digit" });
    return (
      <>
        <b>{chapter ? chapter.title : "全劇終"}</b>
        <span>{party}</span>
        <small>
          {date}・{Math.round(s.playMinutes)} 分鐘・{s.coins} 文
        </small>
      </>
    );
  };
  return (
    <div className="ov slot-ov" onClick={onClose}>
      <div className="ov-panel slot-panel" onClick={(e) => e.stopPropagation()}>
        <div className="ov-head">
          <h2>{mode === "new" ? "新的故事：選擇存檔欄" : "舊的回憶：選擇存檔"}</h2>
          <button type="button" className="ui-btn" onClick={onClose}>
            返回
          </button>
        </div>
        {mode === "new" ? (
          <div className="slot-difficulty">
            <button type="button" className={`ui-btn ${difficulty === "standard" ? "primary" : ""}`} onClick={() => setDifficulty("standard")}>
              標準
            </button>
            <button type="button" className={`ui-btn ${difficulty === "story" ? "primary" : ""}`} onClick={() => setDifficulty("story")}>
              劇情（敵人生命 −40%）
            </button>
          </div>
        ) : null}
        {mode === "load" ? (
          <details className="slot-import">
            <summary>匯入存檔（貼上之前匯出的文字，寫到第 3 欄）</summary>
            <textarea value={importText} onChange={(e) => setImportText(e.target.value)} rows={3} />
            <button
              type="button"
              className="ui-btn"
              onClick={() => {
                const ok = importSave(SLOT_COUNT - 1, importText.trim());
                setImportNote(ok ? "已匯入到第 3 欄" : "格式不對，請貼上完整的匯出文字");
                if (ok) setImportText("");
              }}
            >
              匯入
            </button>
            {importNote ? <small>{importNote}</small> : null}
          </details>
        ) : null}
        {saves.map((s, slot) => {
          const disabled = mode === "load" && !s;
          return (
            <button
              key={slot}
              type="button"
              className="slot"
              disabled={disabled}
              onClick={() => {
                if (mode === "new" && s && confirm !== slot) return setConfirm(slot);
                onPick(slot, difficulty);
              }}
            >
              <span className="slot-no">第 {slot + 1} 欄</span>
              {s ? label(s) : <span className="slot-empty">（空）</span>}
              {confirm === slot ? <em className="slot-warn">再點一次覆蓋這份存檔</em> : null}
            </button>
          );
        })}
      </div>
    </div>
  );
}

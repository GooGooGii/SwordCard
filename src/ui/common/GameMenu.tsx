import { useState } from "react";
import { game } from "../../game/store";
import { exportSave } from "../../platform/save";
import { setSettings, useSettings, type Settings } from "../../game/settings";
import { useEscape } from "./useEscape";

/**
 * 遊戲中選單：設定（REDESIGN §9.1）＋存檔離開。
 * 存檔是自動的（每個動作後寫入），「回到標題」只是離開畫面。
 */
export function GameMenu({ onClose, onQuit }: { onClose: () => void; onQuit?: () => void }) {
  useEscape(onClose);
  const s = useSettings();
  const [note, setNote] = useState<string | null>(null);
  const row = <K extends keyof Settings>(label: string, key: K, options: [Settings[K], string][]) => (
    <div className="menu-row">
      <span>{label}</span>
      <div className="menu-options">
        {options.map(([value, text]) => (
          <button key={String(value)} type="button" className={`ui-btn ${s[key] === value ? "primary" : ""}`} onClick={() => setSettings({ [key]: value } as Partial<Settings>)}>
            {text}
          </button>
        ))}
      </div>
    </div>
  );
  return (
    <div className="ov" onClick={onClose}>
      <div className="ov-panel game-menu" onClick={(e) => e.stopPropagation()}>
        <div className="ov-head">
          <h2>選單</h2>
          <button type="button" className="ui-btn" onClick={onClose}>
            返回
          </button>
        </div>
        <div className="menu-row">
          <span>音樂</span>
          <input type="range" min={0} max={1} step={0.05} value={s.music} onChange={(e) => setSettings({ music: Number(e.target.value) })} />
        </div>
        <div className="menu-row">
          <span>音效</span>
          <input type="range" min={0} max={1} step={0.05} value={s.sfx} onChange={(e) => setSettings({ sfx: Number(e.target.value) })} />
        </div>
        {row("文字速度", "textSpeed", [[20, "慢"], [40, "中"], [80, "快"], [0, "立即"]])}
        {row("自動播放", "autoPlay", [[false, "關"], [true, "開"]])}
        {row("戰鬥動畫", "animSpeed", [[1, "1×"], [1.5, "1.5×"], [0, "略過"]])}
        {row("畫質", "quality", [["high", "高"], ["low", "省電"]])}
        {row("主角", "partyStyle", [["3d", "3D 模型"], ["2d", "2D 立繪"]])}
        {row("字級", "fontScale", [[1, "標準"], [1.15, "大"], [1.3, "特大"]])}
        <p className="menu-note">
          進度會在每個動作後自動存檔。
          {game.run ? (
            <button
              type="button"
              className="ui-btn menu-export"
              onClick={() => {
                const text = exportSave(game.slot);
                if (!text) return setNote("沒有可匯出的存檔");
                navigator.clipboard?.writeText(text).then(
                  () => setNote("存檔已複製到剪貼簿，可以貼到別處保存"),
                  () => setNote("無法使用剪貼簿"),
                );
              }}
            >
              匯出存檔
            </button>
          ) : null}
          {note ? <small>{note}</small> : null}
        </p>
        <button
          type="button"
          className="ui-btn primary"
          onClick={() => {
            onClose();
            if (onQuit) onQuit();
            else game.quit();
          }}
        >
          回到標題
        </button>
      </div>
    </div>
  );
}

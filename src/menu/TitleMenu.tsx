import { lazy, Suspense } from "react";

const TitleStillLife = lazy(() => import("./TitleStillLife"));

interface TitleMenuProps {
  active: boolean;
  hasMemory: boolean;
  onNewStory: () => void;
  onContinue: () => void;
  /** 「舊的回憶」下方的說明；正式遊戲改說存檔，原型沿用預設 */
  memoryHint?: string;
  /** 正式遊戲可由讀檔欄匯入其他裝置的存檔；原型沒有匯入功能。 */
  allowMemoryImport?: boolean;
}

export function TitleMenu({ active, hasMemory, onNewStory, onContinue, memoryHint, allowMemoryImport = false }: TitleMenuProps) {
  return (
    <main className="title-screen" aria-label="SwordCard 起始選單">
      <div className="title-stage" aria-hidden="true">
        <Suspense fallback={<div className="title-loading">展卷中…</div>}>
          <TitleStillLife active={active} />
        </Suspense>
      </div>
      <div className="title-vignette" aria-hidden="true" />
      <div className="title-wordmark" aria-label="SwordCard">SwordCard<span>仙劍一・卡牌敘事</span></div>
      <nav className="title-choices" aria-label="故事選擇">
        <button className="story-choice new-story" onClick={onNewStory}>新的故事</button>
        <button className="story-choice" disabled={!hasMemory && !allowMemoryImport} onClick={onContinue} title={memoryHint ?? (hasMemory ? "接續本機保存的戰鬥原型" : "尚無本機回憶")}>舊的回憶</button>
        <p className="memory-hint">{memoryHint ?? (hasMemory ? "接續此裝置上的戰鬥原型" : "尚無回憶，從新的故事開始")}</p>
      </nav>
      <span className="title-edition">私人同人原型</span>
    </main>
  );
}

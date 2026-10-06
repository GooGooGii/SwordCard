import { lazy, Suspense, useEffect, useState } from "react";
import { newRun, type Difficulty } from "./core/run";
import { playMusic } from "./platform/audio";
import { game, useRun } from "./game/store";
import { TitleMenu } from "./menu/TitleMenu";
import { readMemory, type PrototypeMemory } from "./menu/prototypeMemory";
import { listSaves, loadRun } from "./platform/save";

const BattlePrototype = lazy(() => import("./BattlePrototype"));
const GameRoot = lazy(() => import("./ui/GameRoot").then((m) => ({ default: m.GameRoot })));
const SlotPicker = lazy(() => import("./ui/SlotPicker").then((m) => ({ default: m.SlotPicker })));
const params = new URLSearchParams(window.location.search);
// 效能測試與原型的直達連結（?stress 3 對 3、?perf 幀率、?battle 原型戰場）保留原本的流程
const PROTOTYPE = params.has("stress") || params.has("perf") || params.has("battle") || params.has("resume");

export function App() {
  return PROTOTYPE ? <PrototypeApp /> : <GameApp />;
}

/** 正式遊戲：3D 起始選單（MENU-001）→ 存檔欄 → 章節行程（UI-001） */
function GameApp() {
  const run = useRun();
  const [picker, setPicker] = useState<"new" | "load" | null>(null);
  const [gameLoaded, setGameLoaded] = useState(false);
  const hasSave = listSaves().some((s) => s !== null);
  const inGame = run !== null;
  useEffect(() => {
    if (!inGame) playMusic("title");
  }, [inGame]);
  // 開發用：?dev=<章> 直接跳到某一章（正式建置會整段移除）
  useEffect(() => {
    if (!import.meta.env.DEV || !params.has("dev")) return;
    void import("./game/devJump").then(async ({ devJump }) => {
      const [chapter, node] = (params.get("dev") ?? "0").split(":");
      const next = await devJump(game.db, Number(chapter) || 0, node, params.has("visualqa"));
      setGameLoaded(true);
      game.start(next, 2);
    });
  }, []);

  const start = (slot: number, difficulty: Difficulty) => {
    const next = picker === "load" ? loadRun(slot) : newRun(game.db, (Math.random() * 2 ** 31) | 0, difficulty);
    setPicker(null);
    if (!next) return;
    setGameLoaded(true);
    game.start(next, slot);
  };

  // 起始選單的 Canvas 保留不卸載（drei Html 同步卸載會出錯），離開時只隱藏並停止渲染
  return (
    <>
      <div className="screen-slot" hidden={inGame}>
        <TitleMenu
          active={!inGame}
          hasMemory={hasSave}
          allowMemoryImport
          memoryHint={hasSave ? "接續上次的旅程" : "尚無存檔，可匯入其他裝置的旅程"}
          onNewStory={() => setPicker("new")}
          onContinue={() => setPicker("load")}
        />
      </div>
      {gameLoaded || inGame ? (
        <div className="screen-slot" hidden={!inGame}>
          <Suspense fallback={<div className="battle-loading" role="status">故事展開中…</div>}>{inGame ? <GameRoot /> : null}</Suspense>
        </div>
      ) : null}
      {picker ? (
        <Suspense fallback={null}>
          <SlotPicker mode={picker} onPick={start} onClose={() => setPicker(null)} />
        </Suspense>
      ) : null}
    </>
  );
}

/** 階段 0′ 原型與效能測試：Codex 的 MENU-001 接法原樣保留（起始選單 ↔ 戰鬥原型、原型記憶續玩） */
function PrototypeApp() {
  const [inBattle, setInBattle] = useState(params.has("stress") || params.has("perf") || params.has("battle") || params.has("resume"));
  const [battleLoaded, setBattleLoaded] = useState(inBattle);
  const [menuLoaded, setMenuLoaded] = useState(!inBattle);
  const [entryId, setEntryId] = useState(0);
  const [memory, setMemory] = useState<PrototypeMemory | null>(readMemory);
  const [entryMemory, setEntryMemory] = useState<PrototypeMemory | null>(() => params.has("resume") ? readMemory() : null);
  const continueStory = () => {
    const saved = readMemory();
    if (!saved) { setMemory(null); return; }
    const stress = params.has("stress");
    if ((saved.mode === "stress") !== stress) {
      const url = new URL(window.location.href);
      if (saved.mode === "stress") url.searchParams.set("stress", "");
      else { url.searchParams.delete("stress"); url.searchParams.delete("perf"); }
      url.searchParams.set("resume", "");
      window.location.assign(url.href);
      return;
    }
    setEntryMemory(saved);
    setEntryId((id) => id + 1);
    setBattleLoaded(true);
    setInBattle(true);
  };
  // 保留 Canvas root：drei Html 自己持有 DOM root，父 React root 同步卸載它時
  // 會造成 removeChild / 血條遺失。隱藏畫面停止渲染，重開則重置戰鬥狀態。
  return (
    <>
      {menuLoaded ? <div className="screen-slot" hidden={inBattle}>
        <TitleMenu active={!inBattle} hasMemory={memory !== null} onNewStory={() => {
          setEntryMemory(null);
          setEntryId((id) => id + 1);
          setBattleLoaded(true);
          setInBattle(true);
        }} onContinue={continueStory} />
      </div> : null}
      {battleLoaded ? <div className="screen-slot" hidden={!inBattle}>
        <Suspense fallback={<div className="battle-loading" role="status">故事展開中…</div>}>
          <BattlePrototype memory={entryMemory} entryId={entryId} active={inBattle} onExit={() => {
            setMemory(readMemory());
            setMenuLoaded(true);
            setInBattle(false);
          }} />
        </Suspense>
      </div> : null}
    </>
  );
}

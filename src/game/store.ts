import { useSyncExternalStore } from "react";
import type { GameDb, RunState } from "../core/run";
import { GAME_DB } from "../content";
import { saveRun } from "../platform/save";

/**
 * 整局遊戲的唯一狀態來源。畫面只讀；要改狀態一律透過 core 的 reducer（update）。
 * 每次改動都自動存到目前的存檔欄位（REDESIGN §7.3：每個動作後自動寫入）。
 */
type Listener = () => void;

let run: RunState | null = null;
let slot = 0;
let lastTick = Date.now();
const listeners = new Set<Listener>();

function emit() {
  for (const l of listeners) l();
}

/** 遊玩時間：兩次操作間隔超過 5 分鐘視為離開，不計入 */
function tick(next: RunState): RunState {
  const now = Date.now();
  const gap = Math.min(now - lastTick, 5 * 60_000);
  lastTick = now;
  next.stats.playMinutes = Math.round((next.stats.playMinutes + gap / 60_000) * 100) / 100;
  return next;
}

export const game = {
  db: GAME_DB as GameDb,
  get run() {
    return run;
  },
  get slot() {
    return slot;
  },
  start(next: RunState, saveSlot: number) {
    run = next;
    slot = saveSlot;
    lastTick = Date.now();
    saveRun(slot, run);
    emit();
  },
  /** 套用一個 core reducer：(db, run) → 新的 run */
  update(fn: (db: GameDb, current: RunState) => RunState) {
    if (!run) return;
    run = tick(fn(GAME_DB, run));
    saveRun(slot, run);
    emit();
  },
  quit() {
    run = null;
    emit();
  },
};

function subscribe(l: Listener) {
  listeners.add(l);
  return () => listeners.delete(l);
}

export function useRun(): RunState | null {
  return useSyncExternalStore(subscribe, () => run);
}

import { useSyncExternalStore } from "react";

/** 設定（REDESIGN §9.1）：音量、文字速度、動畫速度、畫質、字級。只存在這台裝置。 */
export interface Settings {
  music: number;
  sfx: number;
  /** 每秒字數；0＝立即顯示 */
  textSpeed: number;
  autoPlay: boolean;
  /** 戰鬥演出速度：1、1.5，或 0＝略過動畫 */
  animSpeed: 1 | 1.5 | 0;
  /** 後製（柔光、暗角）與解析度上限 */
  quality: "high" | "low";
  fontScale: 1 | 1.15 | 1.3;
  /** 戰鬥中主角的呈現：3D 模型，或 2D 全身立繪（和卡圖同一套畫風、手機較省電） */
  partyStyle: "3d" | "2d";
  /** 美術版本：2＝電影感 CG（2026-10-06）。舊設定升到 2 時改用 2D 立繪，因為 3D 模型還是舊畫風 */
  artVersion?: number;
}

const KEY = "xiaoyao.settings";
const DEFAULTS: Settings = { music: 0.6, sfx: 0.8, textSpeed: 40, autoPlay: false, animSpeed: 1, quality: "high", fontScale: 1, partyStyle: "2d", artVersion: 2 };

function load(): Settings {
  try {
    const raw = window.localStorage.getItem(KEY);
    if (!raw) return DEFAULTS;
    const saved = JSON.parse(raw) as Partial<Settings>;
    const merged = { ...DEFAULTS, ...saved };
    return (saved.artVersion ?? 1) < 2 ? { ...merged, partyStyle: "2d", artVersion: 2 } : merged;
  } catch {
    return DEFAULTS;
  }
}

let current: Settings = typeof window !== "undefined" ? load() : DEFAULTS;
const listeners = new Set<() => void>();

export function getSettings(): Settings {
  return current;
}

export function setSettings(patch: Partial<Settings>): void {
  current = { ...current, ...patch };
  try {
    window.localStorage.setItem(KEY, JSON.stringify(current));
  } catch {
    /* 私密模式等情況：只保留在記憶體 */
  }
  for (const l of listeners) l();
}

export function useSettings(): Settings {
  return useSyncExternalStore(
    (l) => {
      listeners.add(l);
      return () => listeners.delete(l);
    },
    () => current,
  );
}

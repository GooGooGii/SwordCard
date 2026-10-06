import type { RunState } from "../core/run";

/**
 * 存檔（REDESIGN §7.3）：3 個欄位，每個節點完成、每個戰鬥動作後自動寫入。
 * 存的就是 RunState（純資料，戰鬥中的狀態也在裡面）。
 */
export const SLOT_COUNT = 3;
const KEY = (slot: number) => `xiaoyao.save.${slot}`;
const SAVE_VERSION = 1;

export interface SaveMeta {
  slot: number;
  savedAt: number;
  chapter: number;
  party: string[];
  coins: number;
  playMinutes: number;
}

interface SaveFile {
  version: number;
  savedAt: number;
  run: RunState;
}

export interface KeyValueStore {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}

function store(): KeyValueStore | null {
  try {
    return typeof window !== "undefined" ? window.localStorage : null;
  } catch {
    return null;
  }
}

/** 舊版存檔升級（目前只有 v1） */
function migrate(file: SaveFile): SaveFile | null {
  if (file.version === SAVE_VERSION) return file;
  return null;
}

export function saveRun(slot: number, run: RunState, kv: KeyValueStore | null = store()): boolean {
  if (!kv) return false;
  const file: SaveFile = { version: SAVE_VERSION, savedAt: Date.now(), run };
  try {
    kv.setItem(KEY(slot), JSON.stringify(file));
    return true;
  } catch {
    return false;
  }
}

export function loadRun(slot: number, kv: KeyValueStore | null = store()): RunState | null {
  if (!kv) return null;
  try {
    const raw = kv.getItem(KEY(slot));
    if (!raw) return null;
    const file = migrate(JSON.parse(raw) as SaveFile);
    return file?.run ?? null;
  } catch {
    return null;
  }
}

export function deleteRun(slot: number, kv: KeyValueStore | null = store()): void {
  try {
    kv?.removeItem(KEY(slot));
  } catch {
    /* 無法寫入時忽略 */
  }
}

export function listSaves(kv: KeyValueStore | null = store()): (SaveMeta | null)[] {
  return Array.from({ length: SLOT_COUNT }, (_, slot) => {
    if (!kv) return null;
    try {
      const raw = kv.getItem(KEY(slot));
      if (!raw) return null;
      const file = migrate(JSON.parse(raw) as SaveFile);
      if (!file) return null;
      return {
        slot,
        savedAt: file.savedAt,
        chapter: file.run.chapter,
        party: file.run.party,
        coins: file.run.coins,
        playMinutes: file.run.stats.playMinutes,
      };
    } catch {
      return null;
    }
  });
}

/** 匯出／匯入（備份用，REDESIGN §7.3） */
export function exportSave(slot: number, kv: KeyValueStore | null = store()): string | null {
  return kv?.getItem(KEY(slot)) ?? null;
}

export function importSave(slot: number, text: string, kv: KeyValueStore | null = store()): boolean {
  try {
    const file = migrate(JSON.parse(text) as SaveFile);
    if (!file?.run || file.run.version !== 1) return false;
    return saveRun(slot, file.run, kv);
  } catch {
    return false;
  }
}

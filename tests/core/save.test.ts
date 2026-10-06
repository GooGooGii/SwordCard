import { describe, expect, it } from "vitest";
import { exportSave, importSave, listSaves, loadRun, saveRun, type KeyValueStore } from "../../src/platform/save";
import type { RunState } from "../../src/core/run";

function memoryStore(): KeyValueStore & { data: Map<string, string> } {
  const data = new Map<string, string>();
  return {
    data,
    getItem: (k) => data.get(k) ?? null,
    setItem: (k, v) => void data.set(k, v),
    removeItem: (k) => void data.delete(k),
  };
}

const fakeRun = { version: 1, chapter: 2, party: ["li_xiaoyao"], coins: 33, stats: { playMinutes: 5 } } as unknown as RunState;

describe("存檔", () => {
  it("存、讀、列表、匯出匯入", () => {
    const kv = memoryStore();
    expect(listSaves(kv)).toEqual([null, null, null]);
    expect(saveRun(1, fakeRun, kv)).toBe(true);
    expect(loadRun(1, kv)).toEqual(fakeRun);
    expect(listSaves(kv)[1]).toMatchObject({ slot: 1, chapter: 2, coins: 33 });
    const text = exportSave(1, kv)!;
    expect(importSave(2, text, kv)).toBe(true);
    expect(loadRun(2, kv)).toEqual(fakeRun);
  });

  it("壞掉的存檔讀不到也不會崩潰", () => {
    const kv = memoryStore();
    kv.setItem("xiaoyao.save.0", "{not json");
    expect(loadRun(0, kv)).toBeNull();
    expect(listSaves(kv)[0]).toBeNull();
    expect(importSave(0, "garbage", kv)).toBe(false);
  });
});

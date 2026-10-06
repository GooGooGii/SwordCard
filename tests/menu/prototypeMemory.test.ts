import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { readMemory, writeMemory, type PrototypeMemory } from "../../src/menu/prototypeMemory";

const memory: PrototypeMemory = {
  version: 1, mode: "standard", qi: 2, handIds: ["c2", "c3", "c4", "c5"],
  hps: { hero: 74, linger: 58, bandit: 32, wasp: 18 },
};

describe("起始選單的本機回憶", () => {
  let saved: string | null;
  beforeEach(() => {
    saved = null;
    vi.stubGlobal("localStorage", { getItem: () => saved, setItem: (_key: string, value: string) => { saved = value; } });
  });
  afterEach(() => vi.unstubAllGlobals());

  it("保存出牌後的真氣、剩餘手牌與敵人 HP", () => {
    writeMemory(memory);
    expect(readMemory()).toEqual(memory);
  });
  it("沒有存檔或 JSON 損毀時不提供續玩", () => {
    expect(readMemory()).toBeNull();
    saved = "{broken";
    expect(readMemory()).toBeNull();
  });
  it("拒絕未知卡片、重複卡片、缺少 HP 與超出上限的 HP", () => {
    for (const patch of [
      { handIds: ["unknown"] }, { handIds: ["c1", "c1"] },
      { hps: { hero: 74 } }, { hps: { ...memory.hps, bandit: 100 } },
    ]) {
      saved = JSON.stringify({ ...memory, ...patch });
      expect(readMemory()).toBeNull();
    }
  });
  it("瀏覽器禁止儲存時不阻斷遊戲", () => {
    vi.stubGlobal("localStorage", { getItem: () => { throw new Error("denied"); }, setItem: () => { throw new Error("denied"); } });
    expect(readMemory()).toBeNull();
    expect(() => writeMemory(memory)).not.toThrow();
  });
});

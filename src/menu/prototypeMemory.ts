/** 起始選單暫存目前的戰鬥原型；正式章節存檔完成後替換。 */
export interface PrototypeMemory {
  version: 1;
  mode: "standard" | "stress";
  qi: number;
  handIds: string[];
  hps: Record<string, number>;
}

const KEY = "xiaoyao.prototype-memory.v1";

export function readMemory(): PrototypeMemory | null {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return null;
    const value = JSON.parse(raw) as Partial<PrototypeMemory>;
    if (value.version !== 1 || !["standard", "stress"].includes(value.mode ?? "")) return null;
    if (!Number.isInteger(value.qi) || value.qi! < 0 || value.qi! > 3) return null;
    if (!Array.isArray(value.handIds) || value.handIds.length > 5 || value.handIds.some((id) => !/^c[1-5]$/.test(id))) return null;
    if (new Set(value.handIds).size !== value.handIds.length) return null;
    if (!value.hps || typeof value.hps !== "object" || Array.isArray(value.hps)) return null;
    const limits = value.mode === "stress"
      ? { hero: 74, linger: 58, p3: 70, bandit: 42, wasp: 18, e3: 30 }
      : { hero: 74, linger: 58, bandit: 42, wasp: 18 };
    if (Object.entries(limits).some(([id, max]) => !Number.isInteger(value.hps![id]) || value.hps![id]! < 0 || value.hps![id]! > max)) return null;
    return value as PrototypeMemory;
  } catch {
    return null;
  }
}

export function writeMemory(memory: PrototypeMemory): void {
  try {
    localStorage.setItem(KEY, JSON.stringify(memory));
  } catch {
    // 私密模式或儲存空間不足時仍可遊玩。
  }
}

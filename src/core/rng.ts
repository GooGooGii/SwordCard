/** 種子化亂數（mulberry32）。狀態是一個 32 位元整數，存在遊戲狀態裡，存檔／重播都能還原。 */
export class Rng {
  constructor(public state: number) {}

  /** [0, 1) */
  next(): number {
    let t = (this.state = (this.state + 0x6d2b79f5) | 0);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  /** [0, n) 的整數 */
  int(n: number): number {
    return Math.floor(this.next() * n);
  }

  pick<T>(items: readonly T[]): T {
    if (items.length === 0) throw new Error("Rng.pick: empty list");
    return items[this.int(items.length)]!;
  }

  /** Fisher–Yates，原地洗牌並回傳同一個陣列 */
  shuffle<T>(items: T[]): T[] {
    for (let i = items.length - 1; i > 0; i--) {
      const j = this.int(i + 1);
      [items[i], items[j]] = [items[j]!, items[i]!];
    }
    return items;
  }

  /** 依權重抽一個 */
  weighted<T>(items: readonly { value: T; weight: number }[]): T {
    const total = items.reduce((s, x) => s + x.weight, 0);
    let roll = this.next() * total;
    for (const item of items) {
      roll -= item.weight;
      if (roll < 0) return item.value;
    }
    return items[items.length - 1]!.value;
  }
}

export function seedFromString(text: string): number {
  let h = 2166136261;
  for (let i = 0; i < text.length; i++) h = Math.imul(h ^ text.charCodeAt(i), 16777619);
  return h | 0;
}

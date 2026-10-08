import { describe, expect, it } from "vitest";
import { GAME_DB } from "../../src/content";
import { playGame } from "./fullrun";

/**
 * 流派平衡（手動跑，平常略過）：每條流派各用 N 個種子打整局，比較敗北次數與平均每場扣血。
 *   ARCH_SEEDS=6 npx vitest run tests/bot/archetypes.test.ts
 * 結果印在 console（加 --silent=false 才看得到）。目標：每條都能通關；沒有哪條明顯「選了就贏」或「選了就輸」。
 */
const count = Number(import.meta.env.ARCH_SEEDS ?? 0);
const ARCHETYPES = ["shushan", "jianghu", "wuling", "nuwa", "zhijian", "purse", "gudu", "wushu"];

describe.skipIf(count === 0)("流派平衡", () => {
  it("每條流派都能通關", () => {
    const rows: string[] = [];
    let failures = 0;
    for (const favor of [undefined, ...ARCHETYPES]) {
      let defeats = 0;
      let loss = 0;
      let battles = 0;
      let finished = 0;
      for (let seed = 1; seed <= count; seed++) {
        const r = playGame(GAME_DB, seed * 7919, "normal", 4000, favor);
        if (r.finished) finished++;
        else failures++;
        defeats += r.defeats;
        for (const b of r.battles) {
          battles++;
          loss += Math.max(0, (b.hpBefore - b.hpAfter) / b.maxHp);
        }
      }
      rows.push(`${(favor ?? "（不挑流派）").padEnd(10)} 通關 ${finished}/${count}  敗北 ${defeats}  平均每場扣血 ${((100 * loss) / Math.max(1, battles)).toFixed(1)}%`);
    }
    console.log(`ARCH_BALANCE\n${rows.join("\n")}`);
    expect(failures).toBe(0);
  }, 1_800_000);
});

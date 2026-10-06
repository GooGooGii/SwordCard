import { describe, expect, it } from "vitest";
import { GAME_DB } from "../../src/content";
import { playGame } from "./fullrun";

/**
 * 多種子通關檢查（平衡調整時手動跑，平常略過）：
 *   BOT_SEEDS=8 npx vitest run tests/bot/seeds.test.ts
 * 每個種子的地圖、抽牌、選牌都不同；兩種玩法都要全部通關。
 */
const count = Number(import.meta.env.BOT_SEEDS ?? 0);

describe.skipIf(count === 0)("多種子自動通關", () => {
  it("普通玩家與最差牌組，每個種子都通關", () => {
    const rows: string[] = [];
    let failures = 0;
    for (let seed = 1; seed <= count; seed++) {
      for (const mode of ["normal", "worst"] as const) {
        const r = playGame(GAME_DB, seed * 7919, mode);
        if (!r.finished) failures++;
        const lost = r.battles.filter((b) => b.outcome === "lost");
        rows.push(`${mode} seed=${seed} finished=${r.finished} defeats=${r.defeats} assisted=${r.assisted} coins=${r.coinsEnd} stuck=${r.stuckAt ?? "-"} lostAt=${[...new Set(lost.map((b) => b.node))].join(",")}`);
      }
    }
    console.log(`BOT_SEEDS\n${rows.join("\n")}`);
    expect(failures).toBe(0);
  }, 600_000);
});

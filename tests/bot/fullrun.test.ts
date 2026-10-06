import { describe, expect, it } from "vitest";
import { GAME_DB } from "../../src/content";
import { playGame, type RunReport } from "./fullrun";

/**
 * 自動通關（BALANCE-001）：普通玩家與最差牌組都要能從序章打到結局（REDESIGN §2.1、§7.2）。
 * 報告寫到 capture_out/bot_report.json，平衡調整時看每場戰鬥的回合數與損血。
 */
function summary(r: RunReport) {
  const byChapter: Record<string, { battles: number; defeats: number; turns: number; hpLossPct: number }> = {};
  for (const b of r.battles) {
    const c = (byChapter[b.chapter] ??= { battles: 0, defeats: 0, turns: 0, hpLossPct: 0 });
    c.battles++;
    if (b.outcome === "lost") c.defeats++;
    c.turns += b.turns;
    c.hpLossPct += b.maxHp ? ((b.hpBefore - b.hpAfter) / b.maxHp) * 100 : 0;
  }
  for (const c of Object.values(byChapter)) {
    c.turns = Math.round((c.turns / c.battles) * 10) / 10;
    c.hpLossPct = Math.round(c.hpLossPct / c.battles);
  }
  return byChapter;
}

describe("自動通關", () => {
  const reports: Record<string, RunReport> = {};

  it("普通玩家：序章打到結局", () => {
    const r = playGame(GAME_DB, 20261005, "normal");
    reports.normal = r;
    expect(r.stuckAt).toBeNull();
    expect(r.finished).toBe(true);
  }, 120_000);

  it("最差牌組（一律跳過選牌、不打支線）：也能打到結局", () => {
    const r = playGame(GAME_DB, 20261005, "worst");
    reports.worst = r;
    expect(r.stuckAt).toBeNull();
    expect(r.finished).toBe(true);
  }, 120_000);

  it("印出報告（npm test -- tests/bot > 檔案）", () => {
    const out = Object.fromEntries(
      Object.entries(reports).map(([k, r]) => [k, { finished: r.finished, defeats: r.defeats, assisted: r.assisted, coinsEnd: r.coinsEnd, stuckAt: r.stuckAt, chapters: summary(r) }]),
    );
    console.log(`BOT_REPORT ${JSON.stringify(out)}`);
    if (import.meta.env.BOT_BATTLES) for (const [k, r] of Object.entries(reports)) console.log(`BOT_BATTLES ${k} ${JSON.stringify(r.battles)}`);
    expect(Object.keys(reports).length).toBeGreaterThan(0);
  });
});

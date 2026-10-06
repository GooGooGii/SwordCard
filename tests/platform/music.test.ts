import { describe, expect, it } from "vitest";
import { BARS, compose, STEPS_PER_BAR, TRACKS } from "../../src/platform/music";
import { GAME_DB } from "../../src/content";

describe("程序化配樂", () => {
  it("章節、劇本、戰鬥用到的曲子都存在", () => {
    const used = new Set<string>(["title", "battle", "boss", "sad", "ending"]);
    for (const ch of GAME_DB.chapters) {
      if (ch.music) used.add(ch.music);
      for (const n of ch.nodes) if (n.battle?.music) used.add(n.battle.music);
    }
    for (const s of Object.values(GAME_DB.stories)) {
      if (s.music) used.add(s.music);
      for (const step of s.steps) if ("music" in step) used.add(step.music);
    }
    expect([...used].filter((id) => !(id in TRACKS))).toEqual([]);
  });

  it("作曲固定（同一首每次一樣）、音符都在循環範圍內", () => {
    for (const [id, def] of Object.entries(TRACKS)) {
      const a = compose(id, def);
      expect(compose(id, def)).toEqual(a);
      expect(a.some((n) => n.voice === "lead")).toBe(true);
      for (const n of a) {
        expect(n.step).toBeGreaterThanOrEqual(0);
        expect(n.step).toBeLessThan(BARS * STEPS_PER_BAR);
      }
    }
  });
});

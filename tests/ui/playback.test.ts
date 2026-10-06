import { describe, expect, it } from "vitest";
import { startBattle, playCard } from "../../src/core/battle";
import { snapshot, toBeats } from "../../src/ui/battle/playback";
import { db, setup } from "../core/fixtures";

describe("戰鬥接觸演出", () => {
  it("擊殺仍先播放接觸、扣血與受擊，下一拍才移除敵人", () => {
    const state = startBattle(db, setup({ enemies: ["biter"], deckIds: Array(10).fill("strike") })).state;
    state.enemies[0]!.hp = 1;
    const step = playCard(db, state, state.hand[0]!.uid, 0);
    const beats = toBeats(step.events, () => ({ name: "劍招", motion: "strike" }), () => "");
    const s = snapshot(state);
    const contact = beats.findIndex((b) => b.impact?.kind === "slash");
    expect(contact).toBeGreaterThan(0);
    expect(beats[contact]!.flash).toEqual({ side: "enemy", index: 0 });
    expect(beats[contact]!.clip?.clip).toBe("hit");
    beats[contact]!.shown!(s, step.state);
    expect(s.enemies[0]!.hp).toBe(0);
    expect(s.enemies[0]!.gone).toBe(false);
    for (const b of beats.slice(contact + 1)) b.shown?.(s, step.state);
    expect(s.enemies[0]!.gone).toBe(true);
  });
  it("完全格擋使用護體接觸色，回血只在有效治療時播放", () => {
    const target = { side: "party", index: 0 } as const;
    const beats = toBeats([
      { type: "damage", target, amount: 0, blocked: 5, effective: "normal", source: null },
      { type: "heal", target, amount: 0 },
      { type: "heal", target, amount: 8 },
    ], () => ({ name: "", motion: "cast" }), () => "");
    expect(beats.map((b) => b.impact?.kind)).toEqual(["block", "heal"]);
  });
});

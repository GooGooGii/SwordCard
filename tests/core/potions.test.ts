import { describe, expect, it } from "vitest";
import { canUsePotion, startBattle, usePotion } from "../../src/core/battle";
import { db, setup } from "./fixtures";

describe("藥品", () => {
  const start = () => {
    const s = startBattle(db, setup({ enemies: ["dummy", "dummy"] })).state;
    s.potions = ["heal_potion", "bomb", null];
    return s;
  };

  it("不花真氣、用完清空該格", () => {
    let s = start();
    s.party[0]!.hp = 10;
    const qi = s.qi;
    s = usePotion(db, s, 0, 0).state;
    expect(s.party[0]!.hp).toBe(30);
    expect(s.qi).toBe(qi);
    expect(s.potions).toEqual([null, "bomb", null]);
  });

  it("群體傷害藥打所有敵人", () => {
    let s = start();
    s = usePotion(db, s, 1, null).state;
    expect(s.enemies.map((e) => e.hp)).toEqual([28, 28]);
  });

  it("空格與需要目標時的檢查", () => {
    const s = start();
    expect(canUsePotion(db, s, 2)).toBe("這格沒有藥品");
    expect(canUsePotion(db, s, 0, null)).toBe("請選擇一名隊友");
    expect(() => usePotion(db, s, 2)).toThrow();
  });

  it("用藥不算出牌：不推進連鎖與合擊氣", () => {
    let s = start();
    s.potions = ["qi_potion", null, null];
    const gauge = s.comboGauge;
    s = usePotion(db, s, 0, null).state;
    expect(s.comboGauge).toBe(gauge);
    expect(s.qi).toBe(5);
  });
});

import type { PotionDef } from "../core/types";

/**
 * 藥品（殺戮尖塔的藥水）：不佔牌組、不花真氣、戰鬥中隨時用一次。全部取自仙劍一的道具。
 * 主要從戰鬥掉落與客棧購買取得；藥品欄 3 格。
 */
const list: PotionDef[] = [
  { id: "p_herb", name: "止血草", rarity: "common", target: "ally", effects: [{ kind: "heal", amount: 12, to: "target" }], canon: "止血草：常見草藥" },
  { id: "p_jinchuang", name: "金創藥", rarity: "uncommon", target: "ally", effects: [{ kind: "heal", amount: 25, to: "target" }], canon: "金創藥" },
  { id: "p_soul_incense", name: "還魂香", rarity: "rare", target: "ally", effects: [{ kind: "revive", amount: 20 }], canon: "還魂香：起死回生" },
  { id: "p_realgar", name: "雄黃酒", rarity: "common", target: "party", effects: [{ kind: "cleanse", to: "party" }, { kind: "block", amount: 5, to: "party" }], canon: "雄黃酒：驅邪解毒" },
  { id: "p_rat_fruit", name: "鼠兒果", rarity: "common", target: "none", effects: [{ kind: "gain_qi", amount: 2 }], canon: "鼠兒果" },
  { id: "p_royal_jelly", name: "蜂王蜜", rarity: "uncommon", target: "party", effects: [{ kind: "heal", amount: 10, to: "party" }], canon: "蜂王蜜" },
  { id: "p_thunderball", name: "霹靂彈", rarity: "common", target: "all_enemies", effects: [{ kind: "damage_all", amount: 12 }], canon: "火藥、霹靂彈（女飛賊的暗器）" },
  { id: "p_crane_red", name: "鶴頂紅", rarity: "uncommon", target: "enemy", effects: [{ kind: "apply", status: "poison", amount: 10 }], canon: "鶴頂紅：劇毒" },
  { id: "p_stun_talisman", name: "定身符", rarity: "uncommon", target: "enemy", effects: [{ kind: "apply", status: "stun", amount: 1 }], canon: "符咒類道具（頭目不受定身）" },
  { id: "p_heaven_talisman", name: "天師符", rarity: "rare", target: "enemy", effects: [{ kind: "damage", amount: 30 }], canon: "天師符" },
  { id: "p_daughter_red", name: "女兒紅", rarity: "uncommon", target: "party", effects: [{ kind: "strength", amount: 2, to: "party" }], canon: "女兒紅：李逍遙最愛的酒" },
  { id: "p_tianxiang", name: "天香續命露", rarity: "rare", target: "party", effects: [{ kind: "heal", amount: 30, to: "party" }, { kind: "cleanse", to: "party" }], canon: "天香續命露" },
];

export const POTIONS: Record<string, PotionDef> = Object.fromEntries(list.map((p) => [p.id, p]));

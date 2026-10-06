import type { CardDef } from "../../core/types";
import { card } from "./helpers";

/**
 * 無主牌：道具（多半從敵人身上偷來或劇情給的）。由 HP 最高的清醒隊員出手；用了就消耗。
 * 全部取自正史道具（REDESIGN §8.0：不做獨立道具系統，以無主牌出現）。
 */
export const ITEM_CARDS: CardDef[] = [
  card({ id: "item_herb", name: "止血草", owner: null, type: "item", target: "ally", rarity: "special", cost: 0,
    effects: [{ kind: "heal", amount: 10, to: "target" }], exhaust: true, canon: "止血草（正史道具）" }),
  card({ id: "item_salve", name: "金創藥", owner: null, type: "item", target: "ally", rarity: "special", cost: 0,
    effects: [{ kind: "heal", amount: 20, to: "target" }], exhaust: true, canon: "金創藥（正史道具）" }),
  card({ id: "item_soulincense", name: "還魂香", owner: null, type: "item", target: "ally", rarity: "special", cost: 1,
    effects: [{ kind: "revive", amount: 20 }], exhaust: true, canon: "還魂香（正史道具）" }),
  card({ id: "item_talisman", name: "天師符", owner: null, type: "item", target: "enemy", rarity: "special", cost: 0,
    effects: [{ kind: "damage", amount: 6 }, { kind: "apply", status: "break", amount: 2 }], exhaust: true, canon: "天師符（正史道具）" }),
  card({ id: "item_incense", name: "驅魔香", owner: null, type: "item", target: "all_enemies", rarity: "special", cost: 0,
    effects: [{ kind: "apply", status: "weak", amount: 2, to: "all_enemies" }], exhaust: true, canon: "驅魔香（正史道具）" }),
  card({ id: "item_realgar", name: "雄黃酒", owner: null, type: "item", target: "party", rarity: "special", cost: 0,
    effects: [{ kind: "cleanse", to: "party" }, { kind: "draw", amount: 1 }], exhaust: true, canon: "雄黃酒：驅蛇解毒（正史道具）" }),
  card({ id: "item_coins", name: "乾坤一擲", owner: null, type: "item", target: "all_enemies", rarity: "special", cost: 1,
    effects: [{ kind: "damage_all", amount: 12 }], exhaust: true, canon: "乾坤一擲：擲錢傷敵（正史招式）" }),
  card({ id: "item_bodhi", name: "玉菩提", owner: null, type: "item", target: "party", rarity: "special", cost: 0,
    effects: [{ kind: "heal", amount: 8, to: "party" }, { kind: "gain_qi", amount: 1 }], exhaust: true, canon: "玉菩提：鎮獄明王身上可偷（正史道具）" }),
  card({ id: "item_zijin", name: "紫金丹", owner: null, type: "item", target: "ally", rarity: "special", cost: 0,
    effects: [{ kind: "heal", amount: 30, to: "target" }, { kind: "cleanse", to: "target" }], exhaust: true, canon: "紫金丹：水月宮靈藥（正史道具）" }),
  card({ id: "item_wine", name: "女兒紅", owner: null, type: "item", target: "self", rarity: "special", cost: 0,
    effects: [{ kind: "gain_qi", amount: 2 }], exhaust: true, canon: "酒劍仙討的好酒（本作命名）" }),
  card({ id: "item_trialfruit", name: "試煉果", owner: null, type: "item", target: "party", rarity: "special", cost: 0,
    effects: [{ kind: "strength", amount: 2, to: "party" }], exhaust: true, canon: "試煉果（鎖妖塔道具）" }),
  card({ id: "item_bomb", name: "火雷珠", owner: null, type: "item", target: "enemy", element: "fire", rarity: "special", cost: 0,
    effects: [{ kind: "damage", amount: 14 }], exhaust: true, canon: "暗器（本作命名）" }),
];

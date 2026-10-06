import type { CardDef } from "../../core/types";
import { card } from "./helpers";

/**
 * 李逍遙：御劍速攻、連擊、偷取；用符咒帶五靈屬性（REDESIGN §4.3）。
 * 正史：御劍術（酒劍仙所傳）、萬劍訣、天劍、劍神、天罡戰氣、醉仙望月步、仙風雲體術；
 * 冰心訣、飛龍探雲手出自父母留下的手卷。
 */
const O = "li_xiaoyao" as const;

export const LI_CARDS: CardDef[] = [
  // ── 起始 ──
  card({ id: "li_strike", name: "劍招", owner: O, type: "attack", target: "enemy", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 6 }], upgrade: { effects: [{ kind: "damage", amount: 9 }] }, canon: "李逍遙的基本劍法" }),
  card({ id: "li_guard", name: "護身", owner: O, type: "skill", target: "self", rarity: "starter", cost: 1,
    effects: [{ kind: "block", amount: 5 }], upgrade: { effects: [{ kind: "block", amount: 8 }] }, canon: "防禦" }),
  card({ id: "li_steal", name: "飛龍探雲手", owner: O, type: "skill", target: "enemy", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 3 }, { kind: "steal" }], upgrade: { cost: 0 }, motion: "strike",
    canon: "飛龍探雲手：出自逍遙父母留下的手卷，可偷取敵人身上的物品" }),
  card({ id: "li_fly", name: "御劍術", owner: O, type: "attack", target: "enemy", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 4 }, { kind: "fly_sword", amount: 6 }], upgrade: { effects: [{ kind: "damage", amount: 5 }, { kind: "fly_sword", amount: 9 }] },
    canon: "御劍術：十里坡山神廟酒劍仙所傳" }),

  // ── 常見 ──
  card({ id: "li_chain", name: "連環劍", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 3, hits: 3 }], upgrade: { effects: [{ kind: "damage", amount: 4, hits: 3 }] }, canon: "李逍遙劍法（本作命名）" }),
  card({ id: "li_cloudstep", name: "仙風雲體術", owner: O, type: "skill", target: "self", rarity: "common", cost: 1,
    effects: [{ kind: "block", amount: 5 }, { kind: "draw", amount: 1 }], upgrade: { effects: [{ kind: "block", amount: 7 }, { kind: "draw", amount: 1 }] },
    canon: "仙風雲體術：提升身法" }),
  card({ id: "li_moonstep", name: "醉仙望月步", owner: O, type: "skill", target: "self", rarity: "common", cost: 1,
    effects: [{ kind: "block", amount: 9 }], upgrade: { effects: [{ kind: "block", amount: 12 }] }, retain: true,
    canon: "醉仙望月步：酒劍仙的步法" }),
  card({ id: "li_wind_talisman", name: "風靈符", owner: O, type: "spell", target: "enemy", element: "wind", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 7 }], upgrade: { effects: [{ kind: "damage", amount: 10 }] }, canon: "符咒（道具）" }),
  card({ id: "li_thunder_talisman", name: "雷靈符", owner: O, type: "spell", target: "enemy", element: "thunder", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 7 }], upgrade: { effects: [{ kind: "damage", amount: 10 }] }, canon: "符咒（道具）" }),
  card({ id: "li_fire_talisman", name: "火靈符", owner: O, type: "spell", target: "enemy", element: "fire", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 7 }], upgrade: { effects: [{ kind: "damage", amount: 10 }] }, canon: "符咒（道具）" }),
  card({ id: "li_earth_talisman", name: "土靈符", owner: O, type: "spell", target: "enemy", element: "earth", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 4 }, { kind: "block", amount: 5 }], upgrade: { effects: [{ kind: "damage", amount: 6 }, { kind: "block", amount: 7 }] },
    canon: "符咒（道具）" }),
  card({ id: "li_water_talisman", name: "水靈符", owner: O, type: "spell", target: "enemy", element: "water", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 5 }, { kind: "apply", status: "weak", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 7 }, { kind: "apply", status: "weak", amount: 2 }] }, canon: "符咒（道具）" }),
  card({ id: "li_icemind", name: "冰心訣", owner: O, type: "skill", target: "self", rarity: "common", cost: 1,
    effects: [{ kind: "cleanse" }, { kind: "heal", amount: 4 }], upgrade: { effects: [{ kind: "cleanse" }, { kind: "heal", amount: 7 }] },
    canon: "冰心訣：出自逍遙父母留下的手卷" }),
  card({ id: "li_sneak", name: "趁隙", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 0,
    effects: [{ kind: "damage", amount: 4 }], upgrade: { effects: [{ kind: "damage", amount: 6 }] }, canon: "客棧小二的機靈（本作原創）" }),

  // ── 少見 ──
  card({ id: "li_myriad", name: "萬劍訣", owner: O, type: "attack", target: "all_enemies", element: "wind", rarity: "uncommon", cost: 2,
    effects: [{ kind: "damage_all", amount: 5, hits: 2 }], upgrade: { effects: [{ kind: "damage_all", amount: 7, hits: 2 }] }, motion: "cast",
    canon: "萬劍訣：李逍遙的群體劍術" }),
  card({ id: "li_tiangang", name: "天罡戰氣", owner: O, type: "skill", target: "self", rarity: "uncommon", cost: 1,
    effects: [{ kind: "strength", amount: 2 }], upgrade: { effects: [{ kind: "strength", amount: 3 }] }, canon: "天罡戰氣：提升攻擊" }),
  card({ id: "li_swordqi", name: "劍氣縱橫", owner: O, type: "attack", target: "enemy", rarity: "uncommon", cost: 2,
    effects: [{ kind: "damage", amount: 13 }, { kind: "apply", status: "vulnerable", amount: 2 }],
    upgrade: { effects: [{ kind: "damage", amount: 17 }, { kind: "apply", status: "vulnerable", amount: 2 }] }, canon: "李逍遙劍法（本作命名）" }),
  card({ id: "li_flyrain", name: "御劍伏魔", owner: O, type: "attack", target: "enemy", rarity: "uncommon", cost: 1,
    effects: [{ kind: "fly_sword", amount: 7 }, { kind: "draw", amount: 1 }], upgrade: { effects: [{ kind: "fly_sword", amount: 10 }, { kind: "draw", amount: 1 }] },
    canon: "御劍術的進階運用" }),
  card({ id: "li_swap", name: "偷天換日", owner: O, type: "skill", target: "enemy", rarity: "uncommon", cost: 1,
    effects: [{ kind: "steal" }, { kind: "draw", amount: 2 }], upgrade: { cost: 0 }, motion: "strike", canon: "飛龍探雲手的變化（本作命名）" }),
  card({ id: "li_tianshi", name: "天師符法", owner: O, type: "spell", target: "enemy", rarity: "uncommon", cost: 1,
    effects: [{ kind: "apply", status: "break", amount: 1 }, { kind: "apply", status: "weak", amount: 2 }],
    upgrade: { effects: [{ kind: "apply", status: "break", amount: 2 }, { kind: "apply", status: "weak", amount: 2 }] }, canon: "天師符法" }),
  card({ id: "li_wine", name: "醉意", owner: O, type: "skill", target: "self", rarity: "uncommon", cost: 0,
    effects: [{ kind: "gain_qi", amount: 2 }, { kind: "self_damage", amount: 4 }], upgrade: { effects: [{ kind: "gain_qi", amount: 2 }, { kind: "self_damage", amount: 2 }] },
    exhaust: true, canon: "酒劍仙的好酒（本作原創）" }),

  // ── 稀有 ──
  card({ id: "li_heavensword", name: "天劍", owner: O, type: "attack", target: "enemy", rarity: "rare", cost: 3,
    effects: [{ kind: "damage", amount: 30 }], upgrade: { effects: [{ kind: "damage", amount: 40 }] }, canon: "天劍：李逍遙的強力劍術" }),
  card({ id: "li_swordgod", name: "劍神", owner: O, type: "attack", target: "all_enemies", element: "earth", rarity: "rare", cost: 2,
    effects: [{ kind: "damage_all", amount: 12 }], upgrade: { effects: [{ kind: "damage_all", amount: 16 }] }, motion: "cast",
    canon: "劍神（雷／土系）：李逍遙的終極劍術" }),
  card({ id: "li_winegod", name: "酒神", owner: O, type: "attack", target: "all_enemies", element: "fire", rarity: "rare", cost: 3,
    effects: [{ kind: "damage_all", amount: 18 }, { kind: "self_damage", amount: 5 }], upgrade: { effects: [{ kind: "damage_all", amount: 24 }, { kind: "self_damage", amount: 5 }] },
    exhaust: true, motion: "cast", canon: "酒神：酒劍仙的絕學" }),

  // ── 合擊 ──
  card({ id: "li_combo", name: "合體氣功", owner: O, type: "combo", target: "all_enemies", rarity: "special", cost: 0,
    effects: [{ kind: "damage_all", amount: 26 }, { kind: "self_damage", amount: 10, percent: true, to: "party" }, { kind: "end_turn" }],
    canon: "合擊：由李逍遙發動時為「合體氣功」" }),
];

import type { CardDef } from "../../core/types";
import { card } from "./helpers";

/**
 * 李逍遙（docs/ARCHETYPES.md，2026-10-09 依原作招式重做）。
 * 原作招式：御劍術、萬劍訣、天師符法、天劍（攻擊敵方全體）、酒神（用全身真氣爆發）、劍神；
 * 天罡戰氣（兵器攻擊威力加倍）、醉仙望月步（兵器攻擊連出兩次）、仙風雲體術；
 * 飛龍探雲手（偷取）、靈葫咒（殘血妖物收進紫金葫蘆煉藥）、冰心訣、金蟬脫殼。合擊為「合體氣功」。
 *
 * 兩條流派：
 * - 蜀山劍仙（shushan）：御劍類累積「劍意」並放飛劍，萬劍訣依劍意加成，天劍一次爆發；天罡戰氣、醉仙望月步是心法。
 *   強：頭目、單場爆發；弱：心法鋪陳前的前幾回合。
 * - 江湖雜學（jianghu）：飛龍探雲手、靈葫咒（收妖煉藥）、天師符法與各系靈符、酒神（剩餘真氣全部爆發）。
 *   強：資源（藥品、銅錢）、彈性；弱：純傷害偏低。
 * 卡牌 id 沿用舊版（存檔相容）。
 */
const O = "li_xiaoyao" as const;
const SS = "shushan";
const JH = "jianghu";
const swordqi = (amount: number) => ({ kind: "stack" as const, key: "swordqi", amount });

export const LI_CARDS: CardDef[] = [
  // ── 起始 ──
  card({ id: "li_strike", name: "劍招", owner: O, type: "attack", target: "enemy", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 6 }], upgrade: { effects: [{ kind: "damage", amount: 9 }] }, canon: "李逍遙的基本劍法" }),
  card({ id: "li_guard", name: "護身", owner: O, type: "skill", target: "self", rarity: "starter", cost: 1,
    effects: [{ kind: "block", amount: 5 }], upgrade: { effects: [{ kind: "block", amount: 8 }] }, canon: "防禦" }),
  card({ id: "li_steal", name: "飛龍探雲手", owner: O, type: "skill", target: "enemy", rarity: "starter", cost: 1, archetype: JH,
    effects: [{ kind: "damage", amount: 3 }, { kind: "steal" }], upgrade: { cost: 0 }, motion: "strike",
    canon: "飛龍探雲手：出自逍遙父母留下的手卷，偷取敵人的物品或金錢" }),
  card({ id: "li_fly", name: "御劍術", owner: O, type: "attack", target: "enemy", rarity: "starter", cost: 1, archetype: SS,
    effects: [{ kind: "damage", amount: 4 }, { kind: "fly_sword", amount: 5 }, swordqi(1)],
    upgrade: { effects: [{ kind: "damage", amount: 5 }, { kind: "fly_sword", amount: 8 }, swordqi(1)] },
    canon: "御劍術：蜀山派入門劍法，十里坡山神廟酒劍仙所傳" }),

  // ── 常見 ──
  card({ id: "li_chain", name: "連環劍", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 1, archetype: SS,
    effects: [{ kind: "damage", amount: 3, hits: 3 }], upgrade: { effects: [{ kind: "damage", amount: 4, hits: 3 }] }, canon: "李逍遙劍法（本作命名）" }),
  card({ id: "li_cloudstep", name: "仙風雲體術", owner: O, type: "skill", target: "self", rarity: "common", cost: 1,
    effects: [{ kind: "block", amount: 5 }, { kind: "draw", amount: 1 }], upgrade: { effects: [{ kind: "block", amount: 7 }, { kind: "draw", amount: 1 }] },
    canon: "仙風雲體術：身法暫時加倍" }),
  card({ id: "li_sneak", name: "趁隙", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 0, archetype: JH,
    effects: [{ kind: "damage", amount: 4 }], upgrade: { effects: [{ kind: "damage", amount: 6 }] }, canon: "客棧小二的機靈（本作原創）" }),
  card({ id: "li_wind_talisman", name: "風靈符", owner: O, type: "spell", target: "enemy", element: "wind", rarity: "common", cost: 1, archetype: JH,
    effects: [{ kind: "damage", amount: 7 }], upgrade: { effects: [{ kind: "damage", amount: 10 }] }, canon: "符咒（原作道具）" }),
  card({ id: "li_thunder_talisman", name: "雷靈符", owner: O, type: "spell", target: "enemy", element: "thunder", rarity: "common", cost: 1, archetype: JH,
    effects: [{ kind: "damage", amount: 7 }], upgrade: { effects: [{ kind: "damage", amount: 10 }] }, canon: "符咒（原作道具）" }),
  card({ id: "li_fire_talisman", name: "火靈符", owner: O, type: "spell", target: "enemy", element: "fire", rarity: "common", cost: 1, archetype: JH,
    effects: [{ kind: "damage", amount: 7 }], upgrade: { effects: [{ kind: "damage", amount: 10 }] }, canon: "符咒（原作道具）" }),
  card({ id: "li_earth_talisman", name: "土靈符", owner: O, type: "spell", target: "enemy", element: "earth", rarity: "common", cost: 1, archetype: JH,
    effects: [{ kind: "damage", amount: 4 }, { kind: "block", amount: 5 }], upgrade: { effects: [{ kind: "damage", amount: 6 }, { kind: "block", amount: 7 }] },
    canon: "符咒（原作道具）" }),
  card({ id: "li_water_talisman", name: "水靈符", owner: O, type: "spell", target: "enemy", element: "water", rarity: "common", cost: 1, archetype: JH,
    effects: [{ kind: "damage", amount: 5 }, { kind: "apply", status: "weak", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 7 }, { kind: "apply", status: "weak", amount: 2 }] }, canon: "符咒（原作道具）" }),
  card({ id: "li_icemind", name: "冰心訣", owner: O, type: "skill", target: "self", rarity: "common", cost: 1,
    effects: [{ kind: "cleanse" }, { kind: "heal", amount: 4 }], upgrade: { effects: [{ kind: "cleanse" }, { kind: "heal", amount: 7 }] },
    canon: "冰心訣：解除麻痺、催眠、瘋魔、咒封" }),

  // ── 少見 ──
  card({ id: "li_flyrain", name: "御劍伏魔", owner: O, type: "attack", target: "enemy", rarity: "uncommon", cost: 1, archetype: SS,
    effects: [{ kind: "fly_sword", amount: 7 }, swordqi(2), { kind: "draw", amount: 1 }],
    upgrade: { effects: [{ kind: "fly_sword", amount: 10 }, swordqi(2), { kind: "draw", amount: 1 }] }, canon: "御劍術的進階運用" }),
  card({ id: "li_myriad", name: "萬劍訣", owner: O, type: "attack", target: "all_enemies", element: "wind", rarity: "uncommon", cost: 2, archetype: SS,
    effects: [{ kind: "damage_all", amount: 4, hits: 2, per: { key: "swordqi", amount: 1 } }],
    upgrade: { effects: [{ kind: "damage_all", amount: 6, hits: 2, per: { key: "swordqi", amount: 1 } }] }, motion: "cast",
    canon: "萬劍訣：劍芒如雨直落，攻擊敵方全體" }),
  card({ id: "li_swordqi", name: "劍氣縱橫", owner: O, type: "attack", target: "enemy", rarity: "uncommon", cost: 2, archetype: SS,
    effects: [{ kind: "damage", amount: 12 }, { kind: "apply", status: "vulnerable", amount: 2 }, swordqi(1)],
    upgrade: { effects: [{ kind: "damage", amount: 16 }, { kind: "apply", status: "vulnerable", amount: 2 }, swordqi(1)] }, canon: "李逍遙劍法（本作命名）" }),
  card({ id: "li_tiangang", name: "天罡戰氣", owner: O, type: "power", target: "none", rarity: "uncommon", cost: 1, archetype: SS, effects: [],
    power: { triggers: [{ on: "turn_start", effects: [{ kind: "strength", amount: 1 }] }] }, upgrade: { cost: 0 },
    canon: "天罡戰氣：一段時間內兵器攻擊威力加倍" }),
  card({ id: "li_moonstep", name: "醉仙望月步", owner: O, type: "power", target: "none", rarity: "uncommon", cost: 2, archetype: SS, effects: [],
    power: { triggers: [{ on: "play", type: "attack", owner: O, every: 2, effects: [{ kind: "damage", amount: 6 }] }] }, upgrade: { cost: 1 },
    canon: "醉仙望月步：一段時間內兵器攻擊可連續出手兩次（酒劍仙的步法）" }),
  card({ id: "li_swap", name: "偷天換日", owner: O, type: "skill", target: "enemy", rarity: "uncommon", cost: 1, archetype: JH,
    effects: [{ kind: "steal" }, { kind: "draw", amount: 2 }], upgrade: { cost: 0 }, motion: "strike", canon: "飛龍探雲手的變化（本作命名）" }),
  card({ id: "li_gourd", name: "靈葫咒", owner: O, type: "spell", target: "enemy", rarity: "uncommon", cost: 1, archetype: JH,
    effects: [{ kind: "damage", amount: 5 }, { kind: "capture", below: 25 }], upgrade: { effects: [{ kind: "damage", amount: 8 }, { kind: "capture", below: 30 }] },
    canon: "靈葫咒：妖物體力低於四分之一時，將其收入紫金葫蘆中煉藥" }),
  card({ id: "li_tianshi", name: "天師符法", owner: O, type: "spell", target: "enemy", rarity: "uncommon", cost: 1, archetype: JH,
    effects: [{ kind: "damage", amount: 8 }, { kind: "apply", status: "break", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 11 }, { kind: "apply", status: "break", amount: 2 }] }, canon: "天師符法：茅山道士用來對付妖怪的符法，攻擊敵方單人" }),
  card({ id: "li_wine", name: "醉意", owner: O, type: "skill", target: "self", rarity: "uncommon", cost: 0, archetype: JH,
    effects: [{ kind: "gain_qi", amount: 2 }, { kind: "self_damage", amount: 4 }], upgrade: { effects: [{ kind: "gain_qi", amount: 2 }, { kind: "self_damage", amount: 2 }] },
    exhaust: true, canon: "酒劍仙的好酒（本作原創）" }),
  card({ id: "li_escape", name: "金蟬脫殼", owner: O, type: "skill", target: "self", rarity: "uncommon", cost: 1, archetype: JH,
    effects: [{ kind: "block", amount: 12 }, { kind: "draw", amount: 1 }], upgrade: { effects: [{ kind: "block", amount: 16 }, { kind: "draw", amount: 1 }] },
    retain: true, canon: "金蟬脫殼：戰鬥中脫身（本作改為閃避護身）" }),

  // ── 稀有 ──
  card({ id: "li_heavensword", name: "天劍", owner: O, type: "attack", target: "all_enemies", rarity: "rare", cost: 3, archetype: SS,
    effects: [{ kind: "damage_all", amount: 14, per: { key: "swordqi", amount: 3, consume: true } }], upgrade: { cost: 2 },
    canon: "天劍：人劍合一，身化利劍，攻擊敵方全體" }),
  card({ id: "li_swordgod", name: "劍神", owner: O, type: "attack", target: "all_enemies", element: "earth", rarity: "rare", cost: 2, archetype: SS,
    effects: [{ kind: "damage_all", amount: 5, hits: 3 }, swordqi(2)], upgrade: { effects: [{ kind: "damage_all", amount: 7, hits: 3 }, swordqi(2)] }, motion: "cast",
    canon: "劍神：召喚劍神，萬劍齊飛" }),
  card({ id: "li_winegod", name: "酒神", owner: O, type: "attack", target: "all_enemies", element: "fire", rarity: "rare", cost: 0, archetype: JH,
    effects: [{ kind: "damage_all", amount: 4, per: { key: "qi", amount: 7, consume: true } }],
    upgrade: { effects: [{ kind: "damage_all", amount: 6, per: { key: "qi", amount: 9, consume: true } }] },
    exhaust: true, motion: "cast", canon: "酒神：召喚酒神，用全身真氣爆發攻擊敵人" }),

  // ── 合擊 ──
  card({ id: "li_combo", name: "合體氣功", owner: O, type: "combo", target: "all_enemies", rarity: "special", cost: 0,
    effects: [{ kind: "damage_all", amount: 26 }, { kind: "self_damage", amount: 10, percent: true, to: "party" }, { kind: "end_turn" }],
    canon: "合擊：由李逍遙發動時為「合體氣功」" }),
];

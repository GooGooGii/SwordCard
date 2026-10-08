import type { CardDef } from "../../core/types";
import { card } from "./helpers";

/**
 * 阿奴（docs/ARCHETYPES.md，2026-10-09 依原作招式重做）——苗疆巫術，蠱、醫、巫三術，**不是純毒師**。
 * 原作招式：靈血咒（解除異常）、御蜂術（笛音指揮毒蜂，攻擊敵全）、三屍蠱、鬼降（敵單體瘋魔＝本作「混亂」）、
 * 贖魂（復活）、炎殺咒、元靈歸心術、奪魂（吸取魂魄，中者立斃）、萬蟻蝕象、爆炸蠱（用蠱作爆炸引信）、萬蠱蝕天（放蠱攻擊敵全）。
 * 兵器：苗刀、鬼牙刀（勾魂刀）、鬼頭杖、冥蛇杖、巫月神刀。合擊為「天女散花」。第七章才入隊。
 *
 * 兩條流派：
 * - 苗疆蠱毒（gudu）：養蠱、疊毒，爆炸蠱把毒一次引爆。強：血厚的頭目、長戰；弱：速戰。
 * - 巫術攝魂（wushu）：鬼降讓敵人混亂、殘血的奪魂斬殺、靈血咒與贖魂當巫醫。強：多敵、精英；弱：頭目（不吃控場與斬殺）。
 * 卡牌 id 沿用舊版（存檔相容）。
 */
const O = "anu" as const;
const GU = "gudu";
const WU = "wushu";

export const ANU_CARDS: CardDef[] = [
  // ── 起始（第七章入隊） ──
  card({ id: "anu_blade", name: "苗刀", owner: O, type: "attack", target: "enemy", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 7 }], upgrade: { effects: [{ kind: "damage", amount: 10 }] }, canon: "苗刀：苗族戰士所慣用的佩刀" }),
  card({ id: "anu_guard", name: "銀飾護身", owner: O, type: "skill", target: "self", rarity: "starter", cost: 1,
    effects: [{ kind: "block", amount: 6 }], upgrade: { effects: [{ kind: "block", amount: 9 }] }, canon: "苗族銀飾（本作命名）" }),
  card({ id: "anu_gu", name: "放蠱", owner: O, type: "skill", target: "none", rarity: "starter", cost: 1, archetype: GU,
    effects: [{ kind: "summon_gu", amount: 1 }, { kind: "draw", amount: 1 }], upgrade: { effects: [{ kind: "summon_gu", amount: 2 }, { kind: "draw", amount: 1 }] },
    motion: "cast", canon: "蠱術：養蠱放蠱" }),
  card({ id: "anu_medicine", name: "靈血咒", owner: O, type: "skill", target: "ally", rarity: "starter", cost: 1, archetype: WU,
    effects: [{ kind: "heal", amount: 6, to: "target" }, { kind: "cleanse", to: "target" }],
    upgrade: { effects: [{ kind: "heal", amount: 9, to: "target" }, { kind: "cleanse", to: "target" }] }, motion: "cast", canon: "靈血咒：解除異常狀態（阿奴初登場即會）" }),

  // ── 常見 ──
  card({ id: "anu_poisonblade", name: "三屍蠱", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 1, archetype: GU,
    effects: [{ kind: "damage", amount: 4 }, { kind: "apply", status: "poison", amount: 4 }],
    upgrade: { effects: [{ kind: "damage", amount: 5 }, { kind: "apply", status: "poison", amount: 6 }] }, canon: "三屍蠱：下蠱攻擊敵單體" }),
  card({ id: "anu_swarm", name: "御蜂術", owner: O, type: "spell", target: "all_enemies", rarity: "common", cost: 1, archetype: GU,
    effects: [{ kind: "damage_all", amount: 2 }, { kind: "apply", status: "poison", amount: 2, to: "all_enemies" }],
    upgrade: { effects: [{ kind: "damage_all", amount: 3 }, { kind: "apply", status: "poison", amount: 3, to: "all_enemies" }] }, motion: "cast",
    canon: "御蜂術：以笛音指揮毒蜂攻擊敵全體" }),
  card({ id: "anu_silver", name: "銀蠶絲", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 0, archetype: GU,
    effects: [{ kind: "damage", amount: 3 }, { kind: "summon_gu", amount: 1 }], upgrade: { effects: [{ kind: "damage", amount: 5 }, { kind: "summon_gu", amount: 1 }] },
    canon: "蠶蠱（本作命名）" }),
  card({ id: "anu_exorcise", name: "炎殺咒", owner: O, type: "spell", target: "enemy", element: "fire", rarity: "common", cost: 1, archetype: WU,
    effects: [{ kind: "damage", amount: 9 }, { kind: "apply", status: "weak", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 12 }, { kind: "apply", status: "weak", amount: 1 }] }, canon: "炎殺咒：火系高級法術，攻擊敵單體" }),
  card({ id: "anu_soul", name: "攝魂", owner: O, type: "spell", target: "enemy", element: "water", rarity: "common", cost: 1, archetype: WU,
    effects: [{ kind: "apply", status: "weak", amount: 2 }, { kind: "apply", status: "vulnerable", amount: 2 }],
    upgrade: { effects: [{ kind: "apply", status: "weak", amount: 3 }, { kind: "apply", status: "vulnerable", amount: 3 }] }, canon: "攝魂：苗疆巫術" }),
  card({ id: "anu_dance", name: "苗疆祭舞", owner: O, type: "skill", target: "party", rarity: "common", cost: 1,
    effects: [{ kind: "block", amount: 4, to: "party" }], upgrade: { effects: [{ kind: "block", amount: 6, to: "party" }] }, motion: "cast",
    canon: "苗族祭典的舞蹈（本作原創）" }),

  // ── 少見 ──
  card({ id: "anu_goldsilk", name: "金蠶蠱", owner: O, type: "skill", target: "none", rarity: "uncommon", cost: 2, archetype: GU,
    effects: [{ kind: "summon_gu", amount: 3 }], upgrade: { effects: [{ kind: "summon_gu", amount: 3 }, { kind: "draw", amount: 1 }] }, motion: "cast",
    canon: "金蠶王（原作道具）" }),
  card({ id: "anu_bloodgu", name: "血蠱", owner: O, type: "spell", target: "enemy", rarity: "uncommon", cost: 1, archetype: GU,
    effects: [{ kind: "apply", status: "poison", amount: 7 }, { kind: "self_damage", amount: 3 }],
    upgrade: { effects: [{ kind: "apply", status: "poison", amount: 10 }, { kind: "self_damage", amount: 3 }] }, canon: "以血養蠱（本作命名）" }),
  card({ id: "anu_ants", name: "萬蟻蝕象", owner: O, type: "spell", target: "enemy", rarity: "uncommon", cost: 1, archetype: GU,
    effects: [{ kind: "apply", status: "poison", amount: 9 }], upgrade: { effects: [{ kind: "apply", status: "poison", amount: 13 }] }, motion: "cast",
    canon: "萬蟻蝕象：以食人毒蟻攻擊敵單體（原作 30 級）" }),
  card({ id: "anu_bomb", name: "爆炸蠱", owner: O, type: "spell", target: "enemy", element: "fire", rarity: "uncommon", cost: 1, archetype: GU,
    effects: [{ kind: "detonate", multiplier: 2 }], upgrade: { effects: [{ kind: "detonate", multiplier: 3 }] }, motion: "cast",
    canon: "爆炸蠱：用蠱作為爆炸引信攻擊敵單體（原作 33 級）" }),
  card({ id: "anu_gumother", name: "萬蠱歸宗", owner: O, type: "power", target: "none", rarity: "uncommon", cost: 1, archetype: GU, effects: [],
    power: { triggers: [{ on: "poison_tick", target: "source", effects: [{ kind: "damage", amount: 2 }] }] },
    upgrade: { cost: 0 }, canon: "苗疆蠱術的心法（本作命名）" }),
  card({ id: "anu_xuanming", name: "鬼牙刀", owner: O, type: "attack", target: "enemy", rarity: "uncommon", cost: 2, archetype: GU,
    effects: [{ kind: "damage", amount: 13 }, { kind: "apply", status: "poison", amount: 3 }],
    upgrade: { effects: [{ kind: "damage", amount: 17 }, { kind: "apply", status: "poison", amount: 4 }] }, canon: "鬼牙刀：苗刀的一種，刀尖倒鉤，又稱「勾魂刀」" }),
  card({ id: "anu_ghostward", name: "鬼降", owner: O, type: "spell", target: "enemy", rarity: "uncommon", cost: 1, archetype: WU,
    effects: [{ kind: "apply", status: "confuse", amount: 2 }, { kind: "apply", status: "weak", amount: 1 }],
    upgrade: { effects: [{ kind: "apply", status: "confuse", amount: 3 }, { kind: "apply", status: "weak", amount: 2 }] },
    canon: "鬼降：使敵單體瘋魔（原作五回合；本作的「混亂」，攻擊可能打到自己人）" }),
  card({ id: "anu_souldrain", name: "奪魂", owner: O, type: "spell", target: "enemy", rarity: "uncommon", cost: 2, archetype: WU,
    effects: [{ kind: "execute", below: 30, fallback: 8 }], upgrade: { effects: [{ kind: "execute", below: 40, fallback: 10 }] },
    canon: "奪魂：吸取魂魄，中者立斃（本作：非頭目且殘血才有效）" }),
  card({ id: "anu_soulhook", name: "勾魂攝魄", owner: O, type: "power", target: "none", rarity: "uncommon", cost: 1, archetype: WU, effects: [],
    power: { triggers: [{ on: "kill", effects: [{ kind: "heal", amount: 3, to: "party" }, { kind: "draw", amount: 1 }] }] },
    upgrade: { cost: 0 }, canon: "攝魂之術的心法（本作命名）" }),
  card({ id: "anu_soulcall", name: "贖魂", owner: O, type: "skill", target: "ally", rarity: "uncommon", cost: 2, archetype: WU,
    effects: [{ kind: "revive", amount: 20 }], upgrade: { effects: [{ kind: "revive", amount: 28 }] }, exhaust: true, motion: "cast",
    canon: "贖魂：復活（神木林救醒逍遙所用）" }),
  card({ id: "anu_snakestaff", name: "冥蛇杖", owner: O, type: "spell", target: "enemy", element: "earth", rarity: "uncommon", cost: 1, archetype: WU,
    effects: [{ kind: "damage", amount: 6 }, { kind: "apply", status: "break", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 9 }, { kind: "apply", status: "break", amount: 1 }] }, canon: "冥蛇杖：來自冥界的魔杖，號令群邪" }),

  // ── 稀有 ──
  card({ id: "anu_myriadgu", name: "萬蠱蝕天", owner: O, type: "spell", target: "all_enemies", rarity: "rare", cost: 2, archetype: GU,
    effects: [{ kind: "damage_all", amount: 5 }, { kind: "apply", status: "poison", amount: 7, to: "all_enemies" }],
    upgrade: { effects: [{ kind: "damage_all", amount: 7 }, { kind: "apply", status: "poison", amount: 10, to: "all_enemies" }] }, exhaust: true,
    canon: "萬蠱蝕天：放蠱攻擊敵方全體（原作 35 級）" }),
  card({ id: "anu_moonblade", name: "巫月神刀", owner: O, type: "attack", target: "enemy", rarity: "rare", cost: 3,
    effects: [{ kind: "damage", amount: 26 }, { kind: "summon_gu", amount: 2 }], upgrade: { effects: [{ kind: "damage", amount: 34 }, { kind: "summon_gu", amount: 2 }] },
    canon: "巫月神刀：苗族拜月教鎮教之寶" }),
  card({ id: "anu_grandma", name: "聖姑真傳", owner: O, type: "skill", target: "party", rarity: "rare", cost: 2, archetype: WU,
    effects: [{ kind: "heal", amount: 8, to: "party" }, { kind: "cleanse", to: "party" }],
    upgrade: { effects: [{ kind: "heal", amount: 12, to: "party" }, { kind: "cleanse", to: "party" }] }, exhaust: true, motion: "cast",
    canon: "白苗聖姑（阿奴的師父）的巫醫之術" }),

  // ── 合擊 ──
  card({ id: "anu_combo", name: "天女散花", owner: O, type: "combo", target: "all_enemies", rarity: "special", cost: 0,
    effects: [{ kind: "damage_all", amount: 18 }, { kind: "apply", status: "poison", amount: 6, to: "all_enemies" }, { kind: "self_damage", amount: 10, percent: true, to: "party" }, { kind: "end_turn" }],
    canon: "合擊：由阿奴發動時為「天女散花」" }),
];

/** 巫后：只在第七章「十年前的南詔」臨時入隊，帶自己的小牌組（使用者指示暫不重做）。 */
const W = "wuhou" as const;

export const WUHOU_CARDS: CardDef[] = [
  card({ id: "wuhou_staff", name: "天蛇杖", owner: W, type: "attack", target: "enemy", element: "water", rarity: "special", cost: 1,
    effects: [{ kind: "damage", amount: 10 }], canon: "天蛇杖：限女媧後人使用" }),
  card({ id: "wuhou_ward", name: "水月庇佑", owner: W, type: "skill", target: "party", element: "water", rarity: "special", cost: 1,
    effects: [{ kind: "block", amount: 7, to: "party" }], canon: "巫后守護南詔（本作命名）" }),
  card({ id: "wuhou_seal", name: "封印咒", owner: W, type: "spell", target: "enemy", element: "earth", rarity: "special", cost: 1,
    effects: [{ kind: "damage", amount: 6 }, { kind: "apply", status: "break", amount: 2 }], canon: "巫后封印水魔獸" }),
  card({ id: "wuhou_nuwa", name: "女媧神咒", owner: W, type: "spell", target: "all_enemies", element: "thunder", rarity: "special", cost: 2,
    effects: [{ kind: "damage_all", amount: 16 }], canon: "女媧族的神術（本作命名）" }),
  card({ id: "wuhou_mercy", name: "慈母心", owner: W, type: "skill", target: "ally", rarity: "special", cost: 1,
    effects: [{ kind: "heal", amount: 12, to: "target" }], motion: "cast", canon: "巫后（林青兒）對靈兒的母愛（本作原創）" }),
  card({ id: "wuhou_combo", name: "女媧之怒", owner: W, type: "combo", target: "all_enemies", rarity: "special", cost: 0,
    effects: [{ kind: "damage_all", amount: 28 }, { kind: "self_damage", amount: 10, percent: true, to: "party" }, { kind: "end_turn" }],
    canon: "合擊：由巫后發動（本作命名；原名與阿奴的爆炸蠱重複，改名）" }),
];

import type { CardDef } from "../../core/types";
import { card } from "./helpers";

/**
 * 阿奴：苗疆巫術的引擎型角色——蠱術、驅鬼、攝魂、巫醫，**不是純毒師**（REDESIGN §4.3）。
 * 正史：南詔白苗聖姑之孫女；兵器苗刀→玄冥寶刀→巫月神刀，亦用冥蛇杖。合擊為「天女散花」。
 * 第七章才入隊，起始牌組比照當時的逍遙（REDESIGN §2.2）。
 */
const O = "anu" as const;

export const ANU_CARDS: CardDef[] = [
  // ── 起始（第七章入隊，含少見牌） ──
  card({ id: "anu_blade", name: "苗刀", owner: O, type: "attack", target: "enemy", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 7 }], upgrade: { effects: [{ kind: "damage", amount: 10 }] }, canon: "阿奴的苗刀" }),
  card({ id: "anu_guard", name: "銀飾護身", owner: O, type: "skill", target: "self", rarity: "starter", cost: 1,
    effects: [{ kind: "block", amount: 6 }], upgrade: { effects: [{ kind: "block", amount: 9 }] }, canon: "苗族銀飾（本作命名）" }),
  card({ id: "anu_gu", name: "放蠱", owner: O, type: "skill", target: "none", rarity: "starter", cost: 1,
    effects: [{ kind: "summon_gu", amount: 1 }, { kind: "draw", amount: 1 }], upgrade: { effects: [{ kind: "summon_gu", amount: 2 }, { kind: "draw", amount: 1 }] },
    motion: "cast", canon: "蠱術：養蠱放蠱" }),
  card({ id: "anu_medicine", name: "巫醫", owner: O, type: "skill", target: "ally", rarity: "starter", cost: 1,
    effects: [{ kind: "heal", amount: 6, to: "target" }, { kind: "cleanse", to: "target" }],
    upgrade: { effects: [{ kind: "heal", amount: 9, to: "target" }, { kind: "cleanse", to: "target" }] }, motion: "cast", canon: "苗疆巫醫" }),

  // ── 常見 ──
  card({ id: "anu_poisonblade", name: "淬毒刀", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 4 }, { kind: "apply", status: "poison", amount: 3 }],
    upgrade: { effects: [{ kind: "damage", amount: 5 }, { kind: "apply", status: "poison", amount: 5 }] }, canon: "苗疆毒術" }),
  card({ id: "anu_exorcise", name: "驅鬼符", owner: O, type: "spell", target: "enemy", element: "fire", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 8 }, { kind: "apply", status: "weak", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 11 }, { kind: "apply", status: "weak", amount: 1 }] }, canon: "驅鬼：苗疆巫術" }),
  card({ id: "anu_soul", name: "攝魂", owner: O, type: "spell", target: "enemy", element: "water", rarity: "common", cost: 1,
    effects: [{ kind: "apply", status: "weak", amount: 2 }, { kind: "apply", status: "vulnerable", amount: 2 }],
    upgrade: { effects: [{ kind: "apply", status: "weak", amount: 3 }, { kind: "apply", status: "vulnerable", amount: 3 }] }, canon: "攝魂：苗疆巫術" }),
  card({ id: "anu_swarm", name: "萬蟲噬", owner: O, type: "spell", target: "all_enemies", rarity: "common", cost: 1,
    effects: [{ kind: "apply", status: "poison", amount: 3, to: "all_enemies" }],
    upgrade: { effects: [{ kind: "apply", status: "poison", amount: 4, to: "all_enemies" }] }, canon: "蠱術（本作命名）" }),
  card({ id: "anu_dance", name: "苗疆祭舞", owner: O, type: "skill", target: "party", rarity: "common", cost: 1,
    effects: [{ kind: "block", amount: 4, to: "party" }], upgrade: { effects: [{ kind: "block", amount: 6, to: "party" }] }, motion: "cast",
    canon: "苗族祭典的舞蹈（本作原創）" }),
  card({ id: "anu_silver", name: "銀蠶絲", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 0,
    effects: [{ kind: "damage", amount: 3 }, { kind: "summon_gu", amount: 1 }], upgrade: { effects: [{ kind: "damage", amount: 5 }, { kind: "summon_gu", amount: 1 }] },
    canon: "蠶蠱（本作命名）" }),

  // ── 少見 ──
  card({ id: "anu_goldsilk", name: "金蠶蠱", owner: O, type: "skill", target: "none", rarity: "uncommon", cost: 2,
    effects: [{ kind: "summon_gu", amount: 3 }], upgrade: { effects: [{ kind: "summon_gu", amount: 3 }, { kind: "draw", amount: 1 }] }, motion: "cast",
    canon: "金蠶王（正史道具）" }),
  card({ id: "anu_bloodgu", name: "血蠱", owner: O, type: "spell", target: "enemy", rarity: "uncommon", cost: 1,
    effects: [{ kind: "apply", status: "poison", amount: 7 }, { kind: "self_damage", amount: 3 }],
    upgrade: { effects: [{ kind: "apply", status: "poison", amount: 10 }, { kind: "self_damage", amount: 3 }] }, canon: "以血養蠱（本作命名）" }),
  card({ id: "anu_xuanming", name: "玄冥寶刀", owner: O, type: "attack", target: "enemy", element: "water", rarity: "uncommon", cost: 2,
    effects: [{ kind: "damage", amount: 15 }, { kind: "apply", status: "poison", amount: 3 }],
    upgrade: { effects: [{ kind: "damage", amount: 19 }, { kind: "apply", status: "poison", amount: 4 }] }, canon: "玄冥寶刀（試煉窟所得）" }),
  card({ id: "anu_ghostward", name: "鬼降", owner: O, type: "spell", target: "all_enemies", rarity: "uncommon", cost: 2,
    effects: [{ kind: "apply", status: "weak", amount: 2, to: "all_enemies" }, { kind: "apply", status: "vulnerable", amount: 1, to: "all_enemies" }],
    upgrade: { effects: [{ kind: "apply", status: "weak", amount: 3, to: "all_enemies" }, { kind: "apply", status: "vulnerable", amount: 2, to: "all_enemies" }] },
    canon: "驅鬼、降頭之術（本作命名）" }),
  card({ id: "anu_soulcall", name: "招魂", owner: O, type: "skill", target: "ally", rarity: "uncommon", cost: 2,
    effects: [{ kind: "revive", amount: 18 }], upgrade: { effects: [{ kind: "revive", amount: 26 }] }, exhaust: true, motion: "cast",
    canon: "苗疆招魂之術" }),
  card({ id: "anu_snakestaff", name: "冥蛇杖", owner: O, type: "spell", target: "enemy", element: "earth", rarity: "uncommon", cost: 1,
    effects: [{ kind: "damage", amount: 6 }, { kind: "apply", status: "break", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 9 }, { kind: "apply", status: "break", amount: 1 }] }, canon: "冥蛇杖：阿奴的杖" }),

  // ── 稀有 ──
  card({ id: "anu_moonblade", name: "巫月神刀", owner: O, type: "attack", target: "enemy", rarity: "rare", cost: 3,
    effects: [{ kind: "damage", amount: 26 }, { kind: "summon_gu", amount: 2 }], upgrade: { effects: [{ kind: "damage", amount: 34 }, { kind: "summon_gu", amount: 2 }] },
    canon: "巫月神刀：阿奴的終極兵器" }),
  card({ id: "anu_myriadgu", name: "萬蠱蝕天", owner: O, type: "spell", target: "all_enemies", rarity: "rare", cost: 2,
    effects: [{ kind: "apply", status: "poison", amount: 8, to: "all_enemies" }],
    upgrade: { effects: [{ kind: "apply", status: "poison", amount: 11, to: "all_enemies" }] }, exhaust: true, canon: "蠱術的極致（本作命名）" }),
  card({ id: "anu_grandma", name: "聖姑真傳", owner: O, type: "skill", target: "party", rarity: "rare", cost: 2,
    effects: [{ kind: "heal", amount: 8, to: "party" }, { kind: "cleanse", to: "party" }],
    upgrade: { effects: [{ kind: "heal", amount: 12, to: "party" }, { kind: "cleanse", to: "party" }] }, exhaust: true, motion: "cast",
    canon: "白苗聖姑（阿奴的祖母）的巫術" }),

  // ── 合擊 ──
  card({ id: "anu_combo", name: "天女散花", owner: O, type: "combo", target: "all_enemies", rarity: "special", cost: 0,
    effects: [{ kind: "damage_all", amount: 18 }, { kind: "apply", status: "poison", amount: 6, to: "all_enemies" }, { kind: "self_damage", amount: 10, percent: true, to: "party" }, { kind: "end_turn" }],
    canon: "合擊：由阿奴發動時為「天女散花」" }),
];

/** 巫后：只在第七章「十年前的南詔」臨時入隊，帶自己的小牌組。 */
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
  card({ id: "wuhou_combo", name: "爆炸蠱", owner: W, type: "combo", target: "all_enemies", rarity: "special", cost: 0,
    effects: [{ kind: "damage_all", amount: 28 }, { kind: "self_damage", amount: 10, percent: true, to: "party" }, { kind: "end_turn" }],
    canon: "合擊：由巫后發動時為「爆炸蠱」" }),
];

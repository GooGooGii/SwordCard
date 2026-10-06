import type { CardDef } from "../../core/types";
import { card } from "./helpers";

/**
 * 趙靈兒：五靈仙術主力（接連鎖）、治療、慢熱後期爆發（REDESIGN §4.3）。
 * 正史：一開始就會風、雷、冰、炎、土五咒；五靈各系有三階法術；觀音咒、還魂咒、夢蛇（人蛇真身）。
 * 屬性對照：冰→水、炎→火（REDESIGN §4.2）。
 */
const O = "zhao_linger" as const;

export const LINGER_CARDS: CardDef[] = [
  // ── 起始：五咒＋觀音咒＋護身 ──
  card({ id: "ling_wind", name: "風咒", owner: O, type: "spell", target: "enemy", element: "wind", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 6 }], upgrade: { effects: [{ kind: "damage", amount: 9 }] }, canon: "風咒：風系第一階" }),
  card({ id: "ling_thunder", name: "雷咒", owner: O, type: "spell", target: "enemy", element: "thunder", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 6 }], upgrade: { effects: [{ kind: "damage", amount: 9 }] }, canon: "雷咒：雷系第一階" }),
  card({ id: "ling_ice", name: "冰咒", owner: O, type: "spell", target: "enemy", element: "water", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 4 }, { kind: "apply", status: "weak", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 6 }, { kind: "apply", status: "weak", amount: 2 }] }, canon: "冰咒：冰系第一階（本作歸為水）" }),
  card({ id: "ling_flame", name: "炎咒", owner: O, type: "spell", target: "enemy", element: "fire", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 7 }], upgrade: { effects: [{ kind: "damage", amount: 10 }] }, canon: "炎咒：火系第一階" }),
  card({ id: "ling_earth", name: "土咒", owner: O, type: "spell", target: "enemy", element: "earth", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 3 }, { kind: "block", amount: 4 }], upgrade: { effects: [{ kind: "damage", amount: 5 }, { kind: "block", amount: 6 }] },
    canon: "土咒：土系第一階" }),
  card({ id: "ling_mercy", name: "觀音咒", owner: O, type: "skill", target: "ally", rarity: "starter", cost: 1,
    effects: [{ kind: "heal", amount: 7, to: "target" }], upgrade: { effects: [{ kind: "heal", amount: 10, to: "target" }] }, motion: "cast",
    canon: "觀音咒：治療法術" }),
  card({ id: "ling_guard", name: "靈護", owner: O, type: "skill", target: "ally", rarity: "starter", cost: 1,
    effects: [{ kind: "block", amount: 6, to: "target" }], upgrade: { effects: [{ kind: "block", amount: 9, to: "target" }] }, motion: "cast",
    canon: "靈族的護身之術（本作命名）" }),

  // ── 常見：五靈第二階 ──
  card({ id: "ling_whirl", name: "旋風咒", owner: O, type: "spell", target: "all_enemies", element: "wind", rarity: "common", cost: 1,
    effects: [{ kind: "damage_all", amount: 4 }], upgrade: { effects: [{ kind: "damage_all", amount: 6 }] }, canon: "旋風咒：風系第二階" }),
  card({ id: "ling_fivethunder", name: "五雷咒", owner: O, type: "spell", target: "enemy", element: "thunder", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 3, hits: 3 }], upgrade: { effects: [{ kind: "damage", amount: 4, hits: 3 }] }, canon: "五雷咒：雷系第二階" }),
  card({ id: "ling_darkice", name: "玄冰咒", owner: O, type: "spell", target: "enemy", element: "water", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 6 }, { kind: "apply", status: "weak", amount: 2 }],
    upgrade: { effects: [{ kind: "damage", amount: 8 }, { kind: "apply", status: "weak", amount: 3 }] }, canon: "玄冰咒：冰系第二階" }),
  card({ id: "ling_burn", name: "炎殺咒", owner: O, type: "spell", target: "enemy", element: "fire", rarity: "common", cost: 2,
    effects: [{ kind: "damage", amount: 14 }], upgrade: { effects: [{ kind: "damage", amount: 19 }] }, canon: "炎殺咒：火系第二階" }),
  card({ id: "ling_rock", name: "飛岩術", owner: O, type: "spell", target: "enemy", element: "earth", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 5 }, { kind: "block", amount: 5 }], upgrade: { effects: [{ kind: "damage", amount: 7 }, { kind: "block", amount: 7 }] },
    canon: "飛岩術：土系第二階" }),
  card({ id: "ling_focus", name: "凝神", owner: O, type: "skill", target: "none", rarity: "common", cost: 1,
    effects: [{ kind: "draw", amount: 2 }], upgrade: { cost: 0 }, motion: "cast", canon: "靈兒修行的靜心之法（本作原創）" }),
  card({ id: "ling_shield_all", name: "水月護法", owner: O, type: "skill", target: "party", element: "water", rarity: "common", cost: 2,
    effects: [{ kind: "block", amount: 6, to: "party" }], upgrade: { effects: [{ kind: "block", amount: 9, to: "party" }] }, motion: "cast",
    canon: "水月宮的護法之術（本作命名）" }),

  // ── 少見：五靈第三階、還魂咒 ──
  card({ id: "ling_tempest", name: "風捲殘雲", owner: O, type: "spell", target: "all_enemies", element: "wind", rarity: "uncommon", cost: 2,
    effects: [{ kind: "damage_all", amount: 9 }], upgrade: { effects: [{ kind: "damage_all", amount: 12 }] }, canon: "風捲殘雲：風系第三階" }),
  card({ id: "ling_skythunder", name: "天雷破", owner: O, type: "spell", target: "enemy", element: "thunder", rarity: "uncommon", cost: 2,
    effects: [{ kind: "damage", amount: 18 }], upgrade: { effects: [{ kind: "damage", amount: 24 }] }, canon: "天雷破：雷系第三階" }),
  card({ id: "ling_blizzard", name: "風雪冰天", owner: O, type: "spell", target: "all_enemies", element: "water", rarity: "uncommon", cost: 2,
    effects: [{ kind: "damage_all", amount: 6 }, { kind: "apply", status: "weak", amount: 2, to: "all_enemies" }],
    upgrade: { effects: [{ kind: "damage_all", amount: 8 }, { kind: "apply", status: "weak", amount: 2, to: "all_enemies" }] }, canon: "風雪冰天：冰系第三階" }),
  card({ id: "ling_earthfire", name: "地烈火", owner: O, type: "spell", target: "all_enemies", element: "fire", rarity: "uncommon", cost: 2,
    effects: [{ kind: "damage_all", amount: 10 }], upgrade: { effects: [{ kind: "damage_all", amount: 13 }] }, canon: "地烈火：火系第三階" }),
  card({ id: "ling_mountain", name: "泰山壓頂", owner: O, type: "spell", target: "enemy", element: "earth", rarity: "uncommon", cost: 2,
    effects: [{ kind: "damage", amount: 14 }, { kind: "block", amount: 8 }], upgrade: { effects: [{ kind: "damage", amount: 18 }, { kind: "block", amount: 10 }] },
    canon: "泰山壓頂：土系第三階" }),
  card({ id: "ling_revive", name: "還魂咒", owner: O, type: "skill", target: "ally", rarity: "uncommon", cost: 2,
    effects: [{ kind: "revive", amount: 20 }], upgrade: { effects: [{ kind: "revive", amount: 30 }] }, exhaust: true, motion: "cast", canon: "還魂咒：復活法術" }),
  card({ id: "ling_prayer", name: "女媧祈願", owner: O, type: "skill", target: "party", rarity: "uncommon", cost: 2,
    effects: [{ kind: "heal", amount: 6, to: "party" }], upgrade: { effects: [{ kind: "heal", amount: 9, to: "party" }] }, motion: "cast",
    canon: "女媧後裔的祈願（本作命名）" }),

  // ── 稀有：夢蛇與試煉窟五靈神 ──
  card({ id: "ling_dreamsnake", name: "夢蛇", owner: O, type: "skill", target: "self", rarity: "rare", cost: 2,
    effects: [{ kind: "strength", amount: 3 }, { kind: "block", amount: 10 }], upgrade: { effects: [{ kind: "strength", amount: 4 }, { kind: "block", amount: 14 }] },
    exhaust: true, motion: "cast", canon: "夢蛇：靈兒化為人蛇真身（鎖妖塔覺醒）" }),
  card({ id: "ling_thundergod", name: "雷神", owner: O, type: "spell", target: "all_enemies", element: "thunder", rarity: "rare", cost: 3,
    effects: [{ kind: "damage_all", amount: 20 }], upgrade: { effects: [{ kind: "damage_all", amount: 26 }] }, canon: "雷神：試煉窟五靈神像所授" }),
  card({ id: "ling_windgod", name: "風神", owner: O, type: "spell", target: "all_enemies", element: "wind", rarity: "rare", cost: 2,
    effects: [{ kind: "damage_all", amount: 11 }, { kind: "draw", amount: 1 }], upgrade: { effects: [{ kind: "damage_all", amount: 14 }, { kind: "draw", amount: 1 }] },
    canon: "風神：試煉窟五靈神像所授" }),
  card({ id: "ling_snowdemon", name: "雪妖", owner: O, type: "spell", target: "enemy", element: "water", rarity: "rare", cost: 2,
    effects: [{ kind: "damage", amount: 16 }, { kind: "apply", status: "break", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 20 }, { kind: "apply", status: "break", amount: 2 }] }, canon: "雪妖：試煉窟五靈神像所授" }),

  // ── 合擊 ──
  card({ id: "ling_combo", name: "爆炸", owner: O, type: "combo", target: "all_enemies", rarity: "special", cost: 0,
    effects: [{ kind: "damage_all", amount: 22 }, { kind: "apply", status: "vulnerable", amount: 2, to: "all_enemies" }, { kind: "self_damage", amount: 10, percent: true, to: "party" }, { kind: "end_turn" }],
    canon: "合擊：由趙靈兒發動時為「爆炸」" }),
];

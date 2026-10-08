import type { CardDef } from "../../core/types";
import { card } from "./helpers";

/**
 * 趙靈兒（docs/ARCHETYPES.md，2026-10-09 依原作招式重做）。
 * 原作招式：五系咒法各三到四階——風咒／旋風咒／風捲殘雲；雷咒／五雷咒／天雷破／狂雷；冰咒／玄冰咒／風雪冰天；
 * 炎咒／三昧真火／煉獄真火；土咒／飛岩術／地裂天崩／泰山壓頂。回夢（昏睡）、觀音咒、五氣朝元、還魂咒、
 * 冰心訣、淨衣咒、金剛咒（防禦提升）、夢蛇（女媧族變身）。合體：集靈珠召喚風神、雷神、雪妖、火神、山神。
 * 屬性對照：冰→水、炎→火（REDESIGN §4.2）。
 *
 * 兩條流派：
 * - 五靈法術（wuling）：照相生順序出咒法疊連鎖，中高階咒法打全體，五神召喚收尾。強：群戰、打得到弱點；弱：斷鏈、抽牌不順。
 * - 女媧靈族（nuwa）：觀音咒、五氣朝元、還魂咒、金剛咒、回夢控場，夢蛇變身後全面強化。強：長戰、保隊友；弱：輸出慢。
 * 卡牌 id 沿用舊版（存檔相容）。
 */
const O = "zhao_linger" as const;
const WL = "wuling";
const NW = "nuwa";

export const LINGER_CARDS: CardDef[] = [
  // ── 起始：五咒＋觀音咒＋護身 ──
  card({ id: "ling_wind", name: "風咒", owner: O, type: "spell", target: "enemy", element: "wind", rarity: "starter", cost: 1, archetype: WL,
    effects: [{ kind: "damage", amount: 6 }], upgrade: { effects: [{ kind: "damage", amount: 9 }] }, canon: "風咒：風系初級法術，攻擊敵單體" }),
  card({ id: "ling_thunder", name: "雷咒", owner: O, type: "spell", target: "enemy", element: "thunder", rarity: "starter", cost: 1, archetype: WL,
    effects: [{ kind: "damage", amount: 6 }], upgrade: { effects: [{ kind: "damage", amount: 9 }] }, canon: "雷咒：雷系初級法術，攻擊敵單體" }),
  card({ id: "ling_ice", name: "冰咒", owner: O, type: "spell", target: "enemy", element: "water", rarity: "starter", cost: 1, archetype: WL,
    effects: [{ kind: "damage", amount: 4 }, { kind: "apply", status: "weak", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 6 }, { kind: "apply", status: "weak", amount: 2 }] }, canon: "冰咒：冰系初級法術（本作歸為水）" }),
  card({ id: "ling_flame", name: "炎咒", owner: O, type: "spell", target: "enemy", element: "fire", rarity: "starter", cost: 1, archetype: WL,
    effects: [{ kind: "damage", amount: 7 }], upgrade: { effects: [{ kind: "damage", amount: 10 }] }, canon: "炎咒：火系初級法術，攻擊敵單體" }),
  card({ id: "ling_earth", name: "土咒", owner: O, type: "spell", target: "enemy", element: "earth", rarity: "starter", cost: 1, archetype: WL,
    effects: [{ kind: "damage", amount: 3 }, { kind: "block", amount: 4 }], upgrade: { effects: [{ kind: "damage", amount: 5 }, { kind: "block", amount: 6 }] },
    canon: "土咒：土系初級法術，攻擊敵單體" }),
  card({ id: "ling_mercy", name: "觀音咒", owner: O, type: "skill", target: "ally", rarity: "starter", cost: 1, archetype: NW,
    effects: [{ kind: "heal", amount: 7, to: "target" }], upgrade: { effects: [{ kind: "heal", amount: 10, to: "target" }] }, motion: "cast",
    canon: "觀音咒：我方單人回復" }),
  card({ id: "ling_guard", name: "靈護", owner: O, type: "skill", target: "ally", rarity: "starter", cost: 1, archetype: NW,
    effects: [{ kind: "block", amount: 6, to: "target" }], upgrade: { effects: [{ kind: "block", amount: 9, to: "target" }] }, motion: "cast",
    canon: "靈族的護身之術（本作命名）" }),

  // ── 常見：五靈中階 ──
  card({ id: "ling_whirl", name: "旋風咒", owner: O, type: "spell", target: "all_enemies", element: "wind", rarity: "common", cost: 1, archetype: WL,
    effects: [{ kind: "damage_all", amount: 4 }], upgrade: { effects: [{ kind: "damage_all", amount: 6 }] }, canon: "旋風咒：風系中級法術，攻擊敵全體" }),
  card({ id: "ling_fivethunder", name: "五雷咒", owner: O, type: "spell", target: "all_enemies", element: "thunder", rarity: "common", cost: 1, archetype: WL,
    effects: [{ kind: "damage_all", amount: 3, hits: 2 }], upgrade: { effects: [{ kind: "damage_all", amount: 4, hits: 2 }] }, canon: "五雷咒：雷系中級法術，攻擊敵全體" }),
  card({ id: "ling_darkice", name: "玄冰咒", owner: O, type: "spell", target: "all_enemies", element: "water", rarity: "common", cost: 1, archetype: WL,
    effects: [{ kind: "damage_all", amount: 3 }, { kind: "apply", status: "weak", amount: 1, to: "all_enemies" }],
    upgrade: { effects: [{ kind: "damage_all", amount: 5 }, { kind: "apply", status: "weak", amount: 1, to: "all_enemies" }] }, canon: "玄冰咒：冰系中級法術，攻擊敵全體" }),
  card({ id: "ling_burn", name: "三昧真火", owner: O, type: "spell", target: "all_enemies", element: "fire", rarity: "common", cost: 2, archetype: WL,
    effects: [{ kind: "damage_all", amount: 8 }], upgrade: { effects: [{ kind: "damage_all", amount: 11 }] }, canon: "三昧真火：火系中級法術，攻擊敵全體" }),
  card({ id: "ling_rock", name: "飛岩術", owner: O, type: "spell", target: "all_enemies", element: "earth", rarity: "common", cost: 1, archetype: WL,
    effects: [{ kind: "damage_all", amount: 3 }, { kind: "block", amount: 4 }], upgrade: { effects: [{ kind: "damage_all", amount: 5 }, { kind: "block", amount: 5 }] },
    canon: "飛岩術：土系中級法術，攻擊敵全體" }),
  card({ id: "ling_dream", name: "回夢", owner: O, type: "spell", target: "enemy", rarity: "common", cost: 1, archetype: NW,
    effects: [{ kind: "apply", status: "sleep", amount: 2 }], upgrade: { effects: [{ kind: "apply", status: "sleep", amount: 3 }] },
    canon: "回夢：使敵單體昏睡（原作五回合；受到傷害就醒，頭目不受影響）" }),
  card({ id: "ling_focus", name: "凝神", owner: O, type: "skill", target: "none", rarity: "common", cost: 1,
    effects: [{ kind: "draw", amount: 2 }], upgrade: { cost: 0 }, motion: "cast", canon: "靈兒修行的靜心之法（本作原創）" }),
  card({ id: "ling_shield_all", name: "水月護法", owner: O, type: "skill", target: "party", element: "water", rarity: "common", cost: 2, archetype: NW,
    effects: [{ kind: "block", amount: 6, to: "party" }], upgrade: { effects: [{ kind: "block", amount: 9, to: "party" }] }, motion: "cast",
    canon: "水月宮的護法之術（本作命名）" }),

  // ── 少見：五靈高階、靈族法術 ──
  card({ id: "ling_tempest", name: "風捲殘雲", owner: O, type: "spell", target: "all_enemies", element: "wind", rarity: "uncommon", cost: 2, archetype: WL,
    effects: [{ kind: "damage_all", amount: 9 }], upgrade: { effects: [{ kind: "damage_all", amount: 12 }] }, canon: "風捲殘雲：風系高級法術，攻擊敵全體" }),
  card({ id: "ling_skythunder", name: "天雷破", owner: O, type: "spell", target: "enemy", element: "thunder", rarity: "uncommon", cost: 2, archetype: WL,
    effects: [{ kind: "damage", amount: 18 }], upgrade: { effects: [{ kind: "damage", amount: 24 }] }, canon: "天雷破：雷系高級法術，攻擊敵單體" }),
  card({ id: "ling_blizzard", name: "風雪冰天", owner: O, type: "spell", target: "all_enemies", element: "water", rarity: "uncommon", cost: 2, archetype: WL,
    effects: [{ kind: "damage_all", amount: 6 }, { kind: "apply", status: "weak", amount: 2, to: "all_enemies" }],
    upgrade: { effects: [{ kind: "damage_all", amount: 8 }, { kind: "apply", status: "weak", amount: 2, to: "all_enemies" }] }, canon: "風雪冰天：冰系高級法術，攻擊敵全體" }),
  card({ id: "ling_quake", name: "地裂天崩", owner: O, type: "spell", target: "all_enemies", element: "earth", rarity: "uncommon", cost: 2, archetype: WL,
    effects: [{ kind: "damage_all", amount: 7 }, { kind: "block", amount: 7 }], upgrade: { effects: [{ kind: "damage_all", amount: 10 }, { kind: "block", amount: 8 }] },
    canon: "地裂天崩：土系中級法術，攻擊敵全體" }),
  card({ id: "ling_wuling", name: "女媧五靈訣", owner: O, type: "power", target: "none", rarity: "uncommon", cost: 1, archetype: WL, effects: [],
    power: { triggers: [{ on: "play", type: "spell", owner: O, every: 3, effects: [{ kind: "gain_qi", amount: 1 }, { kind: "draw", amount: 1 }] }] },
    upgrade: { cost: 0 }, canon: "女媧後人駕馭五靈之力（本作命名）" }),
  card({ id: "ling_prayer", name: "五氣朝元", owner: O, type: "skill", target: "party", rarity: "uncommon", cost: 2, archetype: NW,
    effects: [{ kind: "heal", amount: 7, to: "party" }], upgrade: { effects: [{ kind: "heal", amount: 10, to: "party" }] }, motion: "cast",
    canon: "五氣朝元：我方全體回復（原作 8 級）" }),
  card({ id: "ling_vajra", name: "金剛咒", owner: O, type: "power", target: "none", rarity: "uncommon", cost: 2, archetype: NW, effects: [{ kind: "block", amount: 5, to: "party" }],
    power: { triggers: [{ on: "turn_start", effects: [{ kind: "block", amount: 3, to: "party" }] }] },
    upgrade: { cost: 1 }, canon: "金剛咒：增加防禦數回合" }),
  card({ id: "ling_revive", name: "還魂咒", owner: O, type: "skill", target: "ally", rarity: "uncommon", cost: 2, archetype: NW,
    effects: [{ kind: "revive", amount: 20 }], upgrade: { effects: [{ kind: "revive", amount: 30 }] }, exhaust: true, motion: "cast",
    canon: "還魂咒：復活（蘇州城外為救逍遙強行施展）" }),
  card({ id: "ling_earthfire", name: "煉獄真火", owner: O, type: "spell", target: "all_enemies", element: "fire", rarity: "uncommon", cost: 3, archetype: WL,
    effects: [{ kind: "damage_all", amount: 15 }], upgrade: { effects: [{ kind: "damage_all", amount: 20 }] }, canon: "煉獄真火：火系高級法術，攻擊敵全體" }),

  // ── 稀有：夢蛇、狂雷、泰山壓頂與五神 ──
  card({ id: "ling_dreamsnake", name: "夢蛇", owner: O, type: "power", target: "none", rarity: "rare", cost: 2, archetype: NW,
    effects: [{ kind: "strength", amount: 2 }, { kind: "block", amount: 10 }],
    power: { triggers: [{ on: "turn_start", effects: [{ kind: "strength", amount: 1 }, { kind: "heal", amount: 3 }] }] },
    upgrade: { effects: [{ kind: "strength", amount: 3 }, { kind: "block", amount: 14 }] }, motion: "cast",
    canon: "夢蛇：女媧族變身魔法，能力大幅提升（鎖妖塔覺醒）" }),
  card({ id: "ling_madthunder", name: "狂雷", owner: O, type: "spell", target: "all_enemies", element: "thunder", rarity: "rare", cost: 3, archetype: WL,
    effects: [{ kind: "damage_all", amount: 8, hits: 2 }], upgrade: { effects: [{ kind: "damage_all", amount: 11, hits: 2 }] }, canon: "狂雷：雷系高級法術，攻擊敵全體" }),
  card({ id: "ling_mountain", name: "泰山壓頂", owner: O, type: "spell", target: "all_enemies", element: "earth", rarity: "rare", cost: 3, archetype: WL,
    effects: [{ kind: "damage_all", amount: 14 }, { kind: "block", amount: 10 }], upgrade: { effects: [{ kind: "damage_all", amount: 18 }, { kind: "block", amount: 12 }] },
    canon: "泰山壓頂：土系高級法術，攻擊敵全體" }),
  card({ id: "ling_thundergod", name: "雷神", owner: O, type: "spell", target: "all_enemies", element: "thunder", rarity: "rare", cost: 3, archetype: WL,
    effects: [{ kind: "damage_all", amount: 20 }], upgrade: { effects: [{ kind: "damage_all", amount: 26 }] }, canon: "雷神：集雷靈珠，召喚雷神施展狂雷" }),
  card({ id: "ling_windgod", name: "風神", owner: O, type: "spell", target: "all_enemies", element: "wind", rarity: "rare", cost: 2, archetype: WL,
    effects: [{ kind: "damage_all", amount: 11 }, { kind: "draw", amount: 1 }], upgrade: { effects: [{ kind: "damage_all", amount: 14 }, { kind: "draw", amount: 1 }] },
    canon: "風神：集風靈珠，召喚風神施展風捲殘雲" }),
  card({ id: "ling_snowdemon", name: "雪妖", owner: O, type: "spell", target: "all_enemies", element: "water", rarity: "rare", cost: 2, archetype: WL,
    effects: [{ kind: "damage_all", amount: 9 }, { kind: "apply", status: "break", amount: 1, to: "all_enemies" }],
    upgrade: { effects: [{ kind: "damage_all", amount: 12 }, { kind: "apply", status: "break", amount: 1, to: "all_enemies" }] }, canon: "雪妖：集水靈珠，召喚雪妖施展風雪冰天" }),

  // ── 合擊 ──
  card({ id: "ling_combo", name: "爆炸", owner: O, type: "combo", target: "all_enemies", rarity: "special", cost: 0,
    effects: [{ kind: "damage_all", amount: 22 }, { kind: "apply", status: "vulnerable", amount: 2, to: "all_enemies" }, { kind: "self_damage", amount: 10, percent: true, to: "party" }, { kind: "end_turn" }],
    canon: "合擊：由趙靈兒發動時為「爆炸」" }),
];

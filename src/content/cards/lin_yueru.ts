import type { CardDef } from "../../core/types";
import { card } from "./helpers";

/**
 * 林月如（docs/ARCHETYPES.md，2026-10-08 依原作招式重做，使用者確認）。
 * 原作招式：凝神歸元、氣劍指、一陽指、銅錢鏢、七訣劍氣、元靈歸心術、乾坤一擲、斬龍訣；
 * 兵器：鞭（原作攻擊全體）、劍、刀（鳳鳴刀）；家傳武學「劍指雙絕」。合擊為「弦月斬」。
 *
 * 兩條流派：
 * - 林家劍指（zhijian）：攻擊累積「指勁」，七訣劍氣、斬龍訣依指勁爆發；凝神歸元撐長戰。強：頭目、長戰；弱：開場爆發的敵人。
 * - 大小姐的錢與鞭（purse）：銅錢鏢、乾坤一擲花銅錢換傷害；鞭多段、全體壓制。強：小怪群、速戰；弱：經濟、單體頭目。
 * 卡牌 id 沿用舊版（存檔相容），名稱與效果改成原作招式。
 */
const O = "lin_yueru" as const;
const ZJ = "zhijian";
const PURSE = "purse";
const zhijin = (amount: number) => ({ kind: "stack" as const, key: "zhijin", amount });

export const YUERU_CARDS: CardDef[] = [
  // ── 起始 ──
  card({ id: "yue_whip", name: "長鞭", owner: O, type: "attack", target: "enemy", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 6 }], upgrade: { effects: [{ kind: "damage", amount: 9 }] }, canon: "林月如的初始兵器：長鞭" }),
  card({ id: "yue_guard", name: "林家架式", owner: O, type: "skill", target: "self", rarity: "starter", cost: 1,
    effects: [{ kind: "block", amount: 5 }], upgrade: { effects: [{ kind: "block", amount: 8 }] }, canon: "林家堡武學（本作命名）" }),
  card({ id: "yue_return", name: "氣劍指", owner: O, type: "attack", target: "all_enemies", rarity: "starter", cost: 1, archetype: ZJ,
    effects: [{ kind: "damage_all", amount: 3 }, zhijin(1)], upgrade: { effects: [{ kind: "damage_all", amount: 5 }, zhijin(1)] },
    canon: "氣劍指：指尖運氣吐出劍芒，攻擊敵方全體（原作初登場即會）" }),

  // ── 常見 ──
  card({ id: "yue_parry", name: "一陽指", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 1, archetype: ZJ,
    effects: [{ kind: "damage", amount: 7 }, zhijin(1)], upgrade: { effects: [{ kind: "damage", amount: 10 }, zhijin(1)] },
    canon: "一陽指：聚勁食指發出強勁光芒，攻擊敵單體（原作 7 級）" }),
  card({ id: "yue_breath", name: "凝神歸元", owner: O, type: "skill", target: "self", rarity: "common", cost: 1, archetype: ZJ,
    effects: [{ kind: "heal", amount: 6 }, zhijin(1)], upgrade: { effects: [{ kind: "heal", amount: 9 }, zhijin(2)] },
    canon: "凝神歸元：我方單人回復（原作初登場即會）" }),
  card({ id: "yue_arena", name: "銅錢鏢", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 0, archetype: PURSE,
    effects: [{ kind: "spend_coins", amount: 15 }, { kind: "damage", amount: 9 }],
    upgrade: { effects: [{ kind: "spend_coins", amount: 15 }, { kind: "damage", amount: 13 }] },
    canon: "銅錢鏢：將金錢當做暗器攻擊敵單體，原作每次花 500 文（原作 9 級）" }),
  card({ id: "yue_double", name: "雙鞭連擊", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 1, archetype: PURSE,
    effects: [{ kind: "damage", amount: 4, hits: 2 }], upgrade: { effects: [{ kind: "damage", amount: 6, hits: 2 }] }, canon: "鞭法（本作命名）" }),
  card({ id: "yue_sweep", name: "橫掃千軍", owner: O, type: "attack", target: "all_enemies", rarity: "common", cost: 1, archetype: PURSE,
    effects: [{ kind: "damage_all", amount: 5 }], upgrade: { effects: [{ kind: "damage_all", amount: 7 }] }, canon: "長鞭橫掃：原作的鞭攻擊敵方全體（本作命名）" }),
  card({ id: "yue_bind", name: "纏鞭", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 4 }, { kind: "apply", status: "vulnerable", amount: 2 }],
    upgrade: { effects: [{ kind: "damage", amount: 6 }, { kind: "apply", status: "vulnerable", amount: 2 }] }, canon: "鞭法（本作命名）" }),
  card({ id: "yue_temper", name: "大小姐脾氣", owner: O, type: "skill", target: "self", rarity: "common", cost: 0,
    effects: [{ kind: "strength", amount: 1 }, { kind: "self_damage", amount: 2 }], upgrade: { effects: [{ kind: "strength", amount: 2 }, { kind: "self_damage", amount: 2 }] },
    canon: "林月如嬌縱的個性（本作原創）" }),

  // ── 少見 ──
  card({ id: "yue_thrust", name: "七訣劍氣", owner: O, type: "attack", target: "all_enemies", rarity: "uncommon", cost: 2, archetype: ZJ,
    effects: [{ kind: "damage_all", amount: 6, per: { key: "zhijin", amount: 2 } }],
    upgrade: { effects: [{ kind: "damage_all", amount: 9, per: { key: "zhijin", amount: 2 } }] },
    canon: "七訣劍氣：以指代劍發出裂地劍氣，攻擊敵全體（原作 13 級）" }),
  card({ id: "yue_jianzhi", name: "劍指雙絕", owner: O, type: "power", target: "none", rarity: "uncommon", cost: 1, archetype: ZJ, effects: [],
    power: { triggers: [{ on: "play", type: "attack", owner: O, effects: [zhijin(1)] }] },
    upgrade: { cost: 0 }, canon: "林家家傳武學「劍指雙絕」，林天南憑此立足江湖" }),
  card({ id: "yue_ninewhip", name: "九節鞭", owner: O, type: "attack", target: "enemy", rarity: "uncommon", cost: 2, archetype: PURSE,
    effects: [{ kind: "damage", amount: 3, hits: 5 }], upgrade: { effects: [{ kind: "damage", amount: 4, hits: 5 }] }, canon: "九節鞭：以鐵節鐵環組成的九節軟鞭" }),
  card({ id: "yue_stormwhip", name: "鞭影如潮", owner: O, type: "attack", target: "all_enemies", rarity: "uncommon", cost: 2, archetype: PURSE,
    effects: [{ kind: "damage_all", amount: 4, hits: 3 }], upgrade: { effects: [{ kind: "damage_all", amount: 5, hits: 3 }] }, canon: "鞭法（本作命名）" }),
  card({ id: "yue_spender", name: "揮金如土", owner: O, type: "power", target: "none", rarity: "uncommon", cost: 1, archetype: PURSE, effects: [],
    power: { triggers: [{ on: "turn_start", effects: [{ kind: "spend_coins", amount: 10 }, { kind: "gain_qi", amount: 1 }] }] },
    upgrade: { cost: 0 }, canon: "林家堡千金大小姐出手闊綽（本作原創）", note: "銅錢不足時仍會獲得真氣。" }),
  card({ id: "yue_yuenu", name: "越女劍", owner: O, type: "attack", target: "enemy", element: "wind", rarity: "uncommon", cost: 1,
    effects: [{ kind: "damage", amount: 9 }, { kind: "draw", amount: 1 }], upgrade: { effects: [{ kind: "damage", amount: 12 }, { kind: "draw", amount: 1 }] },
    canon: "越女劍：靈兒與月如共用的劍" }),
  card({ id: "yue_wall", name: "銅牆鐵壁", owner: O, type: "skill", target: "ally", rarity: "uncommon", cost: 2,
    effects: [{ kind: "block", amount: 14, to: "target" }], upgrade: { effects: [{ kind: "block", amount: 18, to: "target" }] },
    canon: "替同伴擋下攻擊（本作命名）" }),
  card({ id: "yue_rally", name: "林家堡號令", owner: O, type: "skill", target: "party", rarity: "uncommon", cost: 1,
    effects: [{ kind: "strength", amount: 1, to: "party" }], upgrade: { effects: [{ kind: "strength", amount: 1, to: "party" }, { kind: "draw", amount: 1 }] },
    exhaust: true, canon: "南武林盟主之女的號召（本作原創）" }),

  // ── 稀有 ──
  card({ id: "yue_zhanlong", name: "斬龍訣", owner: O, type: "attack", target: "all_enemies", rarity: "rare", cost: 3, archetype: ZJ,
    effects: [{ kind: "damage_all", amount: 14, per: { key: "zhijin", amount: 4, consume: true } }],
    upgrade: { cost: 2 }, canon: "斬龍訣：以雄渾氣勁橫掃群魔，攻擊敵全體；月如最強的招式（原作 20 級）" }),
  card({ id: "yue_vow", name: "元靈歸心術", owner: O, type: "skill", target: "ally", rarity: "rare", cost: 2, archetype: ZJ,
    effects: [{ kind: "heal", amount: 18, to: "target" }, zhijin(2)], upgrade: { effects: [{ kind: "heal", amount: 24, to: "target" }, zhijin(3)] }, exhaust: true,
    canon: "元靈歸心術：我方單人大幅回復（原作 15 級）" }),
  card({ id: "yue_qiankun", name: "乾坤一擲", owner: O, type: "attack", target: "all_enemies", rarity: "rare", cost: 1, archetype: PURSE,
    effects: [{ kind: "spend_coins", amount: 60 }, { kind: "damage_all", amount: 20 }],
    upgrade: { effects: [{ kind: "spend_coins", amount: 60 }, { kind: "damage_all", amount: 28 }] },
    canon: "乾坤一擲：使用金錢鏢攻擊敵全體，原作每次花 5000 文（原作 16 級）" }),
  card({ id: "yue_goldsnake", name: "金蛇鞭", owner: O, type: "attack", target: "all_enemies", element: "fire", rarity: "rare", cost: 2, archetype: PURSE,
    effects: [{ kind: "damage_all", amount: 9, hits: 2 }], upgrade: { effects: [{ kind: "damage_all", amount: 12, hits: 2 }] },
    canon: "金蛇鞭：以蛇皮絞以金絲編成的九尺軟鞭，攻擊敵方全體" }),
  card({ id: "yue_phoenix", name: "鳳鳴刀", owner: O, type: "attack", target: "enemy", element: "fire", rarity: "rare", cost: 2,
    effects: [{ kind: "damage", amount: 24 }, { kind: "apply", status: "break", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 30 }, { kind: "apply", status: "break", amount: 1 }] }, canon: "鳳鳴刀：出鞘之聲有如鳳鳴（鎖妖塔）" }),

  // ── 合擊 ──
  card({ id: "yue_combo", name: "弦月斬", owner: O, type: "combo", target: "all_enemies", rarity: "special", cost: 0,
    effects: [{ kind: "damage_all", amount: 12, hits: 2 }, { kind: "self_damage", amount: 10, percent: true, to: "party" }, { kind: "end_turn" }],
    canon: "合擊：由林月如發動時為「弦月斬」" }),

  // ── 紀念牌（月如身亡後留下，無主） ──
  card({ id: "yue_memory", name: "月如的長鞭", owner: null, type: "item", target: "party", rarity: "special", cost: 0,
    effects: [{ kind: "block", amount: 4, to: "party" }, { kind: "strength", amount: 1, to: "party" }, { kind: "draw", amount: 1 }], exhaust: true,
    canon: "林月如身亡後留下的長鞭（本作原創紀念牌）", note: "她還在。" }),
];

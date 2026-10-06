import type { CardDef } from "../../core/types";
import { card } from "./helpers";

/**
 * 林月如：近戰壓制、連段與反擊（REDESIGN §4.3）。
 * 正史：鞭為主（初始長鞭→九截鞭→金蛇鞭），也能用劍（越女劍）與刀（鳳鳴刀）；
 * 南武林盟主林天南之女，蘇州比武招親。合擊為「弦月斬」。
 */
const O = "lin_yueru" as const;

export const YUERU_CARDS: CardDef[] = [
  // ── 起始 ──
  card({ id: "yue_whip", name: "長鞭", owner: O, type: "attack", target: "enemy", rarity: "starter", cost: 1,
    effects: [{ kind: "damage", amount: 6 }], upgrade: { effects: [{ kind: "damage", amount: 9 }] }, canon: "林月如的初始兵器：長鞭" }),
  card({ id: "yue_guard", name: "林家架式", owner: O, type: "skill", target: "self", rarity: "starter", cost: 1,
    effects: [{ kind: "block", amount: 5 }], upgrade: { effects: [{ kind: "block", amount: 8 }] }, canon: "林家堡武學（本作命名）" }),
  card({ id: "yue_return", name: "回馬鞭", owner: O, type: "skill", target: "self", rarity: "starter", cost: 1,
    effects: [{ kind: "block", amount: 4 }, { kind: "counter", amount: 5 }], upgrade: { effects: [{ kind: "block", amount: 6 }, { kind: "counter", amount: 7 }] },
    canon: "鞭法的回擊（本作命名）" }),

  // ── 常見 ──
  card({ id: "yue_double", name: "雙鞭連擊", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 4, hits: 2 }], upgrade: { effects: [{ kind: "damage", amount: 6, hits: 2 }] }, canon: "鞭法（本作命名）" }),
  card({ id: "yue_sweep", name: "橫掃千軍", owner: O, type: "attack", target: "all_enemies", rarity: "common", cost: 1,
    effects: [{ kind: "damage_all", amount: 5 }], upgrade: { effects: [{ kind: "damage_all", amount: 7 }] }, canon: "長鞭橫掃（本作命名）" }),
  card({ id: "yue_bind", name: "纏鞭", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 1,
    effects: [{ kind: "damage", amount: 4 }, { kind: "apply", status: "vulnerable", amount: 2 }],
    upgrade: { effects: [{ kind: "damage", amount: 6 }, { kind: "apply", status: "vulnerable", amount: 2 }] }, canon: "鞭法（本作命名）" }),
  card({ id: "yue_parry", name: "以守為攻", owner: O, type: "skill", target: "self", rarity: "common", cost: 1,
    effects: [{ kind: "block", amount: 7 }, { kind: "counter", amount: 3 }], upgrade: { effects: [{ kind: "block", amount: 9 }, { kind: "counter", amount: 5 }] },
    canon: "林家武學（本作命名）" }),
  card({ id: "yue_temper", name: "大小姐脾氣", owner: O, type: "skill", target: "self", rarity: "common", cost: 0,
    effects: [{ kind: "strength", amount: 1 }, { kind: "self_damage", amount: 2 }], upgrade: { effects: [{ kind: "strength", amount: 2 }, { kind: "self_damage", amount: 2 }] },
    canon: "林月如嬌縱的個性（本作原創）" }),
  card({ id: "yue_thrust", name: "林家劍法", owner: O, type: "attack", target: "enemy", rarity: "common", cost: 2,
    effects: [{ kind: "damage", amount: 12 }, { kind: "block", amount: 4 }], upgrade: { effects: [{ kind: "damage", amount: 16 }, { kind: "block", amount: 5 }] },
    canon: "林家劍法" }),
  card({ id: "yue_breath", name: "調息", owner: O, type: "skill", target: "self", rarity: "common", cost: 1,
    effects: [{ kind: "heal", amount: 5 }, { kind: "draw", amount: 1 }], upgrade: { effects: [{ kind: "heal", amount: 7 }, { kind: "draw", amount: 1 }] },
    canon: "內功調息（本作命名）" }),

  // ── 少見 ──
  card({ id: "yue_ninewhip", name: "九截鞭", owner: O, type: "attack", target: "enemy", rarity: "uncommon", cost: 2,
    effects: [{ kind: "damage", amount: 3, hits: 5 }], upgrade: { effects: [{ kind: "damage", amount: 4, hits: 5 }] }, canon: "九截鞭：林月如的兵器" }),
  card({ id: "yue_yuenu", name: "越女劍", owner: O, type: "attack", target: "enemy", element: "wind", rarity: "uncommon", cost: 1,
    effects: [{ kind: "damage", amount: 9 }, { kind: "draw", amount: 1 }], upgrade: { effects: [{ kind: "damage", amount: 12 }, { kind: "draw", amount: 1 }] },
    canon: "越女劍：靈兒與月如共用的劍" }),
  card({ id: "yue_arena", name: "擂台", owner: O, type: "skill", target: "enemy", rarity: "uncommon", cost: 1,
    effects: [{ kind: "apply", status: "vulnerable", amount: 2 }, { kind: "counter", amount: 6 }],
    upgrade: { effects: [{ kind: "apply", status: "vulnerable", amount: 3 }, { kind: "counter", amount: 8 }] }, motion: "strike",
    canon: "蘇州比武招親的擂台" }),
  card({ id: "yue_wall", name: "銅牆鐵壁", owner: O, type: "skill", target: "ally", rarity: "uncommon", cost: 2,
    effects: [{ kind: "block", amount: 14, to: "target" }], upgrade: { effects: [{ kind: "block", amount: 18, to: "target" }] },
    canon: "替同伴擋下攻擊（本作命名）" }),
  card({ id: "yue_rally", name: "林家堡號令", owner: O, type: "skill", target: "party", rarity: "uncommon", cost: 1,
    effects: [{ kind: "strength", amount: 1, to: "party" }], upgrade: { effects: [{ kind: "strength", amount: 1, to: "party" }, { kind: "draw", amount: 1 }] },
    exhaust: true, canon: "南武林盟主之女的號召（本作原創）" }),
  card({ id: "yue_stormwhip", name: "鞭影如潮", owner: O, type: "attack", target: "all_enemies", rarity: "uncommon", cost: 2,
    effects: [{ kind: "damage_all", amount: 4, hits: 3 }], upgrade: { effects: [{ kind: "damage_all", amount: 5, hits: 3 }] }, canon: "鞭法（本作命名）" }),

  // ── 稀有 ──
  card({ id: "yue_goldsnake", name: "金蛇鞭", owner: O, type: "attack", target: "all_enemies", element: "fire", rarity: "rare", cost: 2,
    effects: [{ kind: "damage_all", amount: 9, hits: 2 }], upgrade: { effects: [{ kind: "damage_all", amount: 12, hits: 2 }] },
    canon: "金蛇鞭：林月如的鞭，攻擊全體" }),
  card({ id: "yue_phoenix", name: "鳳鳴刀", owner: O, type: "attack", target: "enemy", element: "fire", rarity: "rare", cost: 2,
    effects: [{ kind: "damage", amount: 24 }, { kind: "apply", status: "break", amount: 1 }],
    upgrade: { effects: [{ kind: "damage", amount: 30 }, { kind: "apply", status: "break", amount: 1 }] }, canon: "鳳鳴刀：林月如專屬最強兵器（鎖妖塔）" }),
  card({ id: "yue_vow", name: "此生不渝", owner: O, type: "skill", target: "party", rarity: "rare", cost: 2,
    effects: [{ kind: "block", amount: 10, to: "party" }, { kind: "counter", amount: 6 }],
    upgrade: { effects: [{ kind: "block", amount: 13, to: "party" }, { kind: "counter", amount: 8 }] }, exhaust: true,
    canon: "月如對逍遙的心意（本作原創）" }),

  // ── 合擊 ──
  card({ id: "yue_combo", name: "弦月斬", owner: O, type: "combo", target: "all_enemies", rarity: "special", cost: 0,
    effects: [{ kind: "damage_all", amount: 12, hits: 2 }, { kind: "self_damage", amount: 10, percent: true, to: "party" }, { kind: "end_turn" }],
    canon: "合擊：由林月如發動時為「弦月斬」" }),

  // ── 紀念牌（月如身亡後留下，無主） ──
  card({ id: "yue_memory", name: "月如的長鞭", owner: null, type: "item", target: "party", rarity: "special", cost: 0,
    effects: [{ kind: "block", amount: 4, to: "party" }, { kind: "strength", amount: 1, to: "party" }, { kind: "draw", amount: 1 }], exhaust: true,
    canon: "林月如身亡後留下的長鞭（本作原創紀念牌）", note: "她還在。" }),
];

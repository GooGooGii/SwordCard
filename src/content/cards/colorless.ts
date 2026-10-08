import type { CardDef } from "../../core/types";
import { card } from "./helpers";

/**
 * 無主牌（殺戮尖塔的「無色牌」，docs/ARCHETYPES.md）：不屬於任何流派的萬用工具牌，
 * 由當下 HP 最高的清醒隊員出手。不出現在一般戰後三選一，從客棧購買與精英、頭目獎勵取得。
 * 多半是好幾位主角都會的原作招式，或酒劍仙、蜀山的秘笈。
 */
export const COLORLESS_CARDS: CardDef[] = [
  // ── 常見 ──
  card({ id: "cl_qiliao", name: "氣療術", owner: null, type: "skill", target: "ally", rarity: "common", cost: 0,
    effects: [{ kind: "heal", amount: 5, to: "target" }], upgrade: { effects: [{ kind: "heal", amount: 8, to: "target" }] }, exhaust: true, motion: "cast",
    canon: "氣療術：我方單人回復（逍遙、月如都會）" }),
  card({ id: "cl_jingyi", name: "淨衣咒", owner: null, type: "skill", target: "party", rarity: "common", cost: 1,
    effects: [{ kind: "cleanse", to: "party" }, { kind: "draw", amount: 1 }], upgrade: { cost: 0 }, motion: "cast",
    canon: "淨衣咒：解毒（靈兒）" }),
  card({ id: "cl_scroll", name: "蜀山劍譜", owner: null, type: "skill", target: "none", rarity: "common", cost: 1,
    effects: [{ kind: "draw", amount: 3 }], upgrade: { effects: [{ kind: "draw", amount: 4 }] }, exhaust: true, motion: "cast",
    canon: "蜀山派的劍譜（本作命名）" }),

  // ── 少見 ──
  card({ id: "cl_zhenyuan", name: "真元護體", owner: null, type: "power", target: "none", rarity: "uncommon", cost: 2, effects: [],
    power: { triggers: [{ on: "turn_start", effects: [{ kind: "block", amount: 4 }] }] }, upgrade: { cost: 1 },
    canon: "真元護體：使用後如有鐵鎧金甲護體，增加防禦（逍遙）" }),
  card({ id: "cl_stun", name: "定身符", owner: null, type: "skill", target: "enemy", rarity: "uncommon", cost: 0,
    effects: [{ kind: "apply", status: "stun", amount: 1 }], upgrade: { effects: [{ kind: "apply", status: "stun", amount: 1 }, { kind: "apply", status: "weak", amount: 2 }] },
    exhaust: true, motion: "cast", canon: "符咒類道具（頭目不受定身）" }),
  card({ id: "cl_drunk_tip", name: "酒劍仙的指點", owner: null, type: "skill", target: "none", rarity: "uncommon", cost: 1,
    effects: [{ kind: "upgrade_hand" }], upgrade: { cost: 0 }, exhaust: true, motion: "cast",
    canon: "酒劍仙在十里坡與山神廟指點逍遙（本作原創）" }),

  // ── 稀有 ──
  card({ id: "cl_yuanling", name: "元靈歸心術", owner: null, type: "skill", target: "ally", rarity: "rare", cost: 1,
    effects: [{ kind: "heal", amount: 20, to: "target" }, { kind: "cleanse", to: "target" }],
    upgrade: { effects: [{ kind: "heal", amount: 28, to: "target" }, { kind: "cleanse", to: "target" }] }, exhaust: true, motion: "cast",
    canon: "元靈歸心術：我方單人大幅回復（逍遙、月如、阿奴都會）" }),
  card({ id: "cl_purple_gourd", name: "紫金葫蘆", owner: null, type: "power", target: "none", rarity: "rare", cost: 1, effects: [],
    power: { triggers: [{ on: "kill", effects: [{ kind: "gain_qi", amount: 1 }, { kind: "draw", amount: 1 }] }] }, upgrade: { cost: 0 },
    canon: "紫金葫蘆：蘇州支線所得，可收妖煉藥" }),
];

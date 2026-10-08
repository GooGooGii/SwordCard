import type { CardDef } from "../../core/types";
import { card } from "./helpers";

/**
 * 狀態牌（殺戮尖塔的傷口、暈眩）：敵人招式塞進我方棄牌堆，不能打出；回合結束時還在手上就發作。
 * 淨化類的牌（冰心訣、淨衣咒、靈血咒…）可以把手上的狀態牌移除。
 */
export const STATUS_CARDS: CardDef[] = [
  card({ id: "st_silk", name: "纏絲", owner: null, type: "skill", target: "none", rarity: "special", cost: 0, effects: [], unplayable: true,
    inHandAtTurnEnd: [{ kind: "self_damage", amount: 2, to: "party" }],
    canon: "纏魂絲：毒娘子的劇毒蛛絲（劉晉元因此重病）", note: "不能打出。回合結束時還在手上，全隊各失去 2 點生命。" }),
  card({ id: "st_corpse", name: "屍毒", owner: null, type: "skill", target: "none", rarity: "special", cost: 0, effects: [], unplayable: true,
    inHandAtTurnEnd: [{ kind: "self_damage", amount: 4 }],
    canon: "屍毒：殭屍、三屍咒留下的毒", note: "不能打出。回合結束時還在手上，出手的隊員失去 4 點生命。" }),
];

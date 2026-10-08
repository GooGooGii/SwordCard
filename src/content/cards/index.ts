import type { CardDef } from "../../core/types";
import { THOUGHT_CARD } from "../../core/cards";
import { ANU_CARDS, WUHOU_CARDS } from "./anu";
import { COLORLESS_CARDS } from "./colorless";
import { STATUS_CARDS } from "./status";
import { byId } from "./helpers";
import { ITEM_CARDS } from "./items";
import { LI_CARDS } from "./li_xiaoyao";
import { YUERU_CARDS } from "./lin_yueru";
import { LINGER_CARDS } from "./zhao_linger";

export const ALL_CARDS: CardDef[] = [...LI_CARDS, ...LINGER_CARDS, ...YUERU_CARDS, ...ANU_CARDS, ...WUHOU_CARDS, ...COLORLESS_CARDS, ...STATUS_CARDS, ...ITEM_CARDS, THOUGHT_CARD];

export const CARDS: Record<string, CardDef> = byId(ALL_CARDS);

/** 第一次入隊時帶的牌（REDESIGN §2.2：依入隊章節組好） */
export const STARTERS = {
  // 序章：逍遙單人。御劍術要到十里坡山神廟才由酒劍仙傳授（劇情獎勵）；土靈符用來教相剋
  li_xiaoyao: ["li_strike", "li_strike", "li_strike", "li_strike", "li_guard", "li_guard", "li_guard", "li_guard", "li_steal", "li_earth_talisman"],
  // 序章末入隊
  zhao_linger: ["ling_wind", "ling_thunder", "ling_ice", "ling_flame", "ling_earth", "ling_mercy", "ling_guard", "ling_guard"],
  // 第二章入隊
  lin_yueru: ["yue_whip", "yue_whip", "yue_whip", "yue_guard", "yue_guard", "yue_guard", "yue_return", "yue_double", "yue_bind"],
  // 第七章入隊：比照當時的逍遙，起始就含少見牌
  anu: ["anu_blade", "anu_blade", "anu_guard", "anu_guard", "anu_gu", "anu_gu", "anu_medicine", "anu_poisonblade", "anu_soul", "anu_goldsilk", "anu_snakestaff"],
  // 第七章十年前段客串
  wuhou: ["wuhou_staff", "wuhou_staff", "wuhou_ward", "wuhou_seal", "wuhou_nuwa", "wuhou_mercy"],
} as const;

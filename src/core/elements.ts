import type { Element } from "./types";

/**
 * 五靈（REDESIGN §4.2）
 * - 相剋（仙劍一）：風剋雷、雷剋水、水剋火、火剋土、土剋風
 * - 相生連鎖（本作原創）：風→火→雷→土→水→風
 */
export const ELEMENTS: Element[] = ["wind", "thunder", "water", "fire", "earth"];

export const ELEMENT_NAME: Record<Element, string> = {
  wind: "風",
  thunder: "雷",
  water: "水",
  fire: "火",
  earth: "土",
};

const BEATS: Record<Element, Element> = {
  wind: "thunder",
  thunder: "water",
  water: "fire",
  fire: "earth",
  earth: "wind",
};

const GENERATES: Record<Element, Element> = {
  wind: "fire",
  fire: "thunder",
  thunder: "earth",
  earth: "water",
  water: "wind",
};

export const STRONG_MULTIPLIER = 1.5;
export const WEAK_MULTIPLIER = 0.5;

/** 攻擊屬性對防守屬性的相剋結果 */
export function matchup(attack: Element | undefined, defend: Element | undefined): "strong" | "weak" | "normal" {
  if (!attack || !defend) return "normal";
  if (BEATS[attack] === defend) return "strong";
  if (BEATS[defend] === attack) return "weak";
  return "normal";
}

export function beats(element: Element): Element {
  return BEATS[element];
}

/** 相生：下一環該接的屬性 */
export function nextInChain(element: Element): Element {
  return GENERATES[element];
}

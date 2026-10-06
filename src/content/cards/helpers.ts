import type { CardDef } from "../../core/types";

type CardInput = Omit<CardDef, "art" | "motion"> & { motion?: CardDef["motion"] };

/** 卡牌定義 helper：補上預設動作與卡圖路徑（public/assets/cards/<id>.jpg）。 */
export function card(input: CardInput): CardDef {
  const motion = input.motion ?? (input.type === "attack" ? "strike" : input.type === "spell" || input.type === "combo" ? "cast" : "guard");
  return { ...input, motion, art: `/assets/cards/${input.id}.jpg` };
}

export function byId(list: CardDef[]): Record<string, CardDef> {
  const out: Record<string, CardDef> = {};
  for (const c of list) {
    if (out[c.id]) throw new Error(`duplicate card id ${c.id}`);
    out[c.id] = c;
  }
  return out;
}

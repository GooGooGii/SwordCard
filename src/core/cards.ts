import type { CardCore, CardDef, CardInstance, ContentDb } from "./types";

/** 套用升級後的卡牌定義（升級欄位覆蓋原欄位）。 */
export function cardDef(db: ContentDb, card: CardInstance | string, upgraded = false): CardDef {
  const id = typeof card === "string" ? card : card.defId;
  const up = typeof card === "string" ? upgraded : card.upgraded;
  const def = db.cards[id];
  if (!def) throw new Error(`unknown card: ${id}`);
  if (!up || !def.upgrade) return def;
  const patch: Partial<CardCore> = def.upgrade;
  return { ...def, ...patch, name: `${def.name}＋` };
}

/** 「心念」：主人昏迷時，他的牌暫時變成這張。 */
export const THOUGHT_CARD_ID = "thought";

export const THOUGHT_CARD: CardDef = {
  id: THOUGHT_CARD_ID,
  name: "心念",
  owner: null,
  type: "skill",
  target: "none",
  rarity: "special",
  cost: 0,
  effects: [{ kind: "draw", amount: 1 }],
  exhaust: true,
  motion: "cast",
  canon: "本作原創：同伴昏迷時的念想",
};

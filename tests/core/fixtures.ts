import type { CardDef, CardInstance, CharId, CharacterDef, ContentDb, EnemyDef } from "../../src/core/types";
import type { BattleSetup } from "../../src/core/battle";

const card = (def: Partial<CardDef> & Pick<CardDef, "id" | "effects">): CardDef => ({
  name: def.id,
  owner: "li_xiaoyao",
  type: "attack",
  target: "enemy",
  rarity: "common",
  cost: 1,
  motion: "strike",
  canon: "test",
  ...def,
});

export const cards: Record<string, CardDef> = Object.fromEntries(
  [
    card({ id: "strike", effects: [{ kind: "damage", amount: 6 }] }),
    card({ id: "double", effects: [{ kind: "damage", amount: 4, hits: 2 }] }),
    card({ id: "wind_slash", element: "wind", type: "spell", effects: [{ kind: "damage", amount: 10 }] }),
    card({ id: "fire_talisman", element: "fire", type: "spell", effects: [{ kind: "damage", amount: 5 }] }),
    card({ id: "thunder_talisman", element: "thunder", type: "spell", effects: [{ kind: "damage", amount: 5 }] }),
    card({ id: "guard", type: "skill", target: "self", motion: "guard", effects: [{ kind: "block", amount: 5 }] }),
    card({ id: "cover", type: "skill", target: "ally", motion: "guard", effects: [{ kind: "block", amount: 8, to: "target" }] }),
    card({ id: "linger_wind", owner: "zhao_linger", element: "wind", type: "spell", motion: "cast", effects: [{ kind: "damage", amount: 3 }] }),
    card({ id: "linger_heal", owner: "zhao_linger", type: "skill", target: "ally", motion: "cast", effects: [{ kind: "heal", amount: 10, to: "target" }] }),
    card({ id: "revive", owner: "zhao_linger", type: "skill", target: "ally", motion: "cast", effects: [{ kind: "revive", amount: 15 }] }),
    card({ id: "steal", type: "skill", effects: [{ kind: "steal" }] }),
    card({ id: "counter", owner: "lin_yueru", type: "skill", target: "self", motion: "guard", effects: [{ kind: "counter", amount: 4 }] }),
    card({ id: "gu", owner: "anu", type: "skill", target: "none", motion: "cast", effects: [{ kind: "summon_gu", amount: 2 }] }),
    card({ id: "fly", type: "attack", effects: [{ kind: "fly_sword", amount: 9 }] }),
    card({ id: "power", type: "skill", target: "self", effects: [{ kind: "strength", amount: 2 }] }),
    card({ id: "weaken", type: "skill", effects: [{ kind: "apply", status: "weak", amount: 2 }] }),
    card({ id: "expose", type: "skill", effects: [{ kind: "apply", status: "vulnerable", amount: 2 }] }),
    card({
      id: "combo_li",
      type: "combo",
      target: "all_enemies",
      cost: 0,
      effects: [
        { kind: "damage_all", amount: 20 },
        { kind: "self_damage", amount: 10, percent: true, to: "party" },
        { kind: "end_turn" },
      ],
    }),
    card({ id: "combo_linger", owner: "zhao_linger", type: "combo", target: "all_enemies", cost: 0, effects: [{ kind: "damage_all", amount: 20 }] }),
    card({ id: "herb", owner: null, type: "item", target: "self", effects: [{ kind: "heal", amount: 5 }], exhaust: true }),
  ].map((c) => [c.id, c]),
);

const enemy = (def: Partial<EnemyDef> & Pick<EnemyDef, "id" | "moves">): EnemyDef => ({
  name: def.id,
  maxHp: 40,
  model: "x.png",
  height: 1.5,
  pattern: "cycle",
  canon: "test",
  ...def,
});

export const enemies: Record<string, EnemyDef> = Object.fromEntries(
  [
    enemy({ id: "dummy", moves: [{ id: "wait", name: "發呆", intent: "charge" }] }),
    enemy({ id: "thunder_dummy", element: "thunder", moves: [{ id: "wait", name: "發呆", intent: "charge" }] }),
    enemy({ id: "biter", moves: [{ id: "bite", name: "咬", intent: "attack", damage: 6 }] }),
    enemy({ id: "brute", maxHp: 30, moves: [{ id: "smash", name: "重擊", intent: "attack", damage: 10, hits: 2 }] }),
    enemy({ id: "thunder_boss", element: "thunder", isBoss: true, maxHp: 200, moves: [{ id: "slam", name: "重擊", intent: "attack", damage: 20 }] }),
    enemy({ id: "thief", stealable: ["herb"], moves: [{ id: "wait", name: "發呆", intent: "charge" }] }),
    enemy({ id: "water", isField: true, element: "water", maxHp: 20, moves: [] }),
    enemy({
      id: "water_beast",
      maxHp: 30,
      passives: [{ kind: "undying_while", fieldId: "water" }],
      moves: [{ id: "wait", name: "潛伏", intent: "charge" }],
    }),
    enemy({ id: "summoner", moves: [{ id: "call", name: "呼喚", intent: "summon", summon: "dummy" }] }),
    enemy({ id: "snake_man", isBoss: true, successor: "fox_spirit", moves: [{ id: "wait", name: "盤踞", intent: "charge" }] }),
    enemy({ id: "fox_spirit", isBoss: true, moves: [{ id: "wait", name: "媚笑", intent: "charge" }] }),
  ].map((e) => [e.id, e]),
);

const character = (id: CharId, comboCard: string): CharacterDef => ({ id, name: id, maxHp: 50, model: "x.glb", height: 1.7, portrait: "x.png", comboCard });

export const db: ContentDb = {
  cards,
  enemies,
  characters: {
    li_xiaoyao: character("li_xiaoyao", "combo_li"),
    zhao_linger: character("zhao_linger", "combo_linger"),
    lin_yueru: character("lin_yueru", "combo_li"),
    anu: character("anu", "combo_li"),
    wuhou: character("wuhou", "combo_li"),
  },
};

export function deckOf(ids: string[]): CardInstance[] {
  return ids.map((defId, i) => ({ uid: i + 1, defId, upgraded: false }));
}

export function setup(over: Partial<BattleSetup> & { deckIds?: string[] } = {}): BattleSetup {
  const { deckIds, ...rest } = over;
  return {
    seed: 42,
    party: [{ charId: "li_xiaoyao", hp: 50, maxHp: 50 }],
    deck: deckOf(deckIds ?? ["strike", "strike", "strike", "strike", "strike"]),
    enemies: ["dummy"],
    ...rest,
  };
}

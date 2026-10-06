import { nextInChain } from "../elements";
import type { BattleState, CardDef, ContentDb } from "../types";
import { computeDamage } from "./damage";
import { actorFor } from "./setup";

export interface CardPreview {
  /** 每一下傷害（有目標時算對該目標，沒目標時不算守方狀態與屬性） */
  damage: number | null;
  hits: number;
  block: number | null;
  /** 這張牌打出去會得到的連鎖加成 */
  chainBonus: number;
  effective: "strong" | "weak" | "normal";
}

/** 卡面預測值：和實際結算用同一個公式（REDESIGN 支柱 2：卡面即時顯示最終數字）。 */
export function previewCard(db: ContentDb, state: BattleState, def: CardDef, targetEnemy: number | null): CardPreview {
  const actor = actorFor(state, def);
  const attacker = actor !== null ? state.party[actor]!.status : null;
  let chainBonus = 0;
  if (def.element && state.chain.last && def.element === nextInChain(state.chain.last)) chainBonus = state.chain.count + 1;
  const dmgEffect = def.effects.find((e) => e.kind === "damage" || e.kind === "damage_all");
  const blockEffect = def.effects.find((e) => e.kind === "block");
  let damage: number | null = null;
  let hits = 1;
  let effective: CardPreview["effective"] = "normal";
  if (dmgEffect && (dmgEffect.kind === "damage" || dmgEffect.kind === "damage_all")) {
    hits = dmgEffect.hits ?? 1;
    const enemy = targetEnemy !== null ? state.enemies[targetEnemy] : undefined;
    const res = computeDamage({
      base: dmgEffect.amount,
      attacker,
      defender: enemy && !enemy.dead ? enemy.status : null,
      attackElement: def.element,
      defendElement: enemy ? db.enemies[enemy.defId]?.element : undefined,
      chainBonus,
    });
    damage = res.amount;
    effective = res.effective;
  }
  const block = blockEffect && blockEffect.kind === "block" ? blockEffect.amount + (def.element ? chainBonus : 0) : null;
  return { damage, hits, block, chainBonus, effective };
}

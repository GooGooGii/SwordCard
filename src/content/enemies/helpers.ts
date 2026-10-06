import type { DebuffStatus, EnemyDef, MoveDef } from "../../core/types";

/**
 * 敵人資料的簡寫。名稱、出沒地點、招式名與可偷物品取自 DOS 版遊戲資料與攻略
 * （wuyongzheng.github.io/pal-enemy、gamegene.cn、gamersky、52pk；2026-10-05 查證）。
 * 正史的五靈抗性換算成本作的單一屬性：弱火→土、弱土→風、弱風→雷、弱雷→水、弱水→火（REDESIGN §4.2）。
 * 數值是本作重新設計的（正史 HP 動輒上千，不照搬）。
 */
type Spec = Omit<EnemyDef, "model" | "pattern" | "height"> & Partial<Pick<EnemyDef, "model" | "pattern" | "height">>;

export const enemy = (e: Spec): EnemyDef => ({ model: `/assets/enemies/${e.id}.webp`, pattern: "cycle", height: 1.7, ...e });

export const hit = (id: string, name: string, damage: number, hits?: number): MoveDef =>
  hits ? { id, name, intent: "attack", damage, hits } : { id, name, intent: "attack", damage };
export const sweep = (id: string, name: string, damage: number, hits?: number): MoveDef =>
  hits ? { id, name, intent: "attack_all", damage, hits } : { id, name, intent: "attack_all", damage };
export const guard = (id: string, name: string, block: number): MoveDef => ({ id, name, intent: "block", block });
export const rally = (id: string, name: string, strength: number): MoveDef => ({ id, name, intent: "buff", strength });
export const curse = (id: string, name: string, status: DebuffStatus, amount: number, to: "target" | "party" = "target", damage?: number): MoveDef =>
  damage ? { id, name, intent: "debuff", apply: { status, amount, to }, damage } : { id, name, intent: "debuff", apply: { status, amount, to } };
export const mend = (id: string, name: string, heal: number): MoveDef => ({ id, name, intent: "heal", heal });
export const call = (id: string, name: string, summon: string): MoveDef => ({ id, name, intent: "summon", summon });
export const wait = (id: string, name: string): MoveDef => ({ id, name, intent: "charge" });

export const byId = (list: EnemyDef[]): Record<string, EnemyDef> => Object.fromEntries(list.map((e) => [e.id, e]));

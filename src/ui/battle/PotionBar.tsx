import type { MouseEvent } from "react";
import { canUsePotion } from "../../core/battle";
import { describeEffect, describeTrigger, STACK_NAME } from "../../core/describe";
import type { BattleState, PotionDef } from "../../core/types";
import { game } from "../../game/store";

/** 藥品要選目標嗎：敵人或隊友 */
export function potionTargetKind(p: PotionDef | undefined): "enemy" | "party" | null {
  if (!p) return null;
  if (p.target === "enemy") return "enemy";
  if (p.target === "ally") return "party";
  return null;
}

export function potionText(p: PotionDef): string {
  return p.effects.map((e) => describeEffect(e, game.db)).join("。") + "。";
}

/**
 * 藥品欄（3 格）：點一下選取；不用選目標的藥再點一次就用掉，要選目標的藥選了之後點敵人或隊友。
 * 不花真氣、不算出牌。
 */
export function PotionBar({ battle, selected, disabled, onSelect, onUse }: {
  battle: BattleState;
  selected: number | null;
  disabled: boolean;
  onSelect: (slot: number | null) => void;
  onUse: (slot: number) => void;
}) {
  const slots = battle.potions ?? [];
  if (slots.length === 0) return null;
  return (
    <div className="bt-potions" onClick={(e: MouseEvent) => e.stopPropagation()}>
      {slots.map((id, slot) => {
        const p = id ? game.db.potions?.[id] : undefined;
        if (!p) return <span key={slot} className="bt-potion empty" title="空的藥品欄" />;
        const kind = potionTargetKind(p);
        const usableNow = !canUsePotion(game.db, battle, slot, kind === null ? null : 0) || kind !== null;
        return (
          <button
            key={slot}
            type="button"
            className={`bt-potion r-${p.rarity} ${selected === slot ? "selected" : ""}`}
            disabled={disabled || !usableNow}
            title={`${p.name}：${potionText(p)}`}
            onClick={() => {
              if (selected === slot && kind === null) onUse(slot);
              else onSelect(selected === slot ? null : slot);
            }}
          >
            <span className="bt-potion-name">{p.name}</span>
          </button>
        );
      })}
      {selected !== null && slots[selected] ? (
        <div className="bt-potion-tip">
          {(() => {
            const p = game.db.potions?.[slots[selected]!];
            if (!p) return null;
            const kind = potionTargetKind(p);
            return `${p.name}：${potionText(p)}${kind === "enemy" ? "（點選敵人）" : kind === "party" ? "（點選隊友）" : "（再點一次使用）"}`;
          })()}
        </div>
      ) : null}
    </div>
  );
}

/** 生效中的心法與法寶（戰鬥左上角），滑過看說明 */
export function PowerList({ battle }: { battle: BattleState }) {
  const powers = battle.powers ?? [];
  const stacks = Object.entries(battle.stacks ?? {}).filter(([, n]) => n > 0);
  if (powers.length === 0 && stacks.length === 0) return null;
  return (
    <div className="bt-powers">
      {stacks.map(([key, n]) => (
        <span key={key} className="bt-power stack">
          {STACK_NAME[key] ?? key} {n}
        </span>
      ))}
      {powers.map((p, i) => (
        <span key={`${p.id}-${i}`} className={`bt-power ${p.source}`} title={p.triggers.map((t) => describeTrigger(t, game.db)).join("；")}>
          {p.source === "card" ? "心法・" : ""}
          {p.name}
        </span>
      ))}
    </div>
  );
}

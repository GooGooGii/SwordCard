import { useRef, useState, type CSSProperties, type PointerEvent as ReactPointerEvent } from "react";
import { canPlay, effectiveCard, previewCard } from "../../core/battle";
import type { BattleState, CardDef, CardInstance } from "../../core/types";
import { game } from "../../game/store";
import { CardFace } from "../common/CardFace";

/**
 * 手牌：扇形排列。兩種出牌方式（滑鼠與觸控同一套）：
 * - 拖曳：拖到敵人／隊友身上放開；不用選目標的牌往上拖過門檻放開
 * - 點選：點一下選起，再點目標（或再點同一張）打出
 * 拖曳中用 elementFromPoint 找畫面上 data-target 的落點（3D 舞台上蓋的 HTML 區塊）。
 */
export type TargetRef = { side: "enemy" | "party"; index: number };

const PLAY_DRAG_PX = 64;
const TAP_PX = 8;

export function needsTarget(def: CardDef): "enemy" | "party" | null {
  if (def.target === "enemy") return "enemy";
  if (def.target === "ally") return "party";
  return null;
}

/** 判斷「現在能不能打」用的任一合法目標 */
export function defaultTarget(battle: BattleState, def: CardDef): number | null {
  const kind = needsTarget(def);
  if (kind === "enemy") {
    const i = battle.enemies.findIndex((e) => !e.dead);
    return i >= 0 ? i : null;
  }
  if (kind === "party") {
    const revives = def.effects.some((e) => e.kind === "revive");
    const i = battle.party.findIndex((m) => revives || !m.downed);
    return i >= 0 ? i : null;
  }
  return null;
}

function targetAt(x: number, y: number): TargetRef | null {
  const el = document.elementFromPoint(x, y)?.closest("[data-target]") as HTMLElement | null;
  const raw = el?.dataset.target;
  if (!raw) return null;
  const [side, index] = raw.split(":");
  return side === "enemy" || side === "party" ? { side, index: Number(index) } : null;
}

export interface HandProps {
  battle: BattleState;
  disabled: boolean;
  selected: number | null;
  onSelect: (uid: number | null) => void;
  onHover: (target: TargetRef | null) => void;
  hover: TargetRef | null;
  onPlay: (uid: number, target: number | null) => void;
  onDragKind: (kind: "enemy" | "party" | null) => void;
}

const HOLD_MS = 450;

export function Hand({ battle, disabled, selected, onSelect, onHover, hover, onPlay, onDragKind }: HandProps) {
  const [drag, setDrag] = useState<{ uid: number; dx: number; dy: number } | null>(null);
  const start = useRef<{ x: number; y: number } | null>(null);
  // 長按預覽（手機沒有滑鼠懸停）：按住不動 0.45 秒放大顯示，放開不出牌
  const [peek, setPeek] = useState<number | null>(null);
  const holdTimer = useRef<number | null>(null);
  const clearHold = () => {
    if (holdTimer.current !== null) window.clearTimeout(holdTimer.current);
    holdTimer.current = null;
  };

  const tryPlay = (card: CardInstance, def: CardDef, target: TargetRef | null, draggedUp: boolean): boolean => {
    const kind = needsTarget(def);
    if (kind) {
      if (!target || target.side !== kind) return false;
      if (canPlay(game.db, battle, card.uid, target.index)) return false;
      onPlay(card.uid, target.index);
      return true;
    }
    if (!draggedUp) return false;
    if (canPlay(game.db, battle, card.uid, null)) return false;
    onPlay(card.uid, null);
    return true;
  };

  const onDown = (card: CardInstance) => (e: ReactPointerEvent<HTMLDivElement>) => {
    if (disabled) return;
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
    start.current = { x: e.clientX, y: e.clientY };
    setDrag({ uid: card.uid, dx: 0, dy: 0 });
    onDragKind(needsTarget(effectiveCard(game.db, battle, card)));
    clearHold();
    holdTimer.current = window.setTimeout(() => setPeek(card.uid), HOLD_MS);
  };
  const onMove = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (!drag || !start.current) return;
    const dx = e.clientX - start.current.x;
    const dy = e.clientY - start.current.y;
    if (Math.hypot(dx, dy) > TAP_PX) clearHold();
    setDrag({ ...drag, dx, dy });
    onHover(targetAt(e.clientX, e.clientY));
  };
  const onUp = (card: CardInstance, def: CardDef) => (e: ReactPointerEvent<HTMLDivElement>) => {
    const d = drag;
    setDrag(null);
    onDragKind(null);
    start.current = null;
    clearHold();
    if (peek !== null) {
      setPeek(null);
      return;
    }
    if (!d || d.uid !== card.uid) return;
    const moved = Math.hypot(d.dx, d.dy);
    if (moved < TAP_PX) {
      // 點選：同一張再點一次＝打出不用選目標的牌
      if (selected === card.uid && !needsTarget(def) && !canPlay(game.db, battle, card.uid, null)) onPlay(card.uid, null);
      else onSelect(selected === card.uid ? null : card.uid);
      return;
    }
    const target = targetAt(e.clientX, e.clientY);
    onHover(null);
    if (tryPlay(card, def, target, -d.dy > PLAY_DRAG_PX)) onSelect(null);
  };

  const mid = (battle.hand.length - 1) / 2;
  const peekCard = peek !== null ? battle.hand.find((c) => c.uid === peek) : undefined;
  return (
    <>
    {peekCard ? (
      <div className="bt-peek">
        <CardFace def={effectiveCard(game.db, battle, peekCard)} upgraded={peekCard.upgraded} />
      </div>
    ) : null}
    <div className="bt-hand" style={{ "--hand-count": battle.hand.length } as CSSProperties}>
      {battle.hand.map((card, i) => {
        const def = effectiveCard(game.db, battle, card);
        const thought = def.id !== card.defId;
        const offset = i - mid;
        const dragging = drag?.uid === card.uid;
        const isSelected = selected === card.uid;
        const targetIndex = hover && hover.side === "enemy" && (dragging || isSelected) ? hover.index : null;
        const preview = previewCard(game.db, battle, def, targetIndex);
        const affordable = canPlay(game.db, battle, card.uid, defaultTarget(battle, def)) === null;
        const transform = dragging
          ? `translate(${drag.dx}px, ${drag.dy}px) scale(1.08)`
          : isSelected
            ? `translateY(-46px) scale(1.06)`
            : `translateY(${-18 + Math.abs(offset) * 4}px) rotate(${offset * 2.5}deg)`;
        return (
          <div
            key={card.uid}
            className={`bt-card ${dragging ? "dragging" : ""} ${affordable ? "" : "unaffordable"} ${isSelected ? "selected" : ""} ${thought ? "thought" : ""}`}
            style={{ transform, zIndex: dragging ? 60 : isSelected ? 50 : 10 + i }}
            onPointerDown={onDown(card)}
            onPointerMove={onMove}
            onPointerUp={onUp(card, def)}
            onPointerCancel={() => (setDrag(null), onDragKind(null), onHover(null), clearHold(), setPeek(null), start.current = null)}
          >
            <CardFace
              def={def}
              upgraded={card.upgraded}
              numbers={{ damage: preview.damage, block: preview.block }}
              dim={!affordable}
            />
            {preview.effective === "strong" && targetIndex !== null ? <span className="bt-card-tag strong">剋</span> : null}
            {preview.effective === "weak" && targetIndex !== null ? <span className="bt-card-tag weak">抗</span> : null}
            {preview.chainBonus > 0 ? <span className="bt-card-tag chain">連鎖 +{preview.chainBonus}</span> : null}
          </div>
        );
      })}
    </div>
    </>
  );
}

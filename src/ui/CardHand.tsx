import { useRef, useState, type PointerEvent as ReactPointerEvent } from "react";

export interface CardView {
  id: string;
  name: string;
  cost: number;
  element?: "風" | "雷" | "水" | "火" | "土";
  type: "招式" | "身法" | "仙術";
  text: string;
  art?: string;
}

interface CardHandProps {
  cards: CardView[];
  qi: number;
  onPlay: (card: CardView) => void;
}

const PLAY_DRAG_PX = 110; // 往上拖超過這個距離放開＝打出

/** 手牌：扇形排列；拖曳出牌（滑鼠與觸控同一套手勢，不依賴懸停）。 */
export function CardHand({ cards, qi, onPlay }: CardHandProps) {
  const [drag, setDrag] = useState<{ id: string; dx: number; dy: number } | null>(null);
  const start = useRef<{ x: number; y: number } | null>(null);

  const onDown = (card: CardView) => (e: ReactPointerEvent<HTMLDivElement>) => {
    if (card.cost > qi) return;
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
    start.current = { x: e.clientX, y: e.clientY };
    setDrag({ id: card.id, dx: 0, dy: 0 });
  };
  const onMove = (e: ReactPointerEvent<HTMLDivElement>) => {
    if (!drag || !start.current) return;
    setDrag({ ...drag, dx: e.clientX - start.current.x, dy: e.clientY - start.current.y });
  };
  const onUp = (card: CardView) => () => {
    if (drag && drag.id === card.id && -drag.dy > PLAY_DRAG_PX) onPlay(card);
    setDrag(null);
    start.current = null;
  };

  const mid = (cards.length - 1) / 2;
  return (
    <div className="hand">
      {cards.map((card, i) => {
        const offset = i - mid;
        const dragging = drag?.id === card.id;
        const ready = dragging && -drag.dy > PLAY_DRAG_PX;
        const transform = dragging
          ? `translate(${drag.dx}px, ${drag.dy}px) rotate(0deg) scale(1.08)`
          : `translateY(${Math.abs(offset) * 10}px) rotate(${offset * 5}deg)`;
        return (
          <div
            key={card.id}
            className={`card ${card.cost > qi ? "card-disabled" : ""} ${ready ? "card-ready" : ""}`}
            style={{ transform, zIndex: dragging ? 50 : 10 + i }}
            onPointerDown={onDown(card)}
            onPointerMove={onMove}
            onPointerUp={onUp(card)}
            onPointerCancel={() => setDrag(null)}
          >
            <div className="card-art" style={card.art ? { backgroundImage: `url(${card.art})` } : undefined} />
            <div className="card-cost">{card.cost}</div>
            <div className="card-name">{card.name}</div>
            <div className="card-type">
              {card.type}
              {card.element ? `・${card.element}` : ""}
            </div>
            <div className="card-text">{card.text}</div>
          </div>
        );
      })}
    </div>
  );
}

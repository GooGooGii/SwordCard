import { cardDef } from "../../core/cards";
import { member, type RunState } from "../../core/run";
import type { CardInstance } from "../../core/types";
import { CHARACTERS } from "../../content/characters";
import { game } from "../../game/store";
import { CardFace } from "./CardFace";
import { useEscape } from "./useEscape";

/** 牌組總覽：依角色分組（REDESIGN §2.2：每個人的牌跟著人走） */
export function DeckView({ run, onClose, onPick, pickLabel, filter }: {
  run: RunState;
  onClose: () => void;
  /** 客棧刪牌、升級時用：點一張牌 */
  onPick?: (card: CardInstance) => void;
  pickLabel?: string;
  filter?: (card: CardInstance) => boolean;
}) {
  useEscape(onClose);
  const groups: { title: string; cards: CardInstance[] }[] = [
    ...run.party.map((id) => ({ title: CHARACTERS[id].name, cards: member(run, id).deck })),
    { title: "無主", cards: run.shared },
  ].filter((g) => g.cards.length > 0);

  return (
    <div className="ov" onClick={onClose}>
      <div className="ov-panel deck-view" onClick={(e) => e.stopPropagation()}>
        <div className="ov-head">
          <h2>{pickLabel ?? "牌組"}</h2>
          <button type="button" className="ui-btn" onClick={onClose}>
            關閉
          </button>
        </div>
        <div className="deck-scroll">
          {groups.map((g) => (
            <section key={g.title}>
              <h3>
                {g.title}（{g.cards.length}）
              </h3>
              <div className="deck-grid">
                {g.cards.map((c) => {
                  const allowed = !filter || filter(c);
                  return (
                    <button
                      key={c.uid}
                      type="button"
                      className="deck-card"
                      disabled={!onPick || !allowed}
                      onClick={() => onPick?.(c)}
                    >
                      <CardFace def={cardDef(game.db, c)} upgraded={c.upgraded} small dim={!!onPick && !allowed} />
                    </button>
                  );
                })}
              </div>
            </section>
          ))}
        </div>
      </div>
    </div>
  );
}

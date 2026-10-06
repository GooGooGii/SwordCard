import { useState } from "react";
import { cardDef } from "../../core/cards";
import { buyCard, canRemove, leaveInn, nodeOf, removeCard, removePrice, rest, upgradeCard, upgradePrice, type RunState } from "../../core/run";
import { game } from "../../game/store";
import { playSfx } from "../../platform/audio";
import { CardFace } from "../common/CardFace";
import { DeckView } from "../common/DeckView";
import { TopBar } from "../common/TopBar";

/**
 * 客棧（REDESIGN §2）：休息回滿（免費一次）、買牌、刪牌、升級。刪牌與升級越做越貴。
 */
export function InnScreen({ run }: { run: RunState }) {
  const p = run.pending as Extract<RunState["pending"], { kind: "inn" }>;
  const node = nodeOf(game.db, run, p.nodeId);
  const [mode, setMode] = useState<"remove" | "upgrade" | null>(null);
  const rp = removePrice(game.db, run);
  const up = upgradePrice(game.db, run);
  const wounded = run.party.some((id) => run.members[id]!.hp < run.members[id]!.maxHp);

  return (
    <div className="inn">
      <div className="inn-bg" />
      <div className="inn-panel">
        <h1>{node.inn?.name ?? node.label}</h1>
        <p className="inn-greet">「客官裡面請！住店、買東西，還是要整理行囊？」</p>
        <div className="inn-actions">
          <button
            type="button"
            className="ui-btn primary"
            disabled={p.rested || !wounded}
            onClick={() => {
              playSfx("heal");
              game.update((_, r) => rest(r));
            }}
          >
            {p.rested ? "已經休息過了" : wounded ? "休息（全隊回滿）" : "大家精神都很好"}
          </button>
          <button type="button" className="ui-btn" disabled={run.coins < rp} onClick={() => setMode("remove")}>
            刪去一張牌　{rp} 文
          </button>
          <button type="button" className="ui-btn" disabled={run.coins < up} onClick={() => setMode("upgrade")}>
            升級一張牌　{up} 文
          </button>
        </div>
        <h2>掌櫃的貨</h2>
        <div className="inn-stock">
          {p.stock.map((item, i) => (
            <button
              key={i}
              type="button"
              className={`inn-item ${item.sold ? "sold" : ""}`}
              disabled={item.sold || run.coins < item.price}
              onClick={() => {
                playSfx("coin");
                game.update((db, r) => buyCard(db, r, i));
              }}
            >
              <CardFace def={cardDef(game.db, item.card)} small dim={item.sold} />
              <span className="inn-price">{item.sold ? "售出" : `${item.price} 文`}</span>
            </button>
          ))}
        </div>
        <button type="button" className="ui-btn primary inn-leave" onClick={() => game.update((db, r) => leaveInn(db, r))}>
          上路
        </button>
      </div>
      <TopBar run={run} />
      {mode ? (
        <DeckView
          run={run}
          pickLabel={mode === "remove" ? `選一張牌刪去（${rp} 文）` : `選一張牌升級（${up} 文）`}
          filter={(c) => (mode === "remove" ? canRemove(run, c.uid) === null : !c.upgraded && !!game.db.cards[c.defId]?.upgrade)}
          onClose={() => setMode(null)}
          onPick={(c) => {
            setMode(null);
            playSfx("coin");
            game.update((db, r) => (mode === "remove" ? removeCard(db, r, c.uid) : upgradeCard(db, r, c.uid)));
          }}
        />
      ) : null}
    </div>
  );
}

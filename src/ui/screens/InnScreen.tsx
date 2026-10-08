import { useState } from "react";
import { cardDef } from "../../core/cards";
import { buyCard, buyPotion, canRemove, leaveInn, nodeOf, removeCard, removePrice, rest, REST_HEAL, train, type RunState } from "../../core/run";
import type { CardInstance } from "../../core/types";
import { game } from "../../game/store";
import { playSfx } from "../../platform/audio";
import { CardFace } from "../common/CardFace";
import { DeckView } from "../common/DeckView";
import { TopBar } from "../common/TopBar";
import { potionText } from "../battle/PotionBar";

/**
 * 客棧：歇腳二選一（休息回復三成，或練功升級一張牌——殺戮尖塔的營火），
 * 加上掌櫃的貨（買牌）與刪牌（越刪越貴）。
 */
export function InnScreen({ run }: { run: RunState }) {
  const p = run.pending as Extract<RunState["pending"], { kind: "inn" }>;
  const node = nodeOf(game.db, run, p.nodeId);
  const [mode, setMode] = useState<"remove" | "train" | null>(null);
  const [preview, setPreview] = useState<CardInstance | null>(null);
  const rp = removePrice(game.db, run);
  const wounded = run.party.some((id) => run.members[id]!.hp < run.members[id]!.maxHp);
  const canTrain = [...run.party.flatMap((id) => run.members[id]!.deck), ...run.shared].some((c) => !c.upgraded && !!game.db.cards[c.defId]?.upgrade);

  return (
    <div className="inn">
      <div className="inn-bg" />
      <div className="inn-panel">
        <h1>{node.inn?.name ?? node.label}</h1>
        <p className="inn-greet">「客官裡面請！今晚是要好好歇一晚，還是到後院練練功夫？」</p>
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
            {p.rested ? "今晚已經歇過了" : wounded ? `休息（全隊回復 ${Math.round(REST_HEAL * 100)}% 生命）` : "大家精神都很好"}
          </button>
          <span className="inn-or">或</span>
          <button type="button" className="ui-btn primary" disabled={p.rested || !canTrain} onClick={() => setMode("train")}>
            {p.rested ? "今晚已經歇過了" : "練功（升級一張牌）"}
          </button>
          <button type="button" className="ui-btn" disabled={run.coins < rp} onClick={() => setMode("remove")}>
            刪去一張牌　{rp} 文
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
        {p.potions?.length ? (
          <>
            <h2>藥舖</h2>
            <div className="inn-potions">
              {p.potions.map((item, i) => {
                const potion = game.db.potions?.[item.potion];
                if (!potion) return null;
                const full = !(run.potions ?? [null, null, null]).includes(null);
                return (
                  <button
                    key={i}
                    type="button"
                    className={`inn-potion r-${potion.rarity} ${item.sold ? "sold" : ""}`}
                    disabled={item.sold || run.coins < item.price || full}
                    title={full ? "藥品欄滿了" : potion.canon}
                    onClick={() => {
                      playSfx("coin");
                      game.update((db, r) => buyPotion(db, r, i));
                    }}
                  >
                    <b>{potion.name}</b>
                    <small>{potionText(potion)}</small>
                    <span className="inn-price">{item.sold ? "售出" : `${item.price} 文`}</span>
                  </button>
                );
              })}
            </div>
          </>
        ) : null}
        <button type="button" className="ui-btn primary inn-leave" onClick={() => game.update((db, r) => leaveInn(db, r))}>
          上路
        </button>
      </div>
      <TopBar run={run} />
      {mode ? (
        <DeckView
          run={run}
          pickLabel={mode === "remove" ? `選一張牌刪去（${rp} 文）` : "選一張牌練功升級"}
          filter={(c) => (mode === "remove" ? canRemove(run, c.uid) === null : !c.upgraded && !!game.db.cards[c.defId]?.upgrade)}
          onClose={() => setMode(null)}
          onPick={(c) => {
            if (mode === "train") {
              setPreview(c);
              return;
            }
            setMode(null);
            playSfx("coin");
            game.update((db, r) => removeCard(db, r, c.uid));
          }}
        />
      ) : null}
      {preview ? (
        <div className="ov" onClick={() => setPreview(null)}>
          <div className="ov-panel inn-train" onClick={(e) => e.stopPropagation()}>
            <h2>練成新招</h2>
            <div className="inn-train-cards">
              <CardFace def={cardDef(game.db, preview.defId)} />
              <span className="inn-train-arrow">→</span>
              <CardFace def={cardDef(game.db, { ...preview, upgraded: true })} upgraded />
            </div>
            <div className="inn-train-actions">
              <button type="button" className="ui-btn" onClick={() => setPreview(null)}>
                再想想
              </button>
              <button
                type="button"
                className="ui-btn primary"
                onClick={() => {
                  const uid = preview.uid;
                  setPreview(null);
                  setMode(null);
                  playSfx("heal");
                  game.update((db, r) => train(db, r, uid));
                }}
              >
                就練這招
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}

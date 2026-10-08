import { useState } from "react";
import { cardDef } from "../../core/cards";
import { takeReward, type RunState } from "../../core/run";
import { game } from "../../game/store";
import { playSfx } from "../../platform/audio";
import { CardFace } from "../common/CardFace";
import { potionText } from "../battle/PotionBar";

/** 戰後獎勵：銅錢、偷到的東西、法寶，每組三選一（可跳過換 10 文，REDESIGN §2） */
export function RewardScreen({ run }: { run: RunState }) {
  const p = run.pending as Extract<RunState["pending"], { kind: "reward" }>;
  const [picks, setPicks] = useState<(string | null | undefined)[]>(() => p.choices.map(() => undefined));
  const relic = p.relic ? game.db.relics[p.relic] : null;
  const potion = p.potion ? game.db.potions?.[p.potion] : undefined;
  const allChosen = picks.every((x) => x !== undefined);

  const confirm = () => {
    playSfx("coin");
    game.update((db, r) => takeReward(db, r, picks.map((x) => x ?? null)));
  };

  return (
    <div className="rw">
      <div className="rw-panel">
        <h1>{p.outcomeNote}</h1>
        <div className="rw-loot">
          <span className="rw-coins">
            <span className="coin-icon" />+{p.coins} 文
          </span>
          {p.loot.map((id, i) => (
            <span key={i} className="rw-item">
              偷到：{cardDef(game.db, id).name}
            </span>
          ))}
          {potion ? (
            <span className="rw-item" title={potion.canon}>
              藥品：<b>{potion.name}</b>　{potionText(potion)}
            </span>
          ) : null}
          {relic ? (
            <span className="rw-relic" title={relic.canon}>
              法寶：<b>{relic.name}</b>　{relic.text}
            </span>
          ) : null}
        </div>
        {p.choices.map((group, g) => (
          <div key={g} className="rw-group">
            <h2>{p.choices.length > 1 ? `選一張牌（${g + 1}/${p.choices.length}）` : "選一張牌加入牌組"}</h2>
            <div className="rw-cards">
              {group.map((id) => (
                <button
                  key={id}
                  type="button"
                  className={`rw-card ${picks[g] === id ? "picked" : ""}`}
                  onClick={() => setPicks((x) => x.map((v, k) => (k === g ? id : v)))}
                >
                  <CardFace def={cardDef(game.db, id)} />
                </button>
              ))}
              <button type="button" className={`rw-skip ${picks[g] === null ? "picked" : ""}`} onClick={() => setPicks((x) => x.map((v, k) => (k === g ? null : v)))}>
                跳過
                <small>+10 文</small>
              </button>
            </div>
          </div>
        ))}
        <button type="button" className="ui-btn primary rw-confirm" disabled={!allChosen} onClick={confirm}>
          {allChosen ? "收下" : "請先選牌（或跳過）"}
        </button>
      </div>
    </div>
  );
}

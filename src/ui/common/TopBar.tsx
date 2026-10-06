import { useCallback, useState } from "react";
import { useMenuRequest } from "./useEscape";
import { member, type RunState } from "../../core/run";
import { CHARACTERS } from "../../content/characters";
import { game } from "../../game/store";
import { DeckView } from "./DeckView";
import { GameMenu } from "./GameMenu";

/** 地圖、客棧共用的頂列：隊伍 HP、銅錢、法寶、牌組、選單 */
export function TopBar({ run }: { run: RunState }) {
  const [deck, setDeck] = useState(false);
  const [menu, setMenu] = useState(false);
  const [relic, setRelic] = useState<string | null>(null);
  useMenuRequest(useCallback(() => setMenu(true), []));
  const deckSize = run.party.reduce((n, id) => n + member(run, id).deck.length, 0) + run.shared.length;
  const shown = relic ? game.db.relics[relic] : null;

  return (
    <>
      <div className="topbar">
        <div className="topbar-party">
          {run.party.map((id) => {
            const m = member(run, id);
            return (
              <div key={id} className="topbar-member" title={`${CHARACTERS[id].name} ${m.hp}/${m.maxHp}`}>
                <span className="topbar-name">{CHARACTERS[id].name}</span>
                <span className="topbar-hp">
                  <span style={{ width: `${(m.hp / m.maxHp) * 100}%` }} />
                </span>
                <span className="topbar-hp-text">
                  {m.hp}/{m.maxHp}
                </span>
              </div>
            );
          })}
        </div>
        <div className="topbar-coins" title="銅錢">
          <span className="coin-icon" />
          {run.coins}
        </div>
        <div className="topbar-relics">
          {run.relics.map((id) => (
            <button key={id} type="button" className="relic-chip" onClick={() => setRelic(relic === id ? null : id)}>
              {game.db.relics[id]?.name.slice(0, 1)}
            </button>
          ))}
        </div>
        <div className="topbar-actions">
          <button type="button" className="ui-btn" onClick={() => setDeck(true)}>
            牌組 {deckSize}
          </button>
          <button type="button" className="ui-btn" onClick={() => setMenu(true)}>
            選單
          </button>
        </div>
      </div>
      {shown ? (
        <div className="relic-pop" onClick={() => setRelic(null)}>
          <b>{shown.name}</b>
          <p>{shown.text}</p>
          <small>{shown.canon}</small>
        </div>
      ) : null}
      {deck ? <DeckView run={run} onClose={() => setDeck(false)} /> : null}
      {menu ? <GameMenu onClose={() => setMenu(false)} /> : null}
    </>
  );
}

import { useState } from "react";
import { cardDef } from "../../core/cards";
import { ELEMENT_NAME } from "../../core/elements";
import type { BattleState, CardInstance, Element } from "../../core/types";
import { CHARACTERS } from "../../content/characters";
import { game } from "../../game/store";
import { CardFace } from "../common/CardFace";
import { useEscape } from "../common/useEscape";

/**
 * 戰鬥頂部資訊：回合（求生戰顯示撐過幾回合）、五靈輪（相生連鎖）、合擊氣、蠱、飛劍、牌堆。
 * 五靈輪照相生順序排：風→火→雷→土→水→風（REDESIGN §4.2），標出上一環與下一環。
 */
const CHAIN: Element[] = ["wind", "fire", "thunder", "earth", "water"];

export function ChainWheel({ battle }: { battle: BattleState }) {
  const last = battle.chain.last;
  const next = last ? CHAIN[(CHAIN.indexOf(last) + 1) % CHAIN.length] : null;
  return (
    <div className="bt-wheel" title="相生連鎖：風→火→雷→土→水→風，依序出仙術，每接一環傷害與護體 +連鎖數">
      {CHAIN.map((el, i) => {
        const angle = (i / CHAIN.length) * Math.PI * 2 - Math.PI / 2;
        return (
          <span
            key={el}
            className={`bt-wheel-el el-${el} ${el === last ? "last" : ""} ${el === next ? "next" : ""}`}
            style={{ left: `${50 + Math.cos(angle) * 36}%`, top: `${50 + Math.sin(angle) * 36}%` }}
          >
            {ELEMENT_NAME[el]}
          </span>
        );
      })}
      <span className="bt-wheel-count">{battle.chain.count > 0 ? `連鎖 ${battle.chain.count}` : "五靈"}</span>
    </div>
  );
}

function PileView({ title, cards, onClose }: { title: string; cards: CardInstance[]; onClose: () => void }) {
  useEscape(onClose);
  return (
    <div className="ov" onClick={onClose}>
      <div className="ov-panel deck-view" onClick={(e) => e.stopPropagation()}>
        <div className="ov-head">
          <h2>
            {title}（{cards.length}）
          </h2>
          <button type="button" className="ui-btn" onClick={onClose}>
            關閉
          </button>
        </div>
        <div className="deck-scroll">
          <div className="deck-grid">
            {cards.map((c) => (
              <div key={c.uid} className="deck-card">
                <CardFace def={cardDef(game.db, c)} upgraded={c.upgraded} small />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

export function BattleHud({ battle, onMenu }: { battle: BattleState; onMenu: () => void }) {
  const [pile, setPile] = useState<"draw" | "discard" | "exhaust" | null>(null);
  const comboOwner = battle.lastOwner ? CHARACTERS[battle.lastOwner].name : null;
  // 抽牌堆不洩漏順序：依名稱排序顯示
  const drawSorted = [...battle.draw].sort((a, b) => a.defId.localeCompare(b.defId));
  return (
    <>
      <div className="bt-top-left">
        <div className="bt-turn">
          {battle.survive ? (
            <>
              撐過 <b>{Math.min(battle.turn, battle.survive)}</b> / {battle.survive} 回合
            </>
          ) : (
            <>
              第 <b>{battle.turn}</b> 回合
            </>
          )}
        </div>
        <ChainWheel battle={battle} />
        <div className="bt-combo" title="不同角色的牌交替打出會累積合擊氣；滿了之後，最後出牌的人的合擊牌加入手牌">
          <span>合擊氣</span>
          <span className="bt-combo-pips">
            {Array.from({ length: battle.comboMax }, (_, i) => (
              <i key={i} className={i < battle.comboGauge ? "on" : ""} />
            ))}
          </span>
          {comboOwner ? <small>{comboOwner}</small> : null}
        </div>
        {battle.gu > 0 ? <div className="bt-chip">蠱蟲 ×{battle.gu}</div> : null}
        {battle.flyingSwords.length > 0 ? <div className="bt-chip">飛劍 ×{battle.flyingSwords.length}</div> : null}
      </div>
      <div className="bt-top-right">
        <button type="button" className="ui-btn" onClick={() => setPile("draw")}>
          抽牌堆 {battle.draw.length}
        </button>
        <button type="button" className="ui-btn" onClick={() => setPile("discard")}>
          棄牌堆 {battle.discard.length}
        </button>
        {battle.exhaust.length > 0 ? (
          <button type="button" className="ui-btn" onClick={() => setPile("exhaust")}>
            消耗 {battle.exhaust.length}
          </button>
        ) : null}
        <button type="button" className="ui-btn" onClick={onMenu}>
          選單
        </button>
      </div>
      {pile === "draw" ? <PileView title="抽牌堆" cards={drawSorted} onClose={() => setPile(null)} /> : null}
      {pile === "discard" ? <PileView title="棄牌堆" cards={battle.discard} onClose={() => setPile(null)} /> : null}
      {pile === "exhaust" ? <PileView title="消耗" cards={battle.exhaust} onClose={() => setPile(null)} /> : null}
    </>
  );
}

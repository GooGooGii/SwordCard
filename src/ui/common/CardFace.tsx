import type { CardDef } from "../../core/types";
import { describeCard } from "../../core/describe";
import { ELEMENT_NAME } from "../../core/elements";
import { CHARACTERS } from "../../content/characters";
import { game } from "../../game/store";

/**
 * 一張牌的牌面：卡圖、費用印章、名稱、類型與主人、效果文字（由效果自動產生，REDESIGN §7.4）。
 * numbers：戰鬥中帶入實際傷害／護體的預測值（含相剋、狀態），讓牌面數字和結果一致。
 */
const TYPE_NAME: Record<CardDef["type"], string> = { attack: "攻擊", skill: "技能", spell: "仙術", item: "道具", combo: "合擊" };

export interface CardFaceProps {
  def: CardDef;
  upgraded?: boolean;
  numbers?: { damage?: number | null; block?: number | null };
  /** 費用顯示（心念牌等例外情況） */
  cost?: number;
  dim?: boolean;
  small?: boolean;
}

export function CardFace({ def, upgraded, numbers, cost, dim, small }: CardFaceProps) {
  const owner = def.owner ? CHARACTERS[def.owner].name : "無主";
  return (
    <div
      className={`card-face owner-${def.owner ?? "none"} type-${def.type} ${def.element ? `el-${def.element}` : ""} ${dim ? "dim" : ""} ${small ? "small" : ""} ${upgraded ? "upgraded" : ""}`}
    >
      <div className="cf-art" style={def.art ? { backgroundImage: `url(${def.art})` } : undefined} />
      <div className="cf-cost">{cost ?? def.cost}</div>
      {def.element ? <div className="cf-element">{ELEMENT_NAME[def.element]}</div> : null}
      <div className="cf-name">{def.name}</div>
      <div className="cf-type">
        {TYPE_NAME[def.type]}・{owner}
      </div>
      <div className="cf-text">{describeCard(def, game.db, numbers)}</div>
    </div>
  );
}

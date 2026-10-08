import type { CardDef } from "../../core/types";
import { describeCard } from "../../core/describe";
import { ELEMENT_NAME } from "../../core/elements";
import { CHARACTERS } from "../../content/characters";
import { game } from "../../game/store";

/** 流派名稱（docs/ARCHETYPES.md），顯示在牌面類型列 */
export const ARCHETYPE_NAME: Record<string, string> = {
  shushan: "蜀山劍仙", jianghu: "江湖雜學", wuling: "五靈法術", nuwa: "女媧靈族",
  zhijian: "林家劍指", purse: "錢與鞭", gudu: "苗疆蠱毒", wushu: "巫術攝魂",
};

/**
 * 一張牌的牌面：卡圖、費用印章、名稱、類型與主人、效果文字（由效果自動產生，REDESIGN §7.4）。
 * numbers：戰鬥中帶入實際傷害／護體的預測值（含相剋、狀態），讓牌面數字和結果一致。
 */
const TYPE_NAME: Record<CardDef["type"], string> = { attack: "攻擊", skill: "技能", spell: "仙術", item: "道具", combo: "合擊", power: "心法" };

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
      className={`card-face owner-${def.owner ?? "none"} type-${def.type} rarity-${def.rarity} ${def.element ? `el-${def.element}` : ""} ${dim ? "dim" : ""} ${small ? "small" : ""} ${upgraded ? "upgraded" : ""}`}
    >
      <div className="cf-art" style={def.art ? { backgroundImage: `url(${def.art})` } : undefined} />
      <div className="cf-rarity" aria-hidden="true" />
      <div className="cf-cost">{cost ?? def.cost}</div>
      {def.element ? <div className="cf-element">{ELEMENT_NAME[def.element]}</div> : null}
      <div className="cf-name">
        {/* 升級版的名稱已由 cardDef 加上「＋」，這裡統一成一個上色的＋ */}
        {def.name.replace(/＋$/, "")}
        {upgraded || def.name.endsWith("＋") ? <span className="cf-plus">＋</span> : null}
      </div>
      <div className="cf-type">
        {TYPE_NAME[def.type]}・{owner}
        {def.archetype ? <span className="cf-arch">{ARCHETYPE_NAME[def.archetype] ?? def.archetype}</span> : null}
      </div>
      <div className="cf-text">{describeCard(def, game.db, numbers)}</div>
    </div>
  );
}

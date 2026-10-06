import type { CardDef, ContentDb, DebuffStatus, Effect, EffectScope, IntentKind, MoveDef } from "./types";

/**
 * 卡面文字由效果自動產生（不手寫），保證文字和實際行為一致。
 * numbers 可帶入預測值（例如已加上氣勢、連鎖的傷害），沒帶就顯示基礎值。
 */
export const STATUS_NAME: Record<DebuffStatus | "strength", string> = {
  weak: "弱化",
  vulnerable: "破綻",
  poison: "中毒",
  break: "破勢",
  strength: "氣勢",
};

function scopeText(to: EffectScope | undefined, self: string): string {
  switch (to ?? "self") {
    case "party":
      return "全隊";
    case "target":
      return "一名隊友";
    case "all_enemies":
      return "所有敵人";
    default:
      return self;
  }
}

export function describeEffect(effect: Effect, db: ContentDb | null, numbers?: { damage?: number | null; block?: number | null }): string {
  switch (effect.kind) {
    case "damage": {
      const n = numbers?.damage ?? effect.amount;
      return effect.hits && effect.hits > 1 ? `造成 ${n} 點傷害 ${effect.hits} 次` : `造成 ${n} 點傷害`;
    }
    case "damage_all": {
      const n = numbers?.damage ?? effect.amount;
      return effect.hits && effect.hits > 1 ? `對所有敵人造成 ${n} 點傷害 ${effect.hits} 次` : `對所有敵人造成 ${n} 點傷害`;
    }
    case "block": {
      const n = numbers?.block ?? effect.amount;
      const who = scopeText(effect.to, "");
      return who ? `${who}獲得 ${n} 點護體` : `獲得 ${n} 點護體`;
    }
    case "heal": {
      const who = scopeText(effect.to, "");
      return who ? `${who}回復 ${effect.amount} 點生命` : `回復 ${effect.amount} 點生命`;
    }
    case "draw":
      return `抽 ${effect.amount} 張牌`;
    case "gain_qi":
      return `獲得 ${effect.amount} 點真氣`;
    case "apply": {
      const who = effect.to === "all_enemies" ? "所有敵人" : "目標";
      return `使${who}${STATUS_NAME[effect.status]} ${effect.amount}`;
    }
    case "strength": {
      const who = scopeText(effect.to, "");
      return who ? `${who}獲得 ${effect.amount} 點氣勢` : `獲得 ${effect.amount} 點氣勢`;
    }
    case "cleanse":
      return `解除${scopeText(effect.to, "自己")}的弱化、破綻與中毒`;
    case "steal":
      return "偷取目標身上的東西";
    case "counter":
      return `本回合受擊時反擊 ${effect.amount} 點`;
    case "summon_gu":
      return `召喚 ${effect.amount} 隻蠱蟲（每回合結束時，每隻蠱讓最前面的敵人中毒 1）`;
    case "fly_sword":
      return `御劍：下回合開始時對目標造成 ${effect.amount} 點傷害`;
    case "revive":
      return `使一名昏迷的隊友以 ${effect.amount} 點生命甦醒（未昏迷則回復）`;
    case "combo_gauge":
      return `合擊氣 +${effect.amount}`;
    case "self_damage": {
      const who = effect.to === "party" ? "全隊各" : "自己";
      const n = effect.percent ? `最大生命的 ${effect.amount}%` : `${effect.amount} 點生命`;
      return `${who}失去${n}（最低留 1）`;
    }
    case "end_turn":
      return "結束回合";
    case "add_card": {
      const name = db?.cards[effect.card]?.name ?? effect.card;
      return effect.count && effect.count > 1 ? `將 ${effect.count} 張「${name}」加入手牌` : `將「${name}」加入手牌`;
    }
    case "upgrade_hand":
      return "本場戰鬥中強化手上所有牌";
  }
}

export function describeCard(def: CardDef, db: ContentDb | null, numbers?: { damage?: number | null; block?: number | null }): string {
  const parts = def.effects.map((e) => describeEffect(e, db, numbers));
  const keywords: string[] = [];
  if (def.retain) keywords.push("保留");
  if (def.exhaust || def.type === "combo") keywords.push("消耗");
  let text = parts.join("。");
  if (text) text += "。";
  if (def.note) text += def.note;
  if (keywords.length) text += `${keywords.join("、")}。`;
  return text;
}

export const INTENT_NAME: Record<IntentKind, string> = {
  attack: "攻擊",
  attack_all: "群攻",
  block: "防禦",
  buff: "蓄勢",
  debuff: "妨礙",
  summon: "召喚",
  heal: "回復",
  charge: "蓄力",
};

/** 意圖的簡述（HUD 顯示）：例如「12×2」「全體 8」「護體 10」 */
export function describeIntent(move: MoveDef, damageOverride?: number): string {
  const dmg = damageOverride ?? move.damage ?? 0;
  switch (move.intent) {
    case "attack":
      return move.hits && move.hits > 1 ? `${dmg}×${move.hits}` : `${dmg}`;
    case "attack_all":
      return move.hits && move.hits > 1 ? `全體 ${dmg}×${move.hits}` : `全體 ${dmg}`;
    case "block":
      return `護體 ${move.block ?? 0}`;
    case "buff":
      return `氣勢 +${move.strength ?? 0}`;
    case "debuff":
      return move.apply ? `${STATUS_NAME[move.apply.status]} ${move.apply.amount}${move.damage ? `／${dmg}` : ""}` : "妨礙";
    case "heal":
      return `回復 ${move.heal ?? 0}`;
    case "summon":
      return "召喚";
    case "charge":
      return "蓄力";
  }
}

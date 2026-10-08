import type { CardDef, CardType, ContentDb, DebuffStatus, Effect, EffectScope, IntentKind, MoveDef, Trigger } from "./types";
import { ELEMENT_NAME } from "./elements";

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
  stun: "定身",
  seal: "封印",
  sleep: "昏睡",
  confuse: "混亂",
};

/** 流派層數的名稱（資料用的 key → 牌面文字） */
export const STACK_NAME: Record<string, string> = { zhijin: "指勁", swordqi: "劍意", qi: "剩餘真氣" };
const stackName = (key: string) => STACK_NAME[key] ?? key;

function perText(per: { key: string; amount: number; consume?: boolean } | undefined): string {
  if (!per) return "";
  if (per.key === "qi") return `（每點剩餘真氣 +${per.amount}${per.consume ? "，用光所有真氣" : ""}）`;
  return `（每層${stackName(per.key)} +${per.amount}${per.consume ? "，用完清空" : ""}）`;
}

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
      return (effect.hits && effect.hits > 1 ? `造成 ${n} 點傷害 ${effect.hits} 次` : `造成 ${n} 點傷害`) + perText(effect.per);
    }
    case "damage_all": {
      const n = numbers?.damage ?? effect.amount;
      return (effect.hits && effect.hits > 1 ? `對所有敵人造成 ${n} 點傷害 ${effect.hits} 次` : `對所有敵人造成 ${n} 點傷害`) + perText(effect.per);
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
      return `解除${scopeText(effect.to, "自己")}的弱化、破綻、中毒與定身、封印、昏睡、混亂，並移除手上的狀態牌`;
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
    case "stack":
      return `獲得 ${effect.amount} 層${stackName(effect.key)}`;
    case "gain_coins":
      return `得到 ${effect.amount} 文`;
    case "spend_coins":
      return `花費 ${effect.amount} 文`;
    case "detonate":
      return `引爆目標的中毒，造成「中毒層數 ×${effect.multiplier}」點傷害`;
    case "execute":
      return `目標（非頭目）生命低於 ${effect.below}% 時直接擊倒，否則造成 ${effect.fallback} 點傷害`;
    case "capture":
      return `目標（非頭目）生命低於 ${effect.below}% 時收進葫蘆，煉成一瓶藥`;
  }
}

const TYPE_WORD: Record<CardType, string> = { attack: "攻擊", skill: "技能", spell: "仙術", item: "道具", combo: "合擊", power: "心法" };
const TARGET_WORD = { front: "最前面的敵人", random: "隨機一名敵人", source: "那名敵人" } as const;

/** 觸發條件的文字：「每打出第 3 張攻擊牌時」「每回合開始時」… */
export function describeTrigger(trigger: Trigger, db: ContentDb | null): string {
  const n = trigger.every && trigger.every > 1 ? trigger.every : null;
  let when: string;
  switch (trigger.on) {
    case "turn_start":
      when = n ? `每 ${n} 回合開始時` : "每回合開始時";
      break;
    case "turn_end":
      when = n ? `每 ${n} 回合結束時` : "每回合結束時";
      break;
    case "play": {
      const owner = trigger.owner && db ? db.characters[trigger.owner]?.name ?? "" : "";
      const element = trigger.element ? `${ELEMENT_NAME[trigger.element]}屬性的` : "";
      const kind = trigger.type ? `${TYPE_WORD[trigger.type]}牌` : "牌";
      when = `${owner ? `${owner}` : ""}每打出${n ? `第 ${n} 張` : "一張"}${element}${kind}時`;
      break;
    }
    case "kill":
      when = n ? `每擊倒 ${n} 名敵人時` : "每擊倒一名敵人時";
      break;
    case "hurt":
      when = "隊員每次受到傷害時";
      break;
    case "poison_tick":
      when = "敵人每次中毒結算時";
      break;
    case "counter":
      when = "每次反擊時";
      break;
  }
  const target = TARGET_WORD[trigger.target ?? "front"];
  const effects = trigger.effects.map((e) => {
    const text = describeEffect(e, db);
    if (e.kind === "damage" || (e.kind === "apply" && e.to !== "all_enemies")) return text.replace(/^使目標|^造成/, (m) => (m === "造成" ? `對${target}造成` : `使${target}`));
    return text;
  });
  return `${when}，${effects.join("、")}`;
}

export function describeCard(def: CardDef, db: ContentDb | null, numbers?: { damage?: number | null; block?: number | null }): string {
  const parts = def.effects.map((e) => describeEffect(e, db, numbers));
  if (def.power) parts.push(...def.power.triggers.map((tr) => `心法：${describeTrigger(tr, db)}`));
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
  const base = describeIntentCore(move, damageOverride);
  return move.addCard ? `${base}＋塞牌` : base;
}

function describeIntentCore(move: MoveDef, damageOverride?: number): string {
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

import type { BattleEvent, BattleState, Ref } from "../../core/types";
import { STATUS_NAME } from "../../core/describe";

/**
 * 戰鬥演出：core 一次回傳整串事件，畫面把它拆成一拍一拍播放。
 * 播放時 HP、護體用「顯示用快照」一步步扣，播完再對齊 core 的最終狀態。
 */
export interface ShownUnit {
  hp: number;
  block: number;
  gone: boolean;
}

export interface Shown {
  party: ShownUnit[];
  enemies: (ShownUnit & { defId: string; uid: number })[];
}

export type FxKind = "damage" | "strong" | "weak" | "block" | "heal" | "status" | "break" | "info";

export interface Beat {
  /** 這一拍之後要等多久（毫秒，1× 速度） */
  wait: number;
  shown?: (s: Shown, final: BattleState) => void;
  banner?: { text: string; kind: "card" | "enemy" | "turn" | "big" };
  popup?: { at: Ref; text: string; kind: FxKind };
  flash?: Ref;
  /** 與 HP、音效同一拍的接觸效果，擊殺後仍獨立播完。 */
  impact?: { at: Ref; kind: "slash" | "block" | "heal" };
  lunge?: { actor: Ref; target: Ref | null; motion: "strike" | "cast" | "guard" };
  clip?: { actor: Ref; clip: string };
}

export function snapshot(state: BattleState): Shown {
  return {
    party: state.party.map((m) => ({ hp: m.hp, block: m.block, gone: m.downed })),
    enemies: state.enemies.map((e) => ({ hp: e.hp, block: e.block, gone: e.dead, defId: e.defId, uid: e.uid })),
  };
}

const unit = (s: Shown, ref: Ref): ShownUnit | undefined => (ref.side === "party" ? s.party[ref.index] : s.enemies[ref.index]);

/** 把事件轉成一拍一拍的演出 */
export function toBeats(events: BattleEvent[], cardName: (defId: string) => { name: string; motion: "strike" | "cast" | "guard" }, moveName: (actor: Ref, moveId: string) => string): Beat[] {
  const beats: Beat[] = [];
  for (const ev of events) {
    switch (ev.type) {
      case "turn_start":
        if (ev.turn > 1) beats.push({ wait: 450, banner: { text: `第 ${ev.turn} 回合`, kind: "turn" } });
        break;
      case "card_played": {
        const card = cardName(ev.defId);
        beats.push({
          wait: card.motion === "strike" && ev.target?.side === "enemy" ? 260 : 220,
          banner: { text: card.name, kind: "card" },
          ...(ev.actor ? { lunge: { actor: ev.actor, target: card.motion === "strike" ? ev.target : null, motion: card.motion } } : {}),
        });
        break;
      }
      case "enemy_move":
        beats.push({
          wait: 300,
          banner: { text: moveName(ev.actor, ev.moveId), kind: "enemy" },
          lunge: { actor: ev.actor, target: ev.target, motion: ev.target ? "strike" : "cast" },
        });
        break;
      case "damage": {
        const kind: FxKind = ev.effective === "strong" ? "strong" : ev.effective === "weak" ? "weak" : "damage";
        const text = ev.amount > 0 ? `-${ev.amount}` : ev.blocked > 0 ? "擋下" : "0";
        beats.push({
          wait: 170,
          flash: ev.target,
          impact: { at: ev.target, kind: ev.amount === 0 && ev.blocked > 0 ? "block" : "slash" },
          clip: { actor: ev.target, clip: "hit" },
          popup: { at: ev.target, text: ev.effective === "strong" ? `剋！${text}` : ev.effective === "weak" ? `${text}（抗）` : text, kind },
          shown: (s) => {
            const u = unit(s, ev.target);
            if (!u) return;
            u.block = Math.max(0, u.block - ev.blocked);
            u.hp = Math.max(0, u.hp - ev.amount);
          },
        });
        break;
      }
      case "block":
        beats.push({
          wait: 90,
          impact: { at: ev.target, kind: "block" },
          popup: { at: ev.target, text: `護體 +${ev.amount}`, kind: "block" },
          shown: (s) => {
            const u = unit(s, ev.target);
            if (u) u.block += ev.amount;
          },
        });
        break;
      case "heal":
        if (ev.amount > 0) {
          beats.push({
            wait: 90,
            impact: { at: ev.target, kind: "heal" },
            popup: { at: ev.target, text: `+${ev.amount}`, kind: "heal" },
            shown: (s) => {
              const u = unit(s, ev.target);
              if (u) u.hp += ev.amount;
            },
          });
        }
        break;
      case "status":
        if (ev.status !== "break") beats.push({ wait: 60, popup: { at: ev.target, text: `${STATUS_NAME[ev.status]} ${ev.amount}`, kind: "status" } });
        break;
      case "break":
        beats.push({ wait: 260, popup: { at: ev.target, text: ev.result === "cancelled" ? "破勢！意圖取消" : "破勢！威力減半", kind: "break" } });
        break;
      case "chain":
        if (ev.count > 0) beats.push({ wait: 120, banner: { text: `相生連鎖 ×${ev.count}`, kind: "big" } });
        break;
      case "combo_ready":
        beats.push({ wait: 320, banner: { text: "合擊氣滿！", kind: "big" } });
        break;
      case "downed":
        beats.push({
          wait: 260,
          clip: { actor: ev.target, clip: "downed" },
          shown: (s) => {
            const u = unit(s, ev.target);
            if (u) u.gone = true;
          },
        });
        break;
      case "revived":
        beats.push({
          wait: 160,
          popup: { at: ev.target, text: "甦醒", kind: "heal" },
          shown: (s) => {
            const u = unit(s, ev.target);
            if (u) u.gone = false;
          },
        });
        break;
      case "enemy_died":
        beats.push({
          wait: 240,
          shown: (s) => {
            const u = s.enemies[ev.target.index];
            if (u) u.gone = true;
          },
        });
        break;
      case "summon":
        beats.push({
          wait: 280,
          shown: (s, final) => {
            const e = final.enemies[ev.target.index];
            if (e) s.enemies[ev.target.index] = { hp: e.hp, block: e.block, gone: e.dead, defId: e.defId, uid: e.uid };
          },
        });
        break;
      case "steal":
        beats.push({ wait: 260, popup: { at: ev.target, text: ev.card ? "偷到了！" : `摸到 ${ev.coins} 文`, kind: "info" } });
        break;
      case "fly_sword":
        beats.push({ wait: 120, popup: { at: ev.target, text: "御劍", kind: "info" } });
        break;
      case "counter":
        beats.push({ wait: 160, banner: { text: "反擊", kind: "card" } });
        break;
      case "gu":
        beats.push({ wait: 120, banner: { text: `蠱蟲 ${ev.count} 隻發作`, kind: "card" } });
        break;
      case "draw":
      case "outcome":
        break;
    }
  }
  return beats;
}

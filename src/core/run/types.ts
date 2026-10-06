import type { BattleState, CardInstance, CharId, Effect } from "../types";

/**
 * 行程（整局遊戲）的資料型別：章節、節點、劇本、獎勵、法寶、存檔狀態。
 */

// ── 劇本 ─────────────────────────────────────────────────────────────────────

/** 說話者：主角用 CharId，其他 NPC 用自由字串（對應 content/npcs） */
export type Speaker = CharId | string;

export type StoryStep =
  | { say: string; who: Speaker; expr?: string }
  | { narrate: string }
  | { bg: string }
  | { music: string }
  | { join: CharId }
  | { leave: CharId; permanent?: boolean }
  | { choice: { text: string; then: StoryStep[] }[] }
  | { reward: Reward }
  | { bond: CharId; amount: number }
  | { flag: string; value?: boolean }
  /** 依旗標分支（旗標可以是之前章節、或同一段劇本裡較早設的） */
  | { when: string; then: StoryStep[]; otherwise?: StoryStep[] }
  | { heal: "full" };

export interface StoryDef {
  id: string;
  /** 劇情場景的背景（平視插畫） */
  bg: string;
  music?: string;
  steps: StoryStep[];
}

// ── 獎勵 ─────────────────────────────────────────────────────────────────────

export interface Reward {
  coins?: number;
  /** 直接加入牌組的牌 */
  cards?: string[];
  relic?: string;
  /** 從牌池選 1/3 的次數 */
  cardChoices?: number;
  /** 升級牌組裡隨機 n 張（固定種子） */
  upgrades?: number;
  maxHp?: number;
}

// ── 章節與節點 ───────────────────────────────────────────────────────────────

export interface BattleNode {
  enemies: string[];
  /** 戰鬥背景（俯視地面） */
  ground: string;
  music?: string;
  /** 求生戰：撐過幾回合 */
  survive?: number;
  boss?: boolean;
  elite?: boolean;
  /** 戰前、戰後的劇情 */
  intro?: string;
  outro?: string;
  reward?: Reward;
  /** 教學提示（REDESIGN §5.1：不做獨立教學關，融入序章與第一章的戰鬥） */
  tips?: string[];
}

export interface NodeDef {
  id: string;
  kind: "story" | "battle" | "inn" | "event";
  label: string;
  /** 章節地圖上的位置（0..1） */
  pos: [number, number];
  next: string[];
  story?: string;
  battle?: BattleNode;
  /** 客棧：可休息、可買賣 */
  inn?: { name: string; shopSize?: number };
  optional?: boolean;
}

export interface ChapterDef {
  id: string;
  title: string;
  subtitle: string;
  /** 章節標題卡上的一句題詞（本作原創） */
  epigraph?: string;
  /** 章節地圖（俯瞰插畫） */
  map: string;
  music?: string;
  start: string;
  /** 走到這個節點並完成就進入下一章 */
  end: string;
  nodes: NodeDef[];
  /** 這章戰後選牌的稀有度權重 */
  rarity: { common: number; uncommon: number; rare: number };
  /** 這章的戰鬥銅錢 */
  coins: { normal: number; elite: number; boss: number };
}

// ── 法寶 ─────────────────────────────────────────────────────────────────────

export interface RelicDef {
  id: string;
  name: string;
  text: string;
  canon: string;
  art?: string;
  /** 每場戰鬥開始時結算（由 HP 最高的隊員「出手」） */
  battleStart?: Effect[];
  /** 常駐修正 */
  handSize?: number;
  maxQi?: number;
  comboMax?: number;
  /** 戰後回復（每位清醒隊員） */
  afterBattleHeal?: number;
  /** 客棧商品折扣（百分比） */
  shopDiscount?: number;
}

// ── 行程狀態 ─────────────────────────────────────────────────────────────────

export interface MemberRecord {
  hp: number;
  maxHp: number;
  /** 這位角色的牌（離隊時一起離開，歸隊時回來） */
  deck: CardInstance[];
  /** 永久離隊（月如） */
  gone?: boolean;
  joined: boolean;
}

export type Difficulty = "story" | "standard";

export type Pending =
  | { kind: "map" }
  | { kind: "story"; nodeId: string; storyId: string; then: "map" | "battle" | "after_battle" }
  | { kind: "battle"; nodeId: string; battle: BattleState; attempt: number }
  | { kind: "battle_lost"; nodeId: string; attempt: number }
  | { kind: "reward"; nodeId: string; coins: number; loot: string[]; choices: string[][]; relic: string | null; outcomeNote: string }
  | { kind: "inn"; nodeId: string; stock: { card: string; price: number; sold: boolean }[]; rested: boolean; removed: number; upgraded: number }
  | { kind: "chapter_intro"; chapter: number }
  | { kind: "ending" };

export interface RunState {
  version: 1;
  seed: number;
  difficulty: Difficulty;
  chapter: number;
  /** 本章已完成的節點 */
  visited: string[];
  /** 目前所在（最後完成）的節點 */
  at: string | null;
  /** 在場隊員（順序＝站位） */
  party: CharId[];
  members: Partial<Record<CharId, MemberRecord>>;
  /** 無主牌（偷來的道具、紀念牌…） */
  shared: CardInstance[];
  coins: number;
  relics: string[];
  bonds: Partial<Record<CharId, number>>;
  flags: Record<string, boolean>;
  nextUid: number;
  pending: Pending;
  /** 同一場連敗次數（劇情難度協助用） */
  losses: Record<string, number>;
  /** 這場戰鬥改用劇情難度 */
  assisted: Record<string, boolean>;
  stats: { battles: number; defeats: number; cardsPlayed: number; playMinutes: number };
}

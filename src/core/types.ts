/**
 * 遊戲的資料型別（REDESIGN §4）。內容定義（*Def）是不可變的資料；戰鬥／行程狀態是可序列化的純物件。
 */

export type CharId = "li_xiaoyao" | "zhao_linger" | "lin_yueru" | "anu" | "wuhou";
export type Element = "wind" | "thunder" | "water" | "fire" | "earth";
export type DebuffStatus = "weak" | "vulnerable" | "poison" | "break";
export type Status = DebuffStatus | "strength";

// ── 卡牌 ────────────────────────────────────────────────────────────────────

export type CardType = "attack" | "skill" | "spell" | "item" | "combo";
export type CardTarget = "enemy" | "all_enemies" | "self" | "ally" | "party" | "none";
export type Rarity = "starter" | "common" | "uncommon" | "rare" | "special";

/** 效果的作用對象：卡牌的「選定目標」或其他固定範圍 */
export type EffectScope = "target" | "self" | "party" | "all_enemies";

export type Effect =
  | { kind: "damage"; amount: number; hits?: number }
  | { kind: "damage_all"; amount: number; hits?: number }
  | { kind: "block"; amount: number; to?: EffectScope }
  | { kind: "heal"; amount: number; to?: EffectScope }
  | { kind: "draw"; amount: number }
  | { kind: "gain_qi"; amount: number }
  | { kind: "apply"; status: DebuffStatus; amount: number; to?: "target" | "all_enemies" }
  | { kind: "strength"; amount: number; to?: EffectScope }
  | { kind: "cleanse"; to?: EffectScope }
  | { kind: "steal" }
  | { kind: "counter"; amount: number }
  | { kind: "summon_gu"; amount: number }
  | { kind: "fly_sword"; amount: number }
  | { kind: "revive"; amount: number }
  | { kind: "combo_gauge"; amount: number }
  /** 自損：percent 時 amount 是最大 HP 的百分比；最低留 1，不會因此昏迷 */
  | { kind: "self_damage"; amount: number; percent?: boolean; to?: "self" | "party" }
  | { kind: "end_turn" }
  | { kind: "add_card"; card: string; count?: number }
  | { kind: "upgrade_hand" };

export interface CardCore {
  cost: number;
  effects: Effect[];
  exhaust?: boolean;
  retain?: boolean;
}

export interface CardDef extends CardCore {
  id: string;
  name: string;
  /** null＝無主牌（紀念牌、偷來的道具…），由 HP 最高的清醒隊員出手 */
  owner: CharId | null;
  type: CardType;
  target: CardTarget;
  element?: Element;
  rarity: Rarity;
  /** 升級後覆蓋的欄位 */
  upgrade?: Partial<CardCore>;
  /** 3D 舞台播的動作：strike（近戰衝刺）、cast（施法）、guard（護身） */
  motion: "strike" | "cast" | "guard";
  /** 卡圖（public/ 底下的路徑）；缺圖時 UI 顯示純色 */
  art?: string;
  /** 正史依據（招式、事件或道具），內容審查用 */
  canon: string;
  /** 卡面附加說明（自動產生的效果文字之後） */
  note?: string;
}

export interface CardInstance {
  uid: number;
  defId: string;
  upgraded: boolean;
}

// ── 角色與敵人 ───────────────────────────────────────────────────────────────

export interface CharacterDef {
  id: CharId;
  name: string;
  maxHp: number;
  /** 戰鬥中的 3D 模型或 2D 立繪 */
  model: string;
  /** 3D 模型還沒做好時，戰鬥用的 2D 全身立繪（面向左） */
  standee?: string;
  height: number;
  /** 劇情與 HUD 用的頭像 */
  portrait: string;
  /** 合擊牌 id（由此角色發動時加入手牌） */
  comboCard: string;
}

export type IntentKind = "attack" | "attack_all" | "block" | "buff" | "debuff" | "summon" | "heal" | "charge";

export interface MoveDef {
  id: string;
  name: string;
  intent: IntentKind;
  damage?: number;
  hits?: number;
  block?: number;
  strength?: number;
  apply?: { status: DebuffStatus; amount: number; to: "target" | "party" };
  heal?: number;
  summon?: string;
}

export type Passive =
  /** 只要 fieldId 這個場地還在，HP 不會低於 1（水魔獸：在水中殺不死） */
  | { kind: "undying_while"; fieldId: string }
  /** 每回合開始回復 amount（只要 fieldId 還在；沒寫 fieldId 就無條件） */
  | { kind: "regen"; amount: number; fieldId?: string }
  /** HP 低於一半時換成 phase2Moves */
  | { kind: "phase2"; moves: string[] };

export interface EnemyDef {
  id: string;
  name: string;
  maxHp: number;
  element?: Element;
  /** 2D 立繪（.webp／.png）或 3D 模型（.glb） */
  model: string;
  height: number;
  floats?: boolean;
  /** 原圖面向（2D 立繪用） */
  imageFacesLeft?: boolean;
  moves: MoveDef[];
  /** cycle：依序輪流；weighted：依權重亂數（意圖仍會提前攤開） */
  pattern: "cycle" | "weighted";
  weights?: number[];
  passives?: Passive[];
  /** 可以被「偷」走的東西（無主牌 id），依序偷 */
  stealable?: string[];
  isBoss?: boolean;
  /** 場地（水域、血池）：不會行動、不算在勝利條件內 */
  isField?: boolean;
  /** Boss 接續：被打倒時由這隻在同一位置登場（蛇妖男 → 狐狸精），下回合才開始行動 */
  successor?: string;
  canon: string;
}

// ── 戰鬥狀態 ─────────────────────────────────────────────────────────────────

export interface StatusBag {
  strength: number;
  weak: number;
  vulnerable: number;
  poison: number;
}

export interface PartyMemberState {
  charId: CharId;
  hp: number;
  maxHp: number;
  block: number;
  status: StatusBag;
  /** 本回合受擊時反擊的傷害（月如） */
  counter: number;
  downed: boolean;
}

export interface Intent {
  moveId: string;
  /** 指定攻擊的隊員（index）；全體攻擊、自身行動為 null */
  target: number | null;
  /** 被破勢取消（一般敵人）或減半（Boss） */
  cancelled: boolean;
  halved: boolean;
}

export interface EnemyState {
  uid: number;
  defId: string;
  hp: number;
  maxHp: number;
  block: number;
  status: StatusBag;
  breakStacks: number;
  breakThreshold: number;
  breakTriggeredThisTurn: boolean;
  intent: Intent | null;
  moveCursor: number;
  phase2: boolean;
  stolen: number;
  dead: boolean;
}

export interface ChainState {
  last: Element | null;
  count: number;
}

export type BattleOutcome = "ongoing" | "won" | "lost" | "survived" | "survive_failed";

export interface BattleState {
  rng: number;
  turn: number;
  qi: number;
  maxQi: number;
  handSize: number;
  draw: CardInstance[];
  hand: CardInstance[];
  discard: CardInstance[];
  exhaust: CardInstance[];
  nextUid: number;
  party: PartyMemberState[];
  enemies: EnemyState[];
  chain: ChainState;
  comboGauge: number;
  comboMax: number;
  /** 最後一張打出的「有主」牌的主人（合擊發動者判定） */
  lastOwner: CharId | null;
  gu: number;
  flyingSwords: { amount: number; targetUid: number | null }[];
  /** 這場戰鬥中偷到、戰後要加進牌組的牌 */
  loot: string[];
  coinsGained: number;
  survive: number | null;
  outcome: BattleOutcome;
  /** 難度：敵人 HP 倍率 */
  enemyHpScale: number;
}

// ── 事件（給 3D 舞台與 HUD 播放） ─────────────────────────────────────────────

export type Side = "party" | "enemy";
export interface Ref {
  side: Side;
  index: number;
}

export type BattleEvent =
  | { type: "turn_start"; turn: number }
  | { type: "card_played"; uid: number; defId: string; actor: Ref | null; target: Ref | null }
  | { type: "damage"; target: Ref; amount: number; blocked: number; effective: "strong" | "weak" | "normal"; source: Ref | null }
  | { type: "block"; target: Ref; amount: number }
  | { type: "heal"; target: Ref; amount: number }
  | { type: "status"; target: Ref; status: Status; amount: number }
  | { type: "break"; target: Ref; result: "cancelled" | "halved" }
  | { type: "chain"; count: number; element: Element }
  | { type: "combo_ready"; charId: CharId }
  | { type: "downed"; target: Ref }
  | { type: "revived"; target: Ref }
  | { type: "enemy_died"; target: Ref }
  | { type: "enemy_move"; actor: Ref; moveId: string; target: Ref | null }
  | { type: "summon"; target: Ref }
  | { type: "steal"; target: Ref; card: string | null; coins: number }
  | { type: "gu"; count: number }
  | { type: "fly_sword"; target: Ref; amount: number }
  | { type: "counter"; actor: Ref; target: Ref; amount: number }
  | { type: "draw"; count: number }
  | { type: "outcome"; outcome: BattleOutcome };

export interface ContentDb {
  cards: Record<string, CardDef>;
  enemies: Record<string, EnemyDef>;
  characters: Record<CharId, CharacterDef>;
}

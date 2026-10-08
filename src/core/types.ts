/**
 * 遊戲的資料型別（REDESIGN §4）。內容定義（*Def）是不可變的資料；戰鬥／行程狀態是可序列化的純物件。
 */

export type CharId = "li_xiaoyao" | "zhao_linger" | "lin_yueru" | "anu" | "wuhou";
export type Element = "wind" | "thunder" | "water" | "fire" | "earth";
/** 仙劍一的控制類狀態：定身（跳過行動）、封印（不能施法）、昏睡（跳過行動，受傷即醒）、混亂（目標錯亂） */
export type ControlStatus = "stun" | "seal" | "sleep" | "confuse";
export type DebuffStatus = "weak" | "vulnerable" | "poison" | "break" | ControlStatus;
export type Status = DebuffStatus | "strength";

// ── 卡牌 ────────────────────────────────────────────────────────────────────

/** power＝心法：打出後整場戰鬥常駐，靠觸發條件生效（殺戮尖塔的能力牌） */
export type CardType = "attack" | "skill" | "spell" | "item" | "combo" | "power";
export type CardTarget = "enemy" | "all_enemies" | "self" | "ally" | "party" | "none";
export type Rarity = "starter" | "common" | "uncommon" | "rare" | "special";

/** 效果的作用對象：卡牌的「選定目標」或其他固定範圍 */
export type EffectScope = "target" | "self" | "party" | "all_enemies";

/** 流派層數（戰鬥內計數）：zhijin 指勁（月如）、swordqi 劍意（逍遙）…由資料自訂 key */
export type StackKey = string;
/** 傷害依層數加成：每層 +amount；consume 為 true 時結算後清空該層數 */
export interface StackBonus {
  key: StackKey;
  amount: number;
  consume?: boolean;
}

export type Effect =
  | { kind: "damage"; amount: number; hits?: number; per?: StackBonus }
  | { kind: "damage_all"; amount: number; hits?: number; per?: StackBonus }
  /** 累積流派層數 */
  | { kind: "stack"; key: StackKey; amount: number }
  /** 得到銅錢（戰後帶回行程） */
  | { kind: "gain_coins"; amount: number }
  /** 花銅錢（戰鬥外的錢；不夠就不能出這張牌）：銅錢鏢、乾坤一擲 */
  | { kind: "spend_coins"; amount: number }
  /** 引爆目標的中毒：造成 中毒層數 × multiplier 的傷害，並清除中毒（爆炸蠱） */
  | { kind: "detonate"; multiplier: number }
  /** 斬殺：非頭目且血量低於 below% 直接擊倒；否則造成 fallback 點傷害（奪魂） */
  | { kind: "execute"; below: number; fallback: number }
  /** 收妖煉藥：非頭目且血量低於 below% 時收進葫蘆（擊倒並得到一瓶藥）（靈葫咒） */
  | { kind: "capture"; below: number }
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

// ── 觸發（心法與法寶共用）──────────────────────────────────────────────────

/**
 * 觸發時機：turn_start／turn_end 我方回合開始、結束；play 打出一張牌（可篩選）；
 * kill 擊倒敵人；hurt 隊員受到傷害；poison_tick 敵人中毒結算；counter 隊員反擊。
 */
export type TriggerOn = "turn_start" | "turn_end" | "play" | "kill" | "hurt" | "poison_tick" | "counter";

export interface Trigger {
  on: TriggerOn;
  /** play 的篩選條件 */
  type?: CardType;
  element?: Element;
  owner?: CharId;
  /** 每 N 次才生效一次（例：每打出第 3 張攻擊牌） */
  every?: number;
  /** 單體效果打誰：front 最前面的敵人、random 隨機敵人、source 觸發的那名敵人（kill／hurt／poison_tick／counter） */
  target?: "front" | "random" | "source";
  effects: Effect[];
}

export interface PowerDef {
  triggers: Trigger[];
}

/** 戰鬥中生效的心法或法寶 */
export interface ActivePower {
  id: string;
  name: string;
  source: "card" | "relic";
  owner: CharId | null;
  triggers: Trigger[];
  /** 每個觸發各自的計數（every 用） */
  counters: number[];
}

export interface CardCore {
  cost: number;
  effects: Effect[];
  /** 心法牌的常駐效果 */
  power?: PowerDef;
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
  /** 流派（docs/ARCHETYPES.md）：獎勵依流派加權、牌面顯示；沒有＝通用 */
  archetype?: string;
  /** 卡面附加說明（自動產生的效果文字之後） */
  note?: string;
  /** 狀態牌／詛咒牌：不能打出 */
  unplayable?: boolean;
  /** 回合結束時還在手上會發生的事（例：纏絲讓持有者失去生命） */
  inHandAtTurnEnd?: Effect[];
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

/** 單體招式挑誰打：random 隨機、weakest 血量比例最低、strongest 血最多、caster 施法者（靈兒、阿奴、巫后）、front 最前面 */
export type MoveTargeting = "random" | "weakest" | "strongest" | "caster" | "front";

export interface MoveDef {
  id: string;
  name: string;
  intent: IntentKind;
  targeting?: MoveTargeting;
  damage?: number;
  hits?: number;
  block?: number;
  strength?: number;
  apply?: { status: DebuffStatus; amount: number; to: "target" | "party" };
  heal?: number;
  summon?: string;
  /** 把狀態牌塞進我方棄牌堆（殺戮尖塔的傷口、暈眩、詛咒） */
  addCard?: { card: string; count: number };
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
  /** 控制類狀態（回合數）。可選欄位：舊存檔的戰鬥狀態沒有這些欄位 */
  stun?: number;
  seal?: number;
  sleep?: number;
  confuse?: number;
  /** 定身／昏睡剛解除後的抗性回合：期間不會再被定身或昏睡（防鎖死） */
  steady?: number;
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
  /** 最近出過的招式（新到舊，最多 2 個）：避免同一招連出三次 */
  history?: string[];
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
  /** 生效中的心法與法寶觸發（舊存檔沒有這個欄位） */
  powers?: ActivePower[];
  /** 藥品欄（null＝空格；舊存檔沒有） */
  potions?: (string | null)[];
  /** 流派層數（舊存檔沒有） */
  stacks?: Record<StackKey, number>;
  /** 戰鬥開始時身上的銅錢（花銅錢的牌從這裡扣；結算時以 coinsGained 帶回行程，可為負） */
  purse?: number;
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
  | { type: "outcome"; outcome: BattleOutcome }
  | { type: "power"; id: string; name: string; actor: Ref | null }
  | { type: "stack"; key: StackKey; amount: number }
  | { type: "capture"; target: Ref; potion: string | null }
  | { type: "potion"; id: string; actor: Ref | null; target: Ref | null };

/** 藥品：不佔牌組、不花真氣，隨時可用一次（REDESIGN 戰鬥強化） */
export interface PotionDef {
  id: string;
  name: string;
  target: CardTarget;
  effects: Effect[];
  rarity: "common" | "uncommon" | "rare";
  canon: string;
  art?: string;
}

export interface ContentDb {
  cards: Record<string, CardDef>;
  potions?: Record<string, PotionDef>;
  enemies: Record<string, EnemyDef>;
  characters: Record<CharId, CharacterDef>;
}

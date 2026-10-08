import type { RelicDef } from "../core/run";

/**
 * 法寶（REDESIGN §8.0；2026-10-09 依殺戮尖塔分級，docs/ARCHETYPES.md）：全部取自正史道具或法寶。
 * - common／rare：精英戰隨機掉落（不重複）。
 * - boss：強但有代價（例：多一點真氣、少抽一張）。
 * - story：劇情、頭目固定給的法寶，不進隨機掉落。
 * 觸發型（triggers）和心法用同一套規則，用來支撐各流派。
 */
const list: RelicDef[] = [
  // ── 一般 ──
  { id: "wine_gourd", name: "酒葫蘆", tier: "common", text: "每場戰鬥開始時，全隊獲得 3 點護體。", canon: "酒劍仙的朱漆酒葫蘆",
    battleStart: [{ kind: "block", amount: 3, to: "party" }] },
  { id: "long_life_gourd", name: "壽葫蘆", tier: "common", text: "戰鬥勝利後，每位清醒的隊員回復 5 點生命。", canon: "壽葫蘆：桃源村村長所贈", afterBattleHeal: 5 },
  { id: "jade_buddha", name: "玉佛珠", tier: "story", text: "每場戰鬥開始時，全隊獲得 1 點氣勢。", canon: "玉佛珠：可裝備的靈珠之一",
    battleStart: [{ kind: "strength", amount: 1, to: "party" }] },
  { id: "aunts_ladle", name: "嬸嬸的鍋鏟", tier: "common", text: "客棧的東西打八折。", canon: "李大娘經營的客棧（本作原創）", shopDiscount: 20 },
  { id: "inn_token", name: "客棧腰牌", tier: "common", text: "戰鬥勝利後，每位清醒的隊員回復 3 點生命；客棧打九折。", canon: "餘杭鎮客棧（本作原創）",
    afterBattleHeal: 3, shopDiscount: 10 },
  { id: "silver_hairpin", name: "銀簪", tier: "common", text: "每場戰鬥開始時，使所有敵人中毒 3。", canon: "苗族銀飾（本作命名）",
    battleStart: [{ kind: "apply", status: "poison", amount: 3, to: "all_enemies" }] },
  // 流派觸發（一般）
  { id: "sword_tassel", name: "劍穗", tier: "common", text: "每打出第 3 張攻擊牌時，獲得 1 層劍意。", canon: "李逍遙劍上的劍穗（本作原創）",
    triggers: [{ on: "play", type: "attack", every: 3, effects: [{ kind: "stack", key: "swordqi", amount: 1 }] }] },
  { id: "lin_jade", name: "林家玉佩", tier: "common", text: "每場戰鬥開始時，獲得 2 層指勁。", canon: "林家堡的信物（本作原創）",
    battleStart: [{ kind: "stack", key: "zhijin", amount: 2 }] },
  { id: "coin_string", name: "銅錢串", tier: "common", text: "每擊倒一名敵人，得到 6 文。", canon: "一串制錢（本作原創）",
    triggers: [{ on: "kill", effects: [{ kind: "gain_coins", amount: 6 }] }] },

  // ── 稀有 ──
  { id: "zijin_gourd", name: "紫金葫蘆", tier: "story", text: "每場戰鬥開始時抽 1 張牌。", canon: "紫金葫蘆：蘇州支線所得，附「靈葫咒」",
    battleStart: [{ kind: "draw", amount: 1 }] },
  { id: "wind_pearl", name: "風靈珠", tier: "story", text: "每回合多抽 1 張牌。", canon: "風靈珠", handSize: 1 },
  { id: "thunder_pearl", name: "雷靈珠", tier: "story", text: "合擊氣只要 3 格就滿。", canon: "雷靈珠", comboMax: -1 },
  { id: "water_pearl", name: "水靈珠", tier: "story", text: "每場戰鬥開始時，全隊回復 4 點生命。", canon: "水靈珠",
    battleStart: [{ kind: "heal", amount: 4, to: "party" }] },
  { id: "fire_pearl", name: "火靈珠", tier: "story", text: "每場戰鬥開始時，使所有敵人破綻 1。", canon: "火靈珠",
    battleStart: [{ kind: "apply", status: "vulnerable", amount: 1, to: "all_enemies" }] },
  { id: "earth_pearl", name: "土靈珠", tier: "story", text: "每場戰鬥開始時，全隊獲得 6 點護體。", canon: "土靈珠：赤鬼王所掉落",
    battleStart: [{ kind: "block", amount: 6, to: "party" }] },
  { id: "twin_dragon_sword", name: "雙龍劍", tier: "rare", text: "每場戰鬥開始時，獲得 2 點氣勢。", canon: "雙龍劍：鎖妖塔第一層寶物",
    battleStart: [{ kind: "strength", amount: 2 }] },
  { id: "seven_star_sword", name: "七星劍", tier: "rare", text: "每場戰鬥開始時，御劍：下回合對最前面的敵人造成 10 點傷害。", canon: "七星劍：李逍遙的劍",
    battleStart: [{ kind: "fly_sword", amount: 10 }] },
  { id: "sky_snake_staff", name: "天蛇杖", tier: "story", text: "每場戰鬥開始時，使所有敵人弱化 1。", canon: "天蛇杖：限女媧後人使用",
    battleStart: [{ kind: "apply", status: "weak", amount: 1, to: "all_enemies" }] },
  { id: "parents_scroll", name: "父母的手卷", tier: "story", text: "每場戰鬥開始時，獲得 1 點真氣、抽 1 張牌。", canon: "逍遙父母留下的手卷（冰心訣、飛龍探雲手）",
    battleStart: [{ kind: "gain_qi", amount: 1 }, { kind: "draw", amount: 1 }] },
  { id: "butterfly_hairpin", name: "彩蝶髮簪", tier: "story", text: "每場戰鬥開始時，全隊回復 3 點生命並解除負面狀態。", canon: "彩依（蝶精）的遺物（本作原創）",
    battleStart: [{ kind: "heal", amount: 3, to: "party" }, { kind: "cleanse", to: "party" }] },
  { id: "phoenix_feather", name: "金翅鳳凰羽", tier: "story", text: "每場戰鬥開始時，全隊獲得 4 點護體、1 點氣勢。", canon: "靈山神木林金翅鳳凰（本作原創）",
    battleStart: [{ kind: "block", amount: 4, to: "party" }, { kind: "strength", amount: 1, to: "party" }] },
  // 流派觸發（稀有）
  { id: "gu_jar", name: "苗疆蠱罐", tier: "rare", text: "每回合開始時，召喚 1 隻蠱蟲。", canon: "苗族養蠱的陶罐（本作原創）",
    triggers: [{ on: "turn_start", effects: [{ kind: "summon_gu", amount: 1 }] }] },
  { id: "spirit_bell", name: "攝魂鈴", tier: "rare", text: "每擊倒一名敵人，使隨機一名敵人混亂 1。", canon: "苗疆巫師的法鈴（本作原創）",
    triggers: [{ on: "kill", target: "random", effects: [{ kind: "apply", status: "confuse", amount: 1 }] }] },
  { id: "five_charm", name: "五靈護符", tier: "rare", text: "每打出第 4 張仙術牌時，抽 1 張牌、獲得 1 點真氣。", canon: "女媧族的護符（本作原創）",
    triggers: [{ on: "play", type: "spell", every: 4, effects: [{ kind: "draw", amount: 1 }, { kind: "gain_qi", amount: 1 }] }] },

  // ── 劇情給的女媧族聖物 ──
  { id: "holy_pearl", name: "聖靈珠", tier: "story", text: "每回合多 1 點真氣。", canon: "聖靈珠：女媧族聖物", maxQi: 1 },
  { id: "nuwa_stone", name: "女媧石", tier: "story", text: "每場戰鬥開始時，召喚 1 隻蠱蟲並抽 1 張牌。", canon: "女媧石：女媧族聖物",
    battleStart: [{ kind: "summon_gu", amount: 1 }, { kind: "draw", amount: 1 }] },
  // 頭目三選一的法寶（強但有代價）在頭目獎勵畫面完成後加入（docs/ARCHETYPES.md 實作順序 4）
];

export const RELICS: Record<string, RelicDef> = Object.fromEntries(list.map((r) => [r.id, r]));

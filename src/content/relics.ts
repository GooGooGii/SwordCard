import type { RelicDef } from "../core/run";

/**
 * 法寶 20 件（REDESIGN §8.0）：全部取自正史道具或法寶，只有被動效果。
 * 主要由頭目戰、支線、劇情取得。
 */
const list: RelicDef[] = [
  { id: "wine_gourd", name: "酒葫蘆", text: "每場戰鬥開始時，全隊獲得 3 點護體。", canon: "酒劍仙的朱漆酒葫蘆",
    battleStart: [{ kind: "block", amount: 3, to: "party" }] },
  { id: "long_life_gourd", name: "壽葫蘆", text: "戰鬥勝利後，每位清醒的隊員回復 5 點生命。", canon: "壽葫蘆：桃源村村長所贈", afterBattleHeal: 5 },
  { id: "zijin_gourd", name: "紫金葫蘆", text: "每場戰鬥開始時抽 1 張牌。", canon: "紫金葫蘆：蘇州支線所得，附「靈葫咒」",
    battleStart: [{ kind: "draw", amount: 1 }] },
  { id: "jade_buddha", name: "玉佛珠", text: "每場戰鬥開始時，全隊獲得 1 點氣勢。", canon: "玉佛珠：可裝備的靈珠之一",
    battleStart: [{ kind: "strength", amount: 1, to: "party" }] },
  { id: "wind_pearl", name: "風靈珠", text: "每回合多抽 1 張牌。", canon: "風靈珠", handSize: 1 },
  { id: "thunder_pearl", name: "雷靈珠", text: "合擊氣只要 3 格就滿。", canon: "雷靈珠", comboMax: -1 },
  { id: "water_pearl", name: "水靈珠", text: "每場戰鬥開始時，全隊回復 4 點生命。", canon: "水靈珠",
    battleStart: [{ kind: "heal", amount: 4, to: "party" }] },
  { id: "fire_pearl", name: "火靈珠", text: "每場戰鬥開始時，使所有敵人破綻 1。", canon: "火靈珠",
    battleStart: [{ kind: "apply", status: "vulnerable", amount: 1, to: "all_enemies" }] },
  { id: "earth_pearl", name: "土靈珠", text: "每場戰鬥開始時，全隊獲得 6 點護體。", canon: "土靈珠：赤鬼王所掉落",
    battleStart: [{ kind: "block", amount: 6, to: "party" }] },
  { id: "holy_pearl", name: "聖靈珠", text: "每回合多 1 點真氣。", canon: "聖靈珠：女媧族聖物", maxQi: 1 },
  { id: "nuwa_stone", name: "女媧石", text: "每場戰鬥開始時，召喚 1 隻蠱蟲並抽 1 張牌。", canon: "女媧石：女媧族聖物",
    battleStart: [{ kind: "summon_gu", amount: 1 }, { kind: "draw", amount: 1 }] },
  { id: "twin_dragon_sword", name: "雙龍劍", text: "每場戰鬥開始時，獲得 2 點氣勢。", canon: "雙龍劍：鎖妖塔第一層寶物",
    battleStart: [{ kind: "strength", amount: 2 }] },
  { id: "seven_star_sword", name: "七星劍", text: "每場戰鬥開始時，御劍：下回合對最前面的敵人造成 10 點傷害。", canon: "七星劍：李逍遙的劍",
    battleStart: [{ kind: "fly_sword", amount: 10 }] },
  { id: "sky_snake_staff", name: "天蛇杖", text: "每場戰鬥開始時，使所有敵人弱化 1。", canon: "天蛇杖：限女媧後人使用",
    battleStart: [{ kind: "apply", status: "weak", amount: 1, to: "all_enemies" }] },
  { id: "silver_hairpin", name: "銀簪", text: "每場戰鬥開始時，使所有敵人中毒 3。", canon: "苗族銀飾（本作命名）",
    battleStart: [{ kind: "apply", status: "poison", amount: 3, to: "all_enemies" }] },
  { id: "aunts_ladle", name: "嬸嬸的鍋鏟", text: "客棧的東西打八折。", canon: "李大娘經營的客棧（本作原創）", shopDiscount: 20 },
  { id: "inn_token", name: "客棧腰牌", text: "戰鬥勝利後，每位清醒的隊員回復 3 點生命；客棧打九折。", canon: "餘杭鎮客棧（本作原創）",
    afterBattleHeal: 3, shopDiscount: 10 },
  { id: "parents_scroll", name: "父母的手卷", text: "每場戰鬥開始時，獲得 1 點真氣、抽 1 張牌。", canon: "逍遙父母留下的手卷（冰心訣、飛龍探雲手）",
    battleStart: [{ kind: "gain_qi", amount: 1 }, { kind: "draw", amount: 1 }] },
  { id: "butterfly_hairpin", name: "彩蝶髮簪", text: "每場戰鬥開始時，全隊回復 3 點生命並解除負面狀態。", canon: "彩依（蝶精）的遺物（本作原創）",
    battleStart: [{ kind: "heal", amount: 3, to: "party" }, { kind: "cleanse", to: "party" }] },
  { id: "phoenix_feather", name: "金翅鳳凰羽", text: "每場戰鬥開始時，全隊獲得 4 點護體、1 點氣勢。", canon: "靈山神木林金翅鳳凰（本作原創）",
    battleStart: [{ kind: "block", amount: 4, to: "party" }, { kind: "strength", amount: 1, to: "party" }] },
];

export const RELICS: Record<string, RelicDef> = Object.fromEntries(list.map((r) => [r.id, r]));

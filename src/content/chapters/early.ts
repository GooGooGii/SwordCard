import type { ChapterDef } from "../../core/run/types";
import { battleNode, innNode, storyNode } from "./helpers";

/** 教學提示（REDESIGN §5.1）：每種機制第一次出現的戰鬥，開場顯示一次 */
const TIPS = {
  first: [
    "把手牌往上拖、或點一下再點目標，就能出牌。每張牌左上角是要花的真氣，每回合有 3 點。",
    "敵人頭上寫著下一步要做什麼、打誰、打多少。看清楚再決定先打誰、要不要防守。",
  ],
  elements: [
    "護體可以擋下傷害，回合開始時歸零。被瞄準的人才需要護體。",
    "五靈相剋：風剋雷、雷剋水、水剋火、火剋土、土剋風。剋制時傷害 ×1.5，還會給敵人「破勢」。",
    "酒甕屬風——用土靈符剋它。破勢累積滿了，一般敵人的下一個意圖會被取消。",
  ],
  party: [
    "兩人同場：敵人會指明打誰，護體牌可以選要給誰。",
    "不同角色的牌交替打出，會累積「合擊氣」。",
  ],
  chain: [
    "相生連鎖：依「風→火→雷→土→水→風」的順序連續出仙術，每接一環，傷害與護體都 +連鎖數。左上的五靈輪會標出下一環。",
    "靈兒五系仙術俱全，是接連鎖的主力。",
  ],
  steal: ["飛龍探雲手可以偷敵人身上的東西：偷到的道具牌會留在牌組裡；偷光了就只能摸到幾文錢。"],
  survive: ["這是求生戰：撐過指定回合數就算過關。打不倒也沒關係——全員倒下時故事也會繼續，只是少拿獎勵。"],
  combo: [
    "合擊氣滿了，最後出牌的那個人的合擊牌會加入手牌：全隊一起出手，代價是每人扣 10% 生命並結束回合。",
    "有人昏迷或生命低於兩成時不能合擊。",
  ],
};

/**
 * 序章～第三章。教學節奏照 REDESIGN §5.1：
 * 序章第 1 戰出牌與意圖、第 2 戰相剋與破勢（酒甕屬風，土靈符剋它）、客棧之戰兩人同場；
 * 第一章相生連鎖與偷；第二章第一次合擊。
 */
export const PROLOGUE: ChapterDef = {
  id: "prologue",
  title: "序章　仙靈奇緣",
  epigraph: "霧裡的桃花，酒裡的紅燭。少年醒來，只記得一場夢。",
  subtitle: "餘杭盛漁村・仙靈島・十里坡",
  map: "/assets/maps/prologue.jpg",
  music: "yuhang",
  start: "p_morning",
  end: "p_inn",
  rarity: { common: 80, uncommon: 20, rare: 0 },
  coins: { normal: 10, elite: 18, boss: 24 },
  nodes: [
    storyNode("p_morning", "餘杭客棧", [0.16, 0.6], ["p_maze"]),
    battleNode("p_maze", "仙靈島迷陣", [0.62, 0.42], ["p_island"], { enemies: ["grass_imp", "grass_imp"], ground: "xianling", intro: "p_maze", tips: TIPS.first }),
    storyNode("p_island", "水月宮", [0.8, 0.2], ["p_shilipo"]),
    battleNode("p_shilipo", "十里坡", [0.38, 0.74], ["p_swordgod", "p_temple"], { enemies: ["wine_jar", "bee"], ground: "shilipo", tips: TIPS.elements }),
    battleNode("p_swordgod", "十里坡劍神", [0.2, 0.88], ["p_temple"], { enemies: ["bee", "cocoon", "bee"], ground: "shilipo", intro: "p_swordgod", reward: { coins: 15 } }, true),
    storyNode("p_temple", "山神廟", [0.5, 0.9], ["p_inn"]),
    battleNode("p_inn", "客棧之戰", [0.22, 0.4], [], {
      enemies: ["fat_miao", "miao_fist"], ground: "yuhang_inn", boss: true, intro: "p_inn_intro", outro: "p_inn_outro", tips: TIPS.party,
    }),
  ],
};

export const CH1: ChapterDef = {
  id: "ch1",
  title: "第一章　比武招親",
  epigraph: "擂台上的紅綢，月光下的蛇影。有些事，看見了就回不去。",
  subtitle: "仙靈島・蘇州・林家堡",
  map: "/assets/maps/ch1.jpg",
  music: "suzhou",
  start: "c1_return",
  end: "c1_night",
  rarity: { common: 75, uncommon: 23, rare: 2 },
  coins: { normal: 10, elite: 18, boss: 26 },
  nodes: [
    battleNode("c1_return", "水月宮", [0.86, 0.3], ["c1_road"], {
      enemies: ["miao_fist", "miao_fist"], ground: "xianling", intro: "c1_return", outro: "c1_granny", tips: TIPS.chain,
    }),
    battleNode("c1_road", "蘇州城外", [0.62, 0.5], ["c1_thugs", "c1_inn"], {
      enemies: ["yueru_whip"], ground: "suzhou_road", elite: true, intro: "c1_road_intro", outro: "c1_road_outro", tips: TIPS.steal,
    }),
    battleNode("c1_thugs", "城門無賴", [0.48, 0.78], ["c1_inn"], { enemies: ["knife_thug", "kick_thug"], ground: "suzhou_road", intro: "c1_thugs" }, true),
    innNode("c1_inn", "蘇州客棧", [0.38, 0.5], ["c1_arena"]),
    battleNode("c1_arena", "比武招親", [0.26, 0.28], ["c1_night"], {
      enemies: ["yueru_sword"], ground: "lin_arena", elite: true, intro: "c1_suzhou", outro: "c1_arena_outro",
    }),
    battleNode("c1_night", "林家堡西廂", [0.12, 0.56], [], {
      enemies: ["snake_linger"], ground: "lin_arena", survive: 3, boss: true, intro: "c1_night_intro", outro: "c1_night_outro", tips: TIPS.survive,
    }),
  ],
};

export const CH2: ChapterDef = {
  id: "ch2",
  title: "第二章　隱龍窟",
  epigraph: "為了找一個人，走進最深的黑。",
  subtitle: "隱龍窟・白河村",
  map: "/assets/maps/ch2.jpg",
  music: "cave",
  start: "c2_depart",
  end: "c2_inn",
  rarity: { common: 70, uncommon: 26, rare: 4 },
  coins: { normal: 11, elite: 20, boss: 30 },
  nodes: [
    storyNode("c2_depart", "林家堡", [0.1, 0.5], ["c2_road"]),
    battleNode("c2_road", "蘇州郊外", [0.26, 0.36], ["c2_cave"], { enemies: ["furball", "bee", "bee"], ground: "suzhou_road", outro: "c2_road_outro", tips: TIPS.combo }),
    battleNode("c2_cave", "隱龍窟", [0.44, 0.24], ["c2_slime", "c2_hydra"], { enemies: ["green_snake", "red_snake"], ground: "yinlong_cave", intro: "c2_cave_intro" }),
    battleNode("c2_slime", "窟中岔路", [0.56, 0.1], ["c2_boss"], { enemies: ["red_slime", "green_snake"], ground: "yinlong_cave" }),
    battleNode("c2_hydra", "九頭蛇巢", [0.58, 0.44], ["c2_boss"], {
      enemies: ["hydra"], ground: "yinlong_cave", elite: true, reward: { relic: "wind_pearl" },
    }),
    battleNode("c2_boss", "窟底", [0.78, 0.26], ["c2_baihe"], {
      enemies: ["snake_man"], ground: "yinlong_cave", boss: true, intro: "c2_boss_intro", outro: "c2_boss_outro",
    }),
    storyNode("c2_baihe", "白河村", [0.8, 0.66], ["c2_tiger", "c2_inn"]),
    battleNode("c2_tiger", "村外林子", [0.64, 0.86], ["c2_inn"], { enemies: ["tiger"], ground: "baihe", elite: true, intro: "c2_tiger" }, true),
    innNode("c2_inn", "白河村客棧", [0.48, 0.7], []),
  ],
};

export const CH3: ChapterDef = {
  id: "ch3",
  title: "第三章　血池",
  epigraph: "死去的人不肯安息，是因為有人還在利用他們。",
  subtitle: "玉佛寺・黑水鎮・將軍塚",
  map: "/assets/maps/ch3.jpg",
  music: "ghost",
  start: "c3_yufo",
  end: "c3_bloodpool",
  rarity: { common: 62, uncommon: 32, rare: 6 },
  coins: { normal: 11, elite: 21, boss: 34 },
  nodes: [
    storyNode("c3_yufo", "玉佛寺", [0.14, 0.26], ["c3_spar", "c3_heishui"]),
    battleNode("c3_spar", "寺中切磋", [0.1, 0.62], ["c3_heishui"], {
      enemies: ["staff_monk", "red_lama", "grey_lama"], ground: "baihe", elite: true, intro: "c3_spar",
    }, true),
    battleNode("c3_heishui", "黑水鎮", [0.34, 0.5], ["c3_graveyard"], {
      enemies: ["zombie", "ripper"], ground: "graveyard", intro: "c3_heishui", outro: "c3_heishui_outro",
    }),
    battleNode("c3_graveyard", "亂葬崗", [0.48, 0.76], ["c3_inn"], { enemies: ["cleaver_granny", "flying_head"], ground: "graveyard" }),
    innNode("c3_inn", "黑水鎮客棧", [0.58, 0.5], ["c3_tomb"]),
    battleNode("c3_tomb", "將軍塚", [0.7, 0.28], ["c3_king"], {
      enemies: ["zombie_soldier", "white_ghost", "zombie_soldier"], ground: "general_tomb", intro: "c3_tomb_intro",
    }),
    battleNode("c3_king", "墓室", [0.86, 0.42], ["c3_bloodpool"], {
      enemies: ["jiangshi_king"], ground: "general_tomb", elite: true, intro: "c3_king_intro", outro: "c3_king_outro", reward: { cards: ["item_herb"] },
    }),
    battleNode("c3_bloodpool", "血池", [0.84, 0.76], [], {
      enemies: ["red_ghost_king", "blood_pool"], ground: "blood_pool", boss: true, outro: "c3_end",
    }),
  ],
};

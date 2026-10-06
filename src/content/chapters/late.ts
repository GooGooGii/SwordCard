import type { ChapterDef } from "../../core/run/types";
import { battleNode, eventNode, innNode, storyNode } from "./helpers";

/** 第四章～終章 */
export const CH4: ChapterDef = {
  id: "ch4",
  title: "第四章　離散",
  epigraph: "這一次，是她先放開了手。",
  subtitle: "鬼陰山・揚州・蛤蟆山・山中野店",
  map: "/assets/maps/ch4.jpg",
  music: "journey",
  start: "c4_gate",
  end: "c4_shi",
  rarity: { common: 56, uncommon: 36, rare: 8 },
  coins: { normal: 12, elite: 22, boss: 36 },
  nodes: [
    battleNode("c4_gate", "鬼陰山", [0.12, 0.34], ["c4_altar"], { enemies: ["miao_spear", "knife_thug"], ground: "guiyin", intro: "c4_guiyin" }),
    battleNode("c4_altar", "鬼陰壇", [0.26, 0.16], ["c4_yz_out", "c4_yangzhou"], {
      enemies: ["sword_guard", "miao_fist", "miao_spear"], ground: "guiyin", elite: true, intro: "c4_altar_intro", outro: "c4_altar_outro",
    }),
    battleNode("c4_yz_out", "揚州城外", [0.36, 0.58], ["c4_yangzhou"], { enemies: ["earth_imp", "earth_imp"], ground: "yangzhou", intro: "c4_yz_out" }, true),
    battleNode("c4_yangzhou", "揚州夜市", [0.52, 0.42], ["c4_inn"], {
      enemies: ["ji_sanniang", "black_thief"], ground: "yangzhou", elite: true, intro: "c4_yangzhou", outro: "c4_yangzhou_outro",
    }),
    innNode("c4_inn", "揚州客棧", [0.6, 0.7], ["c4_toad"]),
    battleNode("c4_toad", "蛤蟆山", [0.78, 0.4], ["c4_shi"], {
      enemies: ["toad_mother", "golden_toad"], ground: "toad_hill", boss: true, intro: "c4_toad_intro",
    }),
    battleNode("c4_shi", "山中野店", [0.9, 0.72], [], {
      enemies: ["shi_elder"], ground: "yuhang_inn", survive: 5, boss: true, intro: "c4_inn_intro", outro: "c4_inn_outro",
    }),
  ],
};

export const CH5: ChapterDef = {
  id: "ch5",
  title: "第五章　蝶戀",
  epigraph: "一千年，換你十年。",
  subtitle: "林家堡・京城・黑蜘蛛森林",
  map: "/assets/maps/ch5.jpg",
  music: "butterfly",
  start: "c5_home",
  end: "c5_butterfly",
  rarity: { common: 50, uncommon: 40, rare: 10 },
  coins: { normal: 12, elite: 22, boss: 38 },
  nodes: [
    battleNode("c5_home", "林家堡", [0.12, 0.62], ["c5_capital"], {
      enemies: ["lin_tiannan"], ground: "lin_arena", survive: 7, elite: true, intro: "c5_home", outro: "c5_home_outro",
    }),
    battleNode("c5_capital", "尚書府", [0.34, 0.26], ["c5_inn"], {
      enemies: ["caiyi_moth"], ground: "ministry", survive: 4, elite: true, intro: "c5_capital", outro: "c5_capital_outro",
    }),
    innNode("c5_inn", "京城客棧", [0.46, 0.56], ["c5_forest"]),
    battleNode("c5_forest", "黑蜘蛛森林", [0.62, 0.72], ["c5_black"], {
      enemies: ["small_spider", "web_spider", "tree_imp"], ground: "spider_forest", intro: "c5_forest_intro",
    }),
    battleNode("c5_black", "蛛網深處", [0.74, 0.44], ["c5_spider"], { enemies: ["black_spider"], ground: "spider_forest", elite: true }),
    battleNode("c5_spider", "枯樹洞", [0.88, 0.62], ["c5_butterfly"], {
      enemies: ["du_niangzi"], ground: "spider_forest", survive: 7, boss: true, intro: "c5_spider_intro", outro: "c5_spider_outro",
    }),
    storyNode("c5_butterfly", "尚書府", [0.5, 0.14], []),
  ],
};

export const CH6: ChapterDef = {
  id: "ch6",
  title: "第六章　鎖妖塔",
  epigraph: "塔倒下的時候，有人永遠留在了碎石底下。",
  subtitle: "蜀山・鎖妖塔・聖姑家",
  map: "/assets/maps/ch6.jpg",
  music: "tower",
  start: "c6_shushan",
  end: "c6_dragons",
  rarity: { common: 45, uncommon: 42, rare: 13 },
  coins: { normal: 13, elite: 24, boss: 40 },
  nodes: [
    storyNode("c6_shushan", "蜀山", [0.1, 0.3], ["c6_bridge"]),
    battleNode("c6_bridge", "鐵索陣", [0.24, 0.52], ["c6_floor"], { enemies: ["drunk_arhat", "thunder_imp", "thunder_imp"], ground: "demon_tower" }),
    battleNode("c6_floor", "鎖妖塔", [0.38, 0.36], ["c6_jiang", "c6_frog"], {
      enemies: ["xingtian", "sickle_weasel"], ground: "demon_tower", intro: "c6_tower_intro",
    }),
    battleNode("c6_jiang", "劍老頭", [0.46, 0.66], ["c6_tiangui"], {
      enemies: ["jiang_qing"], ground: "demon_tower", elite: true, intro: "c6_jiang", reward: { relic: "seven_star_sword" },
    }),
    battleNode("c6_frog", "蛙鳴之層", [0.54, 0.16], ["c6_tiangui"], { enemies: ["hop_frog", "hammer_warrior"], ground: "demon_tower" }),
    battleNode("c6_tiangui", "鬼皇之層", [0.62, 0.44], ["c6_linger"], {
      enemies: ["tiangui"], ground: "demon_tower", survive: 6, elite: true, intro: "c6_tiangui_intro",
    }),
    storyNode("c6_linger", "封印石室", [0.72, 0.22], ["c6_spring", "c6_mingwang"]),
    eventNode("c6_spring", "女媧之泉", [0.76, 0.6], ["c6_mingwang"]),
    battleNode("c6_mingwang", "塔頂", [0.88, 0.3], ["c6_dragons"], {
      enemies: ["mingwang"], ground: "tower_top", boss: true, intro: "c6_mingwang_intro", outro: "c6_mingwang_outro",
    }),
    battleNode("c6_dragons", "七星磐龍陣", [0.9, 0.72], [], { enemies: ["wind_dragon"], ground: "tower_top", boss: true, outro: "c6_collapse" }),
  ],
};

export const CH7: ChapterDef = {
  id: "ch7",
  title: "第七章　十年",
  epigraph: "十年前的那場雨，到今天還沒有停。",
  subtitle: "靈山・大理・火麒麟洞・十年前的南詔",
  map: "/assets/maps/ch7.jpg",
  music: "nanzhao",
  start: "c7_alone",
  end: "c7_beast",
  rarity: { common: 40, uncommon: 44, rare: 16 },
  coins: { normal: 13, elite: 25, boss: 42 },
  nodes: [
    storyNode("c7_alone", "聖姑家", [0.08, 0.5], ["c7_forest"]),
    // 月如身亡後，額外給一次選牌補回牌組厚度（REDESIGN §2.2）
    battleNode("c7_forest", "神木林", [0.2, 0.32], ["c7_phoenix"], {
      enemies: ["birdman", "purple_phoenix"], ground: "sacred_forest", intro: "c7_forest", reward: { cardChoices: 2 },
    }),
    battleNode("c7_phoenix", "鳳凰巢", [0.3, 0.12], ["c7_dali"], {
      enemies: ["golden_phoenix"], ground: "sacred_forest", boss: true, intro: "c7_anu", outro: "c7_anu_join",
    }),
    storyNode("c7_dali", "大理", [0.44, 0.38], ["c7_spy", "c7_inn"]),
    battleNode("c7_spy", "大理暗巷", [0.38, 0.7], ["c7_inn"], { enemies: ["spy_miao"], ground: "nanzhao_palace", elite: true, intro: "c7_spy" }, true),
    innNode("c7_inn", "大理客棧", [0.54, 0.6], ["c7_cave"]),
    battleNode("c7_cave", "火麒麟洞", [0.66, 0.78], ["c7_qilin"], { enemies: ["fire_jiao", "root", "thunder_wyrm"], ground: "qilin_cave" }),
    battleNode("c7_qilin", "麒麟洞底", [0.76, 0.52], ["c7_past"], { enemies: ["qilin"], ground: "qilin_cave", boss: true, intro: "c7_qilin_intro" }),
    battleNode("c7_past", "十年前的南詔", [0.84, 0.26], ["c7_beast"], {
      enemies: ["fat_miao_past", "miao_spear_past"], ground: "nanzhao_palace", intro: "c7_shrine",
    }),
    battleNode("c7_beast", "城外大水", [0.92, 0.6], [], {
      enemies: ["water_beast", "water_field"], ground: "water_maze", boss: true, intro: "c7_wuhou", outro: "c7_seal",
    }),
  ],
};

export const FINALE: ChapterDef = {
  id: "finale",
  title: "終章　拜月",
  epigraph: "女媧的女兒，生來就要守護蒼生。",
  subtitle: "試煉窟・女媧神殿・南詔王宮",
  map: "/assets/maps/finale.jpg",
  music: "finale",
  start: "f_wake",
  end: "f_baiyue",
  rarity: { common: 35, uncommon: 45, rare: 20 },
  coins: { normal: 14, elite: 26, boss: 45 },
  nodes: [
    storyNode("f_wake", "白苗寨", [0.08, 0.56], ["f_trial"]),
    battleNode("f_trial", "試煉窟", [0.22, 0.32], ["f_trial2"], { enemies: ["earth_spider", "poison_centipede"], ground: "trial_cave", intro: "f_trial" }),
    battleNode("f_trial2", "試煉窟深處", [0.36, 0.5], ["f_temple"], { enemies: ["purple_hydra", "poison_centipede"], ground: "trial_cave", elite: true }),
    storyNode("f_temple", "女媧神殿", [0.46, 0.2], ["f_inn"]),
    innNode("f_inn", "白苗寨", [0.54, 0.56], ["f_gate"]),
    battleNode("f_gate", "王宮門前", [0.66, 0.76], ["f_beast"], {
      enemies: ["gai_luojiao", "poison_scorpion"], ground: "nanzhao_palace", boss: true, intro: "f_palace",
    }),
    battleNode("f_beast", "宮前廣場", [0.74, 0.48], ["f_throne"], { enemies: ["earth_beast"], ground: "nanzhao_palace", boss: true, intro: "f_beast_intro" }),
    battleNode("f_throne", "王座", [0.84, 0.28], ["f_baiyue"], {
      enemies: ["tree_demon", "royal_guard"], ground: "nanzhao_palace", boss: true, intro: "f_throne",
    }),
    battleNode("f_baiyue", "祭壇", [0.92, 0.1], [], {
      enemies: ["baiyue"], ground: "nanzhao_palace", boss: true, intro: "f_baiyue_intro", outro: "f_ending",
    }),
  ],
};

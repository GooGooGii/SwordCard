/**
 * 劇情背景：劇本裡的 bg id → 實際圖檔＋色調。
 * 同一個地點的日夜、明暗變化共用一張圖，由畫面疊色調（省素材，REDESIGN §6.4）。
 * 圖檔清單與每張要畫什麼見 docs/ART_LIST.md（ART-002，Codex 製作）。
 */
export type Tint = "night" | "dark" | "dusk" | "rain" | "dawn" | "fire";

export interface StoryBackground {
  image: string;
  tint?: Tint;
}

const img = (id: string) => `/assets/story/${id}.jpg`;
const at = (id: string, tint?: Tint): StoryBackground => (tint ? { image: img(id), tint } : { image: img(id) });

export const STORY_BACKGROUNDS: Record<string, StoryBackground> = {
  // 序章
  yuhang_inn_hall: at("yuhang_inn_hall"),
  yuhang_inn_kitchen: at("yuhang_inn_hall", "dark"),
  yuhang_inn_night: at("yuhang_inn_hall", "night"),
  yuhang_epilogue: at("yuhang_inn_front", "dawn"),
  xianling_fog: at("xianling_fog"),
  xianling_pool: at("xianling_pool"),
  shuiyue_palace: at("shuiyue_palace"),
  shilipo_path: at("shilipo_path"),
  mountain_temple: at("mountain_temple"),
  // 第一章
  shuiyue_ruin: at("shuiyue_ruin"),
  suzhou_outskirts: at("suzhou_outskirts"),
  suzhou_street: at("suzhou_street"),
  lin_manor: at("lin_manor"),
  lin_manor_night: at("lin_manor", "night"),
  // 第二章
  yinlong_cave: at("yinlong_cave"),
  yinlong_cave_deep: at("yinlong_cave", "dark"),
  baihe_village: at("baihe_village"),
  baihe_house: at("baihe_village", "dusk"),
  // 第三章
  yufo_temple: at("yufo_temple"),
  heishui_town: at("heishui_town"),
  general_tomb: at("general_tomb"),
  general_tomb_hall: at("general_tomb", "dark"),
  blood_pool: at("blood_pool"),
  // 第四章
  guiyin_mountain: at("guiyin_mountain"),
  guiyin_altar: at("guiyin_altar"),
  yangzhou_night: at("yangzhou_night"),
  toad_mountain: at("toad_mountain"),
  mountain_inn: at("mountain_inn"),
  mountain_inn_ruin: at("mountain_inn", "dusk"),
  // 第五章
  capital_mansion: at("capital_mansion"),
  capital_mansion_night: at("capital_mansion", "night"),
  spider_forest: at("spider_forest"),
  spider_lair: at("spider_forest", "dark"),
  // 第六章
  shushan: at("shushan"),
  demon_tower: at("demon_tower"),
  demon_tower_hall: at("demon_tower", "dark"),
  demon_tower_cell: at("demon_tower", "dark"),
  demon_tower_collapse: at("demon_tower", "fire"),
  tower_top: at("tower_top"),
  shenggu_house: at("shenggu_house"),
  // 第七章
  sacred_forest: at("sacred_forest"),
  dali_town: at("dali_town"),
  qilin_cave: at("qilin_cave"),
  nuwa_shrine: at("nuwa_shrine"),
  nanzhao_past: at("nanzhao_city", "rain"),
  nanzhao_palace_past: at("nanzhao_palace", "rain"),
  nanzhao_flood: at("nanzhao_flood"),
  // 終章
  dali_white_miao: at("dali_white_miao"),
  trial_cave: at("trial_cave"),
  nuwa_temple: at("nuwa_temple"),
  nanzhao_palace: at("nanzhao_palace"),
  nanzhao_throne: at("nanzhao_throne"),
  nanzhao_altar: at("nanzhao_altar", "night"),
  nanzhao_dawn: at("nanzhao_city", "dawn"),
};

/** 所有需要畫的圖（去重） */
export const STORY_IMAGES: string[] = [...new Set(Object.values(STORY_BACKGROUNDS).map((b) => b.image))];

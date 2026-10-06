import type { CharId, CharacterDef } from "../core/types";

/**
 * 可操作角色（REDESIGN §4.3、§12）。HP 以序章為準，之後每章 +4。
 * 巫后只在第七章「十年前的南詔」臨時入隊。
 */
export const CHARACTERS: Record<CharId, CharacterDef> = {
  li_xiaoyao: {
    id: "li_xiaoyao",
    name: "李逍遙",
    maxHp: 72,
    model: "/assets/characters/li_xiaoyao_style_d_ready_v2.glb",
    standee: "/assets/characters/li_xiaoyao_standee.webp",
    height: 1.75,
    portrait: "/assets/portraits/li_xiaoyao.webp",
    comboCard: "li_combo",
  },
  zhao_linger: {
    id: "zhao_linger",
    name: "趙靈兒",
    maxHp: 58,
    model: "/assets/characters/zhao_linger_style_d_v3.glb",
    standee: "/assets/characters/zhao_linger_standee.webp",
    height: 1.58,
    portrait: "/assets/portraits/zhao_linger.webp",
    comboCard: "ling_combo",
  },
  lin_yueru: {
    id: "lin_yueru",
    name: "林月如",
    maxHp: 68,
    model: "/assets/characters/lin_yueru_style_d_v4.glb",
    standee: "/assets/characters/lin_yueru_standee.webp",
    height: 1.66,
    portrait: "/assets/portraits/lin_yueru.webp",
    comboCard: "yue_combo",
  },
  anu: {
    id: "anu",
    name: "阿奴",
    maxHp: 64,
    model: "/assets/characters/anu_style_d_v3.glb",
    standee: "/assets/characters/anu_standee.webp",
    height: 1.55,
    portrait: "/assets/portraits/anu.webp",
    comboCard: "anu_combo",
  },
  wuhou: {
    id: "wuhou",
    name: "巫后",
    maxHp: 90,
    model: "/assets/characters/wuhou_style_d_v3.glb",
    standee: "/assets/characters/wuhou_standee.webp",
    height: 1.7,
    portrait: "/assets/portraits/wuhou.webp",
    comboCard: "wuhou_combo",
  },
};

/** 劇情裡出場的配角（只有頭像與名字） */
export const NPCS: Record<string, { name: string; portrait: string }> = {
  aunt: { name: "李大娘", portrait: "/assets/portraits/aunt.webp" },
  drunk: { name: "酒劍仙", portrait: "/assets/portraits/drunk.webp" },
  granny: { name: "姥姥", portrait: "/assets/portraits/granny.webp" },
  miao_leader: { name: "黑苗首領", portrait: "/assets/portraits/miao_leader.webp" },
  fat_miao: { name: "胖苗", portrait: "/assets/portraits/fat_miao.webp" },
  tang_yu: { name: "唐鈺", portrait: "/assets/portraits/tang_yu.webp" },
  wuwang: { name: "巫王", portrait: "/assets/portraits/wuwang.webp" },
  lin_tiannan: { name: "林天南", portrait: "/assets/portraits/lin_tiannan.webp" },
  liu_jinyuan: { name: "劉晉元", portrait: "/assets/portraits/liu_jinyuan.webp" },
  caiyi: { name: "彩依", portrait: "/assets/portraits/caiyi.webp" },
  shi_zhanglao: { name: "石長老", portrait: "/assets/portraits/shi_zhanglao.webp" },
  sword_saint: { name: "劍聖", portrait: "/assets/portraits/sword_saint.webp" },
  shenggu: { name: "聖姑", portrait: "/assets/portraits/shenggu.webp" },
  gai_luojiao: { name: "蓋羅嬌", portrait: "/assets/portraits/gai_luojiao.webp" },
  baiyue: { name: "拜月教主", portrait: "/assets/portraits/baiyue.webp" },
  ji_sanniang: { name: "姬三娘", portrait: "/assets/portraits/ji_sanniang.webp" },
  zhixiu: { name: "智修大師", portrait: "/assets/portraits/zhixiu.webp" },
  villager: { name: "村民", portrait: "/assets/portraits/villager.webp" },
  narrator: { name: "", portrait: "" },
};

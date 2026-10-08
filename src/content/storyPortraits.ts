/**
 * 劇情對話頭像：電影感 CG 版（2026-10-06 使用者定的新美術方向，造型來源 tools/art/cine_cast.py）。
 * 主角的表情都從同一張底圖圖生圖，臉與衣服一致；配角只有底圖。
 * 巫后使用者指示先不重做，沿用 characters.ts 的舊頭像。
 */
export interface StoryPortrait {
  base: string;
  expressions?: Partial<Record<string, string>>;
}

const DIR = "/assets/portraits/cine-v1";
const EXPRESSIONS = ["smile", "angry", "surprise", "sad", "resolve"] as const;
const MAIN = ["li_xiaoyao", "zhao_linger", "lin_yueru", "anu"] as const;
const SUPPORTING = [
  "aunt", "drunk", "granny", "miao_leader", "fat_miao", "tang_yu", "wuwang", "lin_tiannan", "liu_jinyuan", "caiyi",
  "shi_zhanglao", "sword_saint", "shenggu", "gai_luojiao", "baiyue", "ji_sanniang", "zhixiu", "villager",
] as const;

export const STORY_PORTRAITS: Record<string, StoryPortrait> = Object.fromEntries([
  ...MAIN.map((id) => [id, { base: `${DIR}/${id}.webp`, expressions: Object.fromEntries(EXPRESSIONS.map((e) => [e, `${DIR}/${id}_${e}.webp`])) }]),
  ...SUPPORTING.map((id) => [id, { base: `${DIR}/${id}.webp` }]),
]);

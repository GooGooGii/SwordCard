import type { BattleSceneId } from './catalog';

export type PalSceneId = Exclude<BattleSceneId, 'blood_pool'>;
export type Surface = 'earth' | 'tiles' | 'wood' | 'rock' | 'roots' | 'lava' | 'red';
export type Architecture = 'rocks' | 'inn' | 'quay' | 'arena' | 'graves' | 'wall' | 'garden' | 'forest' | 'tower' | 'roots' | 'lava' | 'temple' | 'palace' | 'red';
export interface PalSceneRecipe {
  surface: Surface; architecture: Architecture;
  ground: string; detail: string; stone: string; vegetation?: string;
  /** 原作場景辨識元素；只記錄背景，不把 Boss 本體算入場景。 */
  features: readonly string[];
}

/** DOS 截圖逐場核對；不以地名猜測現代奇幻場景。 */
export const PAL_SCENE_RECIPES: Record<PalSceneId, PalSceneRecipe> = {
  shilipo: { surface: 'earth', architecture: 'rocks', ground: '#635741', detail: '#37392a', stone: '#5a5142', vegetation: '#364831', features: ['褐灰土路', '碎岩邊緣', '低矮綠叢'] },
  xianling: { surface: 'earth', architecture: 'rocks', ground: '#6d644a', detail: '#424a34', stone: '#655843', vegetation: '#405938', features: ['橄欖褐土', '鋸齒岩岸', '稀疏草叢'] },
  yuhang_inn: { surface: 'tiles', architecture: 'inn', ground: '#656b61', detail: '#41463e', stone: '#72382d', vegetation: '#354d30', features: ['灰綠斜磚', '紅木隔扇', '格窗與紅燈籠', '圓桌與長凳'] },
  yangzhou: { surface: 'tiles', architecture: 'inn', ground: '#566270', detail: '#333d49', stone: '#60312f', vegetation: '#2c4438', features: ['夜間藍灰磚', '紅木格窗', '圓桌與長凳'] },
  suzhou_road: { surface: 'rock', architecture: 'quay', ground: '#76776a', detail: '#4c5046', stone: '#77766a', features: ['灰色河埠石路', '暗色河水', '木板橋與木樁'] },
  lin_arena: { surface: 'wood', architecture: 'arena', ground: '#822c25', detail: '#4c201d', stone: '#6b392a', features: ['矩形紅擂台', '細金邊', '木質臺基', '角柱紅結'] },
  yinlong_cave: { surface: 'rock', architecture: 'rocks', ground: '#284b4a', detail: '#142c31', stone: '#29494b', features: ['青黑裂岩', '藍綠直立洞壁', '低矮岩緣'] },
  baihe: { surface: 'earth', architecture: 'garden', ground: '#605e3d', detail: '#3e492c', stone: '#777366', vegetation: '#416134', features: ['草地', '褐色小徑', '灰褐石崖'] },
  graveyard: { surface: 'earth', architecture: 'graves', ground: '#514734', detail: '#32342b', stone: '#77786b', vegetation: '#35482d', features: ['褐黑泥地', '破損灰碑', '黑色墓穴', '低矮棺木'] },
  general_tomb: { surface: 'earth', architecture: 'rocks', ground: '#66573f', detail: '#40392d', stone: '#706754', vegetation: '#3c4830', features: ['褐色洞底', '密集灰褐碎岩', '少量苔蘚'] },
  guiyin: { surface: 'tiles', architecture: 'wall', ground: '#726852', detail: '#474236', stone: '#7a6c54', features: ['褐灰斜向磚', '灰褐砌石牆', '場外黑暗'] },
  toad_hill: { surface: 'earth', architecture: 'rocks', ground: '#635b42', detail: '#3a4031', stone: '#615b48', vegetation: '#304943', features: ['褐灰岩洞', '青色岩縫', '碎岩地面'] },
  ministry: { surface: 'tiles', architecture: 'garden', ground: '#72776b', detail: '#51574e', stone: '#74766a', vegetation: '#2f6030', features: ['灰綠方磚庭院', '四周繁花', '密集綠葉'] },
  spider_forest: { surface: 'roots', architecture: 'forest', ground: '#714a31', detail: '#443a27', stone: '#514b3b', vegetation: '#2d4630', features: ['赤褐林地', '灰褐枯樹幹', '盤根', '稀疏落葉'] },
  demon_tower: { surface: 'tiles', architecture: 'tower', ground: '#797a66', detail: '#555848', stone: '#92917c', features: ['密集灰綠小磚', '方形石廊', '壁面雕刻', '青綠格窗'] },
  tower_top: { surface: 'red', architecture: 'red', ground: '#7d080d', detail: '#2e080b', stone: '#3d0d10', features: ['深紅地面', '橫向暗紋', '無屋頂或天空'] },
  sacred_forest: { surface: 'roots', architecture: 'roots', ground: '#493d2c', detail: '#242f22', stone: '#4b4230', vegetation: '#295536', features: ['神木巨根', '棕黑根毯', '青綠藤蔓', '右側巨大樹幹'] },
  qilin_cave: { surface: 'lava', architecture: 'lava', ground: '#92271e', detail: '#380c12', stone: '#63171a', features: ['暗紅龜裂', '黃白環流', '環流外側紅色熔岩紋'] },
  water_maze: { surface: 'rock', architecture: 'rocks', ground: '#274447', detail: '#172832', stone: '#29444a', vegetation: '#2d6152', features: ['青黑岩地', '波浪形岩壁', '綠色水草'] },
  trial_cave: { surface: 'roots', architecture: 'roots', ground: '#3d4b32', detail: '#282b20', stone: '#68583c', vegetation: '#335538', features: ['暗綠洞口', '棕色交錯根莖', '褐色崖緣'] },
  nuwa_temple: { surface: 'tiles', architecture: 'temple', ground: '#626c65', detail: '#404941', stone: '#82827a', features: ['灰綠細石磚', '粗大方柱', '石造殿牆', '淡青牆基'] },
  nanzhao_palace: { surface: 'rock', architecture: 'palace', ground: '#777866', detail: '#484e42', stone: '#93927b', features: ['灰綠碎石地', '雕花石屏', '連續矩形浮雕', '石質牆基'] },
};

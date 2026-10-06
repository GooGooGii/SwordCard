import type { BackdropLayout } from "../backdrop";

/** sceneId 與 TASKS.md 的交付規格 B 一致；不依賴 Claude 正在編輯的章節資料。 */
export const SCENE_NAMES = {
  shilipo: "十里坡", yuhang_inn: "餘杭客棧", xianling: "仙靈島",
  suzhou_road: "蘇州城外", lin_arena: "林家堡擂台", yinlong_cave: "隱龍窟",
  baihe: "白河村", graveyard: "亂葬崗", general_tomb: "將軍塚", blood_pool: "血池",
  guiyin: "鬼陰山", yangzhou: "揚州夜街", toad_hill: "蛤蟆山", ministry: "京城尚書府",
  spider_forest: "黑蜘蛛森林", demon_tower: "鎖妖塔", tower_top: "鎖妖塔頂",
  sacred_forest: "靈山神木林", qilin_cave: "火麒麟洞", water_maze: "水底迷宮",
  trial_cave: "試煉窟", nuwa_temple: "女媧神殿", nanzhao_palace: "南詔王宮",
} as const;

export type BattleSceneId = keyof typeof SCENE_NAMES;
export type SceneEnvironmentId = BattleSceneId;
export const BATTLE_SCENE_IDS = Object.freeze(Object.keys(SCENE_NAMES) as BattleSceneId[]);

interface ScenePresentation {
  readonly backdropUrl: string;
  readonly backdropLayout: BackdropLayout;
  /** 完整 3D 地面，不疊舊背景；美術驗收狀態另記 TASKS.md。 */
  readonly environment?: SceneEnvironmentId;
}

// 保留現成圖片供明確自訂 Backdrop 的相容後備；正式預設使用 3D。
const PRESENTATIONS: Partial<Record<BattleSceneId, ScenePresentation>> = {
  shilipo: {
    backdropUrl: "/assets/backgrounds/shilipo_ground.jpg",
    backdropLayout: Object.freeze({ wallV: 0 }),
  },
};

// Claude Code 補位的地面第一版（ComfyUI，2026-10-05，提示詞在 tools/art/make_assets.py 的 BATTLE）。
// 全地面投影（wallV 0）同十里坡；自訂背景仍可使用。
const FIRST_PASS_GROUNDS: readonly BattleSceneId[] = [
  "yuhang_inn", "xianling", "suzhou_road", "lin_arena", "yinlong_cave", "baihe", "graveyard", "general_tomb",
  "blood_pool", "guiyin", "yangzhou", "toad_hill", "ministry", "spider_forest", "demon_tower", "tower_top",
  "sacred_forest", "qilin_cave", "water_maze", "trial_cave", "nuwa_temple", "nanzhao_palace",
];
for (const id of FIRST_PASS_GROUNDS) {
  PRESENTATIONS[id] = { backdropUrl: `/assets/battle/${id}.jpg`, backdropLayout: Object.freeze({ wallV: 0 }) };
}
for (const id of BATTLE_SCENE_IDS) PRESENTATIONS[id] = { ...PRESENTATIONS[id]!, environment: id };

export interface ResolvedBattleScene extends ScenePresentation {
  readonly requestedId: string;
  readonly renderedId: BattleSceneId;
  readonly name: string;
  readonly fallbackReason: "none" | "pending_art" | "unknown_scene";
}

export function isBattleSceneId(value: string): value is BattleSceneId {
  return Object.hasOwn(SCENE_NAMES, value);
}

/** 未知 ID 或尚未製作的場景只讀現成十里坡，不會嘗試抓不存在的 JPG。 */
export function resolveBattleScene(sceneId?: string | null): ResolvedBattleScene {
  const requestedId = sceneId?.trim() || "shilipo";
  const known = isBattleSceneId(requestedId);
  const presentation = known ? PRESENTATIONS[requestedId] : undefined;
  const renderedId: BattleSceneId = presentation ? requestedId as BattleSceneId : "shilipo";
  const rendered = presentation ?? PRESENTATIONS.shilipo!;
  return {
    requestedId, renderedId, name: SCENE_NAMES[renderedId],
    backdropUrl: rendered.backdropUrl, backdropLayout: rendered.backdropLayout,
    environment: rendered.environment,
    fallbackReason: presentation ? "none" : known ? "pending_art" : "unknown_scene",
  };
}

/** 提供檢查／排程清單；plannedAssetUrl 只能用於交付，不能直接拿來載入。 */
export function listBattleScenes() {
  return BATTLE_SCENE_IDS.map((id) => ({
    id, name: SCENE_NAMES[id], ready: PRESENTATIONS[id] !== undefined,
    environment: PRESENTATIONS[id]?.environment ?? null,
    plannedAssetUrl: `/assets/battle/${id}.jpg`,
  }));
}

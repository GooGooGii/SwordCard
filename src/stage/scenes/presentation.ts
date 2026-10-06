import type { ResolvedBattleScene } from "./catalog";

/** 完整場景自動接入正式版；明確自訂背景或道具仍使用呼叫者的組合。 */
export function resolveSceneEnvironment(scene: ResolvedBattleScene, overrides: {
  explicitBackdrop: boolean;
  explicitScenery: boolean;
}) {
  return overrides.explicitBackdrop || overrides.explicitScenery ? null : scene.environment ?? null;
}

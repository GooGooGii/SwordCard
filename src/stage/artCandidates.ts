/** 赤鬼王 DOS v2 已獲使用者確認；保留歷史候選入口，正式圖使用相同比例。 */
export const RED_GHOST_KING_DOS_ART = "/assets/enemies/candidates/red_ghost_king_dos_v2.webp";

export function presentBossArt<T extends { url: string; height: number; headOffset?: [number, number, number] }>(actor: T, options: {
  development: boolean;
  search: string;
  sceneId: string;
}): T & { headOffset?: [number, number, number] } {
  if (actor.url !== "/assets/enemies/red_ghost_king.webp") return actor;
  const candidate = options.development && options.sceneId === "blood_pool"
    && new URLSearchParams(options.search).get("bossArt") === "red_ghost_king_dos";
  // DOS 是屈膝袍服，不能沿用完整直立惡魔的高度，否則高帽會出畫面。
  return { ...actor, url: candidate ? RED_GHOST_KING_DOS_ART : actor.url,
    height: Math.min(actor.height, 1.9), headOffset: actor.headOffset ?? [-1.5, 0, 0] };
}

import type { CharId } from "../core/types";

/**
 * 主角戰鬥立繪的姿勢圖（電影感 CG，2026-10-06；tools/art/standees_cine.py 產生）。
 * 站姿用 characters.ts 的 standee；這裡只列「該動作期間換成的圖」，沒列的動作就用站姿加程式動作。
 * 只列已發布的檔案：舞台會預先載入全部姿勢，缺圖會讓整個舞台載入失敗。
 */
const POSES = ["attack", "cast", "guard", "hit"] as const;
const READY: CharId[] = ["li_xiaoyao", "zhao_linger", "lin_yueru", "anu"];

export const HERO_POSES: Partial<Record<CharId, Partial<Record<string, string>>>> = Object.fromEntries(
  READY.map((id) => [id, Object.fromEntries(POSES.map((p) => [p, `/assets/characters/${id}_pose_${p}.webp`]))]),
);

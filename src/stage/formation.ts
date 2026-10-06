/**
 * 仙劍一式斜向站位（REDESIGN §6，2026-10-04 依原作 DOS 版戰鬥畫面）：
 * - 鏡頭約 45° 俯視，看不到天空與地平線
 * - 敵方在畫面左上、面朝右下；我方在畫面右下、面朝左上
 * - 每方最多 3 人，排成一條與交戰軸垂直的斜線（畫面上由左下往右上）
 *
 * 世界座標：x 往畫面右、z 往鏡頭（畫面下方）、y 往上。純函式，方便單元測試。
 */

export type Vec3 = [number, number, number];

export interface FormationOptions {
  /** 我方中心；敵方中心預設為其鏡像 */
  partyCenter: Vec3;
  enemyCenter: Vec3;
  /** 同一方相鄰兩人的間距（公尺） */
  spacing: number;
}

export const PAL_FORMATION: FormationOptions = {
  partyCenter: [1.65, 0, 0.95],
  enemyCenter: [-1.55, 0, -0.8],
  spacing: 1.3,
};

/**
 * 一方的排列方向：畫面上由左下往右上的「緩斜線」（x 增加、z 稍微減少）。
 * 不用交戰軸的垂直方向：那條線在 45° 俯視下幾乎是直的往畫面深處，隊友會前後疊在一起；
 * 仙劍一原作的隊伍是橫向展開、略微斜向的。
 */
const LINE_DIRECTION: [number, number] = (() => {
  const x = 1;
  const z = -0.55;
  const len = Math.hypot(x, z);
  return [x / len, z / len];
})();

function lineDirection(_opts: FormationOptions): [number, number] {
  return LINE_DIRECTION;
}

/**
 * 第 index 個站位（0 = 中央，1 = 右上，2 = 左下），total 為該方人數。
 * 1 人站中央；2 人分站兩側；3 人中央＋兩側。
 */
export function slotPosition(side: "party" | "enemy", index: number, total: number, opts: FormationOptions = PAL_FORMATION): Vec3 {
  const center = side === "party" ? opts.partyCenter : opts.enemyCenter;
  const [dx, dz] = lineDirection(opts);
  const offsets = total <= 1 ? [0] : total === 2 ? [0.5, -0.5] : [0, 1, -1];
  const k = (offsets[index] ?? 0) * opts.spacing;
  return [center[0] + dx * k, center[1], center[2] + dz * k];
}

/** 從 from 面向 to 的 yaw（度）：0 = 面向鏡頭（+z），正值往畫面右轉。 */
export function yawToward(from: Vec3, to: Vec3): number {
  return (Math.atan2(to[0] - from[0], to[2] - from[2]) * 180) / Math.PI;
}

/** 衝刺落點：從 from 往 to 前進，停在距離 to 還有 gap 公尺的地方。 */
export function lungePoint(from: Vec3, to: Vec3, gap: number): Vec3 {
  const dx = to[0] - from[0];
  const dz = to[2] - from[2];
  const len = Math.hypot(dx, dz);
  if (len <= gap) return [...from];
  const t = (len - gap) / len;
  return [from[0] + dx * t, from[1], from[2] + dz * t];
}

export function sideCenter(side: "party" | "enemy", opts: FormationOptions = PAL_FORMATION): Vec3 {
  return side === "party" ? opts.partyCenter : opts.enemyCenter;
}

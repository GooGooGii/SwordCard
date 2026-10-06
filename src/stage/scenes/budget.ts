import * as THREE from "three";

/** 只算戰場附加道具／粒子，不包含角色、投影背景、血條與後製。 */
export const SCENERY_BUDGET = Object.freeze({ drawCalls: 20, triangles: 30_000 });

export interface SceneryBudgetReport {
  mainDrawCalls: number;
  /** 依舞台的一盞投影方向光估算；實際陰影視錐剔除可能減少繪製。 */
  shadowDrawCalls: number;
  drawCalls: number;
  /** 主 pass 的三角面數，包含 instance 次數，不把陰影再重算一次。 */
  triangles: number;
  withinBudget: boolean;
  violations: string[];
}

function clippedCount(total: number, start: number, count: number, range: THREE.BufferGeometry["drawRange"]): number {
  const first = Math.max(0, start, range.start);
  const last = Math.min(total, start + count, range.start + range.count);
  return Math.max(0, last - first);
}

function mainPasses(material: THREE.Material): number {
  return material.transparent && material.side === THREE.DoubleSide && !material.forceSinglePass ? 2 : 1;
}

/**
 * 離線檢查候選道具 group。計入材質分組、drawRange、隱藏物件、instancing 與
 * 一次陰影 pass；是預算上界估算，不是 GPU 計時。最終仍看 renderer.info 與手機實測。
 */
export function inspectSceneryBudget(root: THREE.Object3D): SceneryBudgetReport {
  let mainDrawCalls = 0;
  let shadowDrawCalls = 0;
  let triangles = 0;
  root.traverseVisible((object) => {
    if (object instanceof THREE.Sprite) {
      if (object.material.visible) {
        const passes = mainPasses(object.material);
        mainDrawCalls += passes;
        triangles += 2 * passes;
      }
      return;
    }
    if (!(object instanceof THREE.Mesh || object instanceof THREE.Line || object instanceof THREE.Points)) return;
    const geometry: THREE.BufferGeometry = object.geometry;
    const total = geometry.index?.count ?? geometry.getAttribute("position")?.count ?? 0;
    const instances = object instanceof THREE.InstancedMesh ? Math.max(0, object.count) : 1;
    if (total === 0 || instances === 0) return;
    const draws = Array.isArray(object.material)
      ? geometry.groups.flatMap((group) => {
        const material = object.material as THREE.Material[];
        const current = material[group.materialIndex ?? 0];
        return current?.visible
          ? [{ count: clippedCount(total, group.start, group.count, geometry.drawRange), passes: mainPasses(current) }] : [];
      })
      : object.material.visible
        ? [{ count: clippedCount(total, 0, total, geometry.drawRange), passes: mainPasses(object.material) }] : [];
    for (const { count, passes } of draws) {
      if (count <= 0) continue;
      mainDrawCalls += passes;
      if (object.castShadow) shadowDrawCalls++;
      if (object instanceof THREE.Mesh) triangles += Math.floor(count / 3) * instances * passes;
    }
  });
  const drawCalls = mainDrawCalls + shadowDrawCalls;
  const violations: string[] = [];
  if (drawCalls > SCENERY_BUDGET.drawCalls) violations.push(`繪製呼叫 ${drawCalls} > ${SCENERY_BUDGET.drawCalls}`);
  if (triangles > SCENERY_BUDGET.triangles) violations.push(`三角面 ${triangles} > ${SCENERY_BUDGET.triangles}`);
  return { mainDrawCalls, shadowDrawCalls, drawCalls, triangles, withinBudget: violations.length === 0, violations };
}

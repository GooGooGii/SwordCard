import { useFrame, useThree } from "@react-three/fiber";
import { useEffect, useRef } from "react";

/**
 * 效能量測（REDESIGN §8.1 驗收 2）：每秒把平均幀率、最差幀時間、繪製次數、三角面數寫到 DOM，
 * 也掛在 window.__perf 供自動化讀取。
 */
export function FpsMeter({ target }: { target: HTMLElement | null }) {
  const { gl } = useThree();
  const frames = useRef(0);
  const worst = useRef(0);
  const since = useRef(performance.now());
  const last = useRef(performance.now());
  const peak = useRef({ calls: 0, triangles: 0 });
  useEffect(() => {
    // 後製每一道都會重設 gl.info：改成手動在每幀開頭重設，才能累計整幀（場景＋後製）的數字
    gl.info.autoReset = false;
    return () => {
      gl.info.autoReset = true;
    };
  }, [gl]);
  // priority -1000：在所有渲染之前跑——讀上一幀累計的數字，再重設
  useFrame(() => {
    const info = gl.info.render;
    peak.current.calls = Math.max(peak.current.calls, info.calls);
    peak.current.triangles = Math.max(peak.current.triangles, info.triangles);
    gl.info.reset();
  }, -1000);
  useFrame(() => {
    const now = performance.now();
    worst.current = Math.max(worst.current, now - last.current);
    last.current = now;
    frames.current += 1;
    if (now - since.current < 1000) return;
    const fps = (frames.current * 1000) / (now - since.current);
    const stats = {
      fps: Math.round(fps),
      worstMs: Math.round(worst.current),
      calls: peak.current.calls,
      triangles: peak.current.triangles,
      dpr: Math.round(gl.getPixelRatio() * 100) / 100,
      geometries: gl.info.memory.geometries,
      textures: gl.info.memory.textures,
      programs: gl.info.programs?.length ?? 0,
      frame: gl.info.render.frame,
    };
    peak.current = { calls: 0, triangles: 0 };
    (window as unknown as { __perf?: typeof stats }).__perf = stats;
    if (target) target.textContent = `${stats.fps} fps・最差 ${stats.worstMs} ms・${stats.calls} draw・${Math.round(stats.triangles / 1000)}k 面・DPR ${stats.dpr}`;
    frames.current = 0;
    worst.current = 0;
    since.current = now;
  });
  return null;
}

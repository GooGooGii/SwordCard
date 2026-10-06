import { useFrame } from "@react-three/fiber";
import { useEffect, useMemo, useRef } from "react";
import { buildBloodPoolScenery } from "./bloodPool";

/** 已通過驗收的完整 3D 血池；保持原先 StrictMode 安全的資源清理。 */
export default function BloodPoolScene({ quality }: { quality: "high" | "low" }) {
  const scenery = useMemo(buildBloodPoolScenery, []);
  const mounted = useRef(false);
  useFrame(({ clock }) => scenery.update(clock.elapsedTime, quality === "low"));
  useEffect(() => {
    // StrictMode 的第一次模擬卸載會立即接著掛載；取消延後清理。
    mounted.current = true;
    return () => {
      mounted.current = false;
      queueMicrotask(() => { if (!mounted.current) scenery.dispose(); });
    };
  }, [scenery]);
  return <primitive object={scenery.group} dispose={null} />;
}

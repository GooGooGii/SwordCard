import { useEffect, useRef, type ReactNode } from "react";
import type { StageAnchor } from "../../stage/BattleStage";

/**
 * 3D 舞台上方的 DOM 疊層：血條、意圖、狀態、拖曳落點、浮動數字。
 * 位置由 BattleStage 每幀投影寫進 anchors；這裡用 requestAnimationFrame 直接改 transform，不觸發 React 重繪。
 * （不用 drei Html：它每個元素各自一個 React root，戰鬥中卸載會出錯。）
 */
export interface OverlayLayer {
  id: string;
  head?: ReactNode;
  foot?: ReactNode;
  mid?: ReactNode;
  pop?: ReactNode;
}

type Slot = "head" | "foot" | "mid" | "pop";
const SLOTS: Slot[] = ["foot", "mid", "head", "pop"];
// 每個錨點相對元素的對齊：頭頂的東西往上長、腳下的往下長
const ALIGN: Record<Slot, string> = { head: "-50%, -100%", foot: "-50%, 0", mid: "-50%, -50%", pop: "-50%, -100%" };

export function StageOverlay({ anchors, layers }: { anchors: { current: Map<string, StageAnchor> }; layers: OverlayLayer[] }) {
  const nodes = useRef(new Map<string, HTMLDivElement>());
  useEffect(() => {
    let raf = 0;
    const tick = () => {
      // 三人隊前排的腳下 HUD 需留在手牌之上；選牌抬起時仍可局部重疊。
      const hand = document.querySelector<HTMLElement>(".bt-hand");
      const footLimit = hand ? hand.offsetTop - 58 : Infinity;
      for (const [key, el] of nodes.current) {
        const [id, slot] = key.split("|") as [string, Slot];
        const p = anchors.current.get(id)?.[slot];
        if (!p) {
          el.style.visibility = "hidden";
          continue;
        }
        el.style.visibility = "visible";
        // 往上長的東西（意圖、浮動數字）不能超出畫面上緣：高大的 Boss 頭頂常在畫面外
        const y = slot === "head" || slot === "pop" ? Math.max(p[1], el.offsetHeight + 6) : slot === "foot" ? Math.min(p[1], footLimit) : p[1];
        el.style.transform = `translate(${p[0]}px, ${y}px) translate(${ALIGN[slot]})`;
      }
      raf = requestAnimationFrame(tick);
    };
    tick();
    return () => cancelAnimationFrame(raf);
  }, [anchors]);

  return (
    <div className="stage-overlay">
      {layers.flatMap((layer) =>
        SLOTS.filter((slot) => layer[slot]).map((slot) => {
          const key = `${layer.id}|${slot}`;
          return (
            <div
              key={key}
              className={`anchor anchor-${slot}`}
              style={{ visibility: "hidden" }}
              ref={(el) => {
                if (el) nodes.current.set(key, el);
                else nodes.current.delete(key);
              }}
            >
              {layer[slot]}
            </div>
          );
        }),
      )}
    </div>
  );
}

import { useState } from "react";
import { availableNodes, chapterOf, enterNode, type NodeDef, type RunState } from "../../core/run";
import { game } from "../../game/store";
import { playSfx } from "../../platform/audio";
import { TopBar } from "../common/TopBar";

/**
 * 章節路線圖（REDESIGN §2：手繪 2D 地圖、手工設計節點）。
 * 已走過的節點變淡，下一步能去的節點發亮；點了就進入（劇情、戰鬥、客棧）。
 */
const KIND_SEAL: Record<string, string> = { story: "劇", battle: "戰", inn: "棧", event: "奇" };

function seal(node: NodeDef): string {
  if (node.kind === "battle" && node.battle?.boss) return "首";
  if (node.kind === "battle" && node.battle?.elite) return "強";
  if (node.kind === "battle" && node.battle?.survive) return "守";
  return KIND_SEAL[node.kind] ?? "？";
}

export function MapScreen({ run }: { run: RunState }) {
  const chapter = chapterOf(game.db, run);
  const open = new Set(availableNodes(game.db, run).map((n) => n.id));
  const [hover, setHover] = useState<string | null>(null);
  const byId = new Map(chapter.nodes.map((n) => [n.id, n]));
  const hovered = hover ? byId.get(hover) : null;

  const go = (id: string) => {
    if (!open.has(id)) return;
    playSfx("click");
    game.update((db, r) => enterNode(db, r, id));
  };

  return (
    <div className="map">
      {/* 地圖圖檔還沒交付時，退回 CSS 畫的絹本底色 */}
      <div className="map-bg" style={{ backgroundImage: `url(${chapter.map}), var(--map-fallback)` }} />
      <div className="map-field">
      <svg className="map-lines" viewBox="0 0 100 100" preserveAspectRatio="none">
        {chapter.nodes.flatMap((node) =>
          node.next.map((nextId) => {
            const to = byId.get(nextId)!;
            const walked = run.visited.includes(node.id) && run.visited.includes(nextId);
            const ahead = (run.at === node.id || (run.at === null && node.id === chapter.start)) && open.has(nextId);
            return (
              <line
                key={`${node.id}-${nextId}`}
                x1={node.pos[0] * 100}
                y1={node.pos[1] * 100}
                x2={to.pos[0] * 100}
                y2={to.pos[1] * 100}
                className={walked ? "walked" : ahead ? "ahead" : ""}
                vectorEffect="non-scaling-stroke"
              />
            );
          }),
        )}
      </svg>
      {chapter.nodes.map((node) => {
        const state = run.visited.includes(node.id) ? "visited" : open.has(node.id) ? "open" : "locked";
        return (
          <button
            key={node.id}
            type="button"
            className={`map-node ${state} ${node.optional ? "optional" : ""} ${run.at === node.id ? "here" : ""}`}
            style={{ left: `${node.pos[0] * 100}%`, top: `${node.pos[1] * 100}%` }}
            disabled={state !== "open"}
            onClick={() => go(node.id)}
            onPointerEnter={() => setHover(node.id)}
            onPointerLeave={() => setHover((h) => (h === node.id ? null : h))}
          >
            <span className="map-seal">{seal(node)}</span>
            <span className="map-label">{node.label}</span>
          </button>
        );
      })}
      </div>
      <div className="map-title">
        <h1>{chapter.title}</h1>
        <p>{chapter.subtitle}</p>
      </div>
      {hovered ? (
        <div className="map-hint">
          <b>{hovered.label}</b>
          {hovered.optional ? <span>（支線，可略過）</span> : null}
        </div>
      ) : null}
      <TopBar run={run} />
    </div>
  );
}

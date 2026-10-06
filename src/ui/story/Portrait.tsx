import { useEffect, useState } from "react";
import { CHARACTERS, NPCS } from "../../content/characters";
import { STORY_PORTRAITS } from "../../content/storyPortraits";

/**
 * 劇情立繪：校正角色只使用已登錄的新表情與底圖，避免回退到舊造型。
 * 尚未校正者沿用 <id>_<expr>.webp → 基本版 → 名字印章。
 * 立繪還沒畫好的角色也能正常播劇情。
 */
export function Portrait({ who, expr, side }: { who: string; expr?: string; side: "left" | "right" }) {
  const canonical = STORY_PORTRAITS[who];
  const base = canonical?.base ?? (CHARACTERS as Record<string, { portrait: string; name: string }>)[who]?.portrait ?? NPCS[who]?.portrait ?? "";
  const name = (CHARACTERS as Record<string, { name: string }>)[who]?.name ?? NPCS[who]?.name ?? "";
  const expression = canonical ? (expr ? canonical.expressions?.[expr] : null) : (expr ? base.replace(/\.(png|webp)$/, `_${expr}.$1`) : null);
  const candidates = [expression, base].filter((s): s is string => !!s);
  const [attempt, setAttempt] = useState(0);
  useEffect(() => setAttempt(0), [who, expr]);
  const src = candidates[attempt];
  if (!src) {
    return name ? <div className={`story-portrait story-portrait-seal ${side}`}>{name.slice(0, 1)}</div> : null;
  }
  return <img className={`story-portrait ${side}`} src={src} alt={name} draggable={false} onError={() => setAttempt((a) => a + 1)} />;
}

import type { ReactNode } from "react";

const EMBERS = Array.from({ length: 14 }, (_, i) => i);

/**
 * 電影感起始畫面（2026-10-06 使用者要求重製，學習 3A 同人影片的開場靜物）：
 * 黃昏山崖上的酒葫蘆、竹簡、長劍；選項以墨字寫在竹簡上。
 * 背景固定 16:9 並以 cover 方式填滿，竹簡上的文字跟著圖一起縮放。
 */
export function TitleCinematic({ children }: { children: ReactNode }) {
  return (
    <div className="title-cine">
      <img className="title-cine-bg" src="/assets/title/title_bg.jpg" alt="" draggable={false} />
      <div className="title-cine-embers" aria-hidden="true">
        {EMBERS.map((i) => (
          <span key={i} style={{ left: `${(i * 37) % 100}%`, animationDelay: `${(i * 1.7) % 9}s`, animationDuration: `${7 + (i % 5)}s` }} />
        ))}
      </div>
      <div className="title-cine-scroll">{children}</div>
    </div>
  );
}

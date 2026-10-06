import { useEffect, useState } from "react";

/**
 * 從候選網址裡挑第一個真的存在的素材（3D 模型 → 2D 立繪 → 預設圖）。
 * 美術陸續交付中，缺圖時不能讓 3D 舞台整個載入失敗（useTexture／useGLTF 遇到 404 會丟錯）。
 */
const cache = new Map<string, Promise<boolean>>();

function exists(url: string): Promise<boolean> {
  let p = cache.get(url);
  if (!p) {
    p = fetch(url, { method: "HEAD" })
      .then((r) => {
        const type = r.headers.get("content-type") ?? "";
        // 開發伺服器對不存在的路徑可能回 index.html（200）：只認圖片與模型
        return r.ok && !type.includes("text/html");
      })
      .catch(() => false);
    cache.set(url, p);
  }
  return p;
}

export function useAsset(candidates: (string | undefined)[]): string | null {
  const list = candidates.filter((c): c is string => !!c);
  const key = list.join("|");
  const [found, setFound] = useState<string | null>(null);
  useEffect(() => {
    let alive = true;
    (async () => {
      for (const url of list) {
        if (await exists(url)) {
          if (alive) setFound(url);
          return;
        }
      }
      if (alive) setFound(null);
    })();
    return () => {
      alive = false;
    };
    // list 由 key 決定
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);
  return found;
}

/** 一次解析多組候選（戰鬥裡每個角色一組） */
export function useAssets(groups: (string | undefined)[][]): (string | null)[] {
  const key = groups.map((g) => g.join("|")).join("||");
  const [found, setFound] = useState<(string | null)[]>(() => groups.map(() => null));
  useEffect(() => {
    let alive = true;
    Promise.all(
      groups.map(async (g) => {
        for (const url of g) if (url && (await exists(url))) return url;
        return null;
      }),
    ).then((r) => alive && setFound(r));
    return () => {
      alive = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);
  return found;
}

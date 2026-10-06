import { useEffect } from "react";
import { MENU_EVENT } from "../../platform/backButton";

/** 面板：按 Esc（或 Android 返回鍵）關閉 */
export function useEscape(onClose: () => void): void {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);
}

/** 地圖、戰鬥：Android 返回鍵（沒有面板開著時）打開選單 */
export function useMenuRequest(open: () => void): void {
  useEffect(() => {
    window.addEventListener(MENU_EVENT, open);
    return () => window.removeEventListener(MENU_EVENT, open);
  }, [open]);
}

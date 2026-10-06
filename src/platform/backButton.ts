import { Capacitor } from "@capacitor/core";

/**
 * Android 返回鍵（只在 App 裡）：有開著的面板就關掉（等同 Esc），否則打開遊戲選單；
 * 在起始選單按返回則把 App 縮到背景（不直接結束，進度本來就自動存了）。
 * 畫面端：面板監聽 Esc 關閉；地圖、戰鬥監聽 MENU_EVENT 打開選單。
 */
export const MENU_EVENT = "xiaoyao:menu";

export function installBackButton(inGame: () => boolean): void {
  if (!Capacitor.isNativePlatform()) return;
  void import("@capacitor/app").then(({ App }) => {
    void App.addListener("backButton", () => {
      if (document.querySelector(".ov, .story-log, .bt-tips")) {
        window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
        return;
      }
      if (inGame()) window.dispatchEvent(new Event(MENU_EVENT));
      else void App.minimizeApp();
    });
  });
}

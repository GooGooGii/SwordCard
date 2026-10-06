import type { CapacitorConfig } from "@capacitor/cli";

/**
 * Android 打包（QA-001a）：網頁版直接包進 App（Capacitor）。私人同人作品，不上架。
 * npm run android:build → android/app/build/outputs/apk/debug/app-debug.apk
 */
const config: CapacitorConfig = {
  appId: "tw.fan.xiaoyao",
  appName: "SwordCard",
  webDir: "dist",
  android: {
    allowMixedContent: false,
    // 載入前的底色（和網頁的墨色一致，避免白屏閃一下）
    backgroundColor: "#1a1712",
  },
};

export default config;

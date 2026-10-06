# SwordCard

仙劍一私人粉絲向卡牌敘事遊戲。新版以 Three.js、React Three Fiber、React 與 TypeScript 製作；與先前 Godot 原型是同一個遊戲，沿用原 Git 歷史及 [SwordCard 儲存庫](https://github.com/GooGooGii/SwordCard)。

## 開發

```sh
npm ci
npm run dev
npm run build
npm test
```

`src/core` 為遊戲規則，`src/content` 為章節／卡牌內容，`src/ui` 為介面，`src/stage` 為 3D 場景，`public/assets` 為正式素材。主角使用正常比例 STYLE D；不採用被拒的 Q 版候選。

協作入口：[AGENTS.md](AGENTS.md)、[TASKS.md](TASKS.md)、[CLAUDE.md](CLAUDE.md)。所有後續開發在本儲存庫進行，舊 Godot 版本可從 `e2b3f41` 及之前的歷史恢復。

## 手機

`npm run android:build` 可建置 Android 包裝版，需要 Android SDK／JDK。顯示名稱統一為 SwordCard；既有 Android appId 與 localStorage 舊鍵保留，以維持既有應用程式及存檔相容性。

既有私人試玩站沿用原網址及權限。此輪是 Git 儲存庫整合；推送程式碼與 Sites 發布是不同步驟。

遷移細節：[docs/REPOSITORY_MIGRATION.md](docs/REPOSITORY_MIGRATION.md)。

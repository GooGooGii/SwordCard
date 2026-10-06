# SwordCard 儲存庫整合 — 2026-10-06

使用者授權將新版 Three.js 工作樹覆蓋 SwordCard，視為同一遊戲，不建立新 GitHub 儲存庫。

- 遠端保留 `https://github.com/GooGooGii/SwordCard.git`，主分支 main，完整舊歷史保留。
- 遷移前 SwordCard HEAD：`e2b3f41`；新版來源 HEAD：`d925bbb`，另含已完成的四角色 STYLE D 本地變更。
- 來源 manifest 1591 檔／約 258 MB，每檔 SHA256 已驗證。含正常比例正式角色、文件、工具與驗收，排除未追蹤 Q 版候選、過程截圖、node_modules、hosting credential／產物。來源目錄仍保存原始內容，不刪除。
- 舊 Godot tracked files 移出目前工作樹，改為 Vite／React／Three.js，舊程式可從 Git 歷史復原。新 CI 跑 npm build／vitest，不再跑 Godot。原 tools/comfyui 的三支客戶端仍供新版美術工具使用，因此保留；改用相對儲存庫路徑。
- 網頁標題、主選單品牌、npm 包名稱、Android 顯示名稱及未來協作入口統一 SwordCard。李逍遙的角色 ID `li_xiaoyao` 與兼容性 appId／存檔鍵不改。
- 本機 `.git`、`.gitattributes`、使用者附件與忽略的工作檔保留。完整舊 Git bundle、來源 binary diff、檔案雜湊清單位於 `C:/Users/USER/source/repo-backups/SwordCard-before-web-20261006/`，未上传 GitHub。
- 本次要求為 commit + push。既有 Sites 站點 ID／網址／權限不改，沒有新建站點；本次 Git 推送不冒充線上改名已發布。

本地驗證通過：npm ci、npm run fonts、npm run build、npm test（119 passed / 1 skipped）。推送目標為 origin/main，保留未推送的既有 6 個歷史提交，不使用 force push。

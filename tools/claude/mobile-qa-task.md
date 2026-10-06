# QA-003 — Claude CLI 手機正式流程驗收

使用者明確授權 Codex 直接啟動本機 Claude Code CLI 分擔開發工作，節省 Codex 用量。你是本機 Claude Code，請完成以下工作，不只提出計畫。

工作目錄固定為 C:/Users/USER/source/repos/SwordCard（Three.js 網頁版），同一遊戲沿用 SwordCard 儲存庫。

先讀 AGENTS.md、CLAUDE.md、TASKS.md、docs/PROGRESS.md、docs/MOBILE_PLAY.md，查看 git status 與相關 diff。當前 Claude.md、docs/PROGRESS.md、src/App.tsx 有之前 Claude 的未提交改動；保留所有既有改動，禁止 reset、checkout 覆蓋或刪除。若同一範圍已有其他工作程序在改，先記錄衝突，不要競寫。

## 授權範圍與成果

1. 認領 TASKS.md 的 QA-003，寫實際開始時間、CLI session ID（若可取得）、修改範圍與進度百分比。所有進度回報帶範圍與百分比。
2. 在 production 建置上驗證正常起始選單 → 新的故事 → 存檔欄 → 序章／劇情 → 地圖 → 第一場戰鬥，以及重新載入後舊的回憶／讀檔能接續。手機橫向 844×390、DPR2、hasTouch，用真 touch 事件，不只 mouse click。補驗證存檔匯出／匯入：可下載後在乾淨 browser context 匯入並核對進度。
3. 優先沿用 tools/playthrough.mjs 與 Playwright，新增可重跑的 tools/qa/mobile-flow.mjs；畫面／JSON 報告放 docs/previews/mobile-flow。報告包含步驟、實際斷言、錯誤、存檔前後關鍵欄位。不要將 Chromium 模擬寫成實體 Android 驗收。
4. 若發現上述流程問題，修復相關 src/ui/、src/game/、src/platform/ 或正式入口（先核對既有 src/App.tsx diff，保留原本改動），附有意義的回歸驗證。新增介面文字需 npm run fonts。不要為只是低影響樣式寫鏡像測試。
5. 完成後 npm run build、npm test 各一次即可；沒有新錯誤不要反覆跑全套。只啟動必要預覽服務，選空閒埠，停掉自己啟動的服務，不能停止 Claude 桌面、其他人的服務或 ComfyUI。
6. 完成 docs/CLAUDE_HANDOFF.md 的具體交接，更新 TASKS.md 的 QA-003 與 docs/PROGRESS.md 自己新增的段落，不覆蓋整份文件。列修改檔案、驗證數量、截圖、已知問題、下一步，標完成度百分比。

## 邊界

- Codex 已完成 blood_pool 正式完整 3D、Boss 與旋流，src/stage/、血池 assets、tools/hosting/ 屬 Codex；本批不要修改。
- 23 個戰場目前只有血池完整 3D：1/23（4.3%）。其餘美術不能假稱已完成。
- SCENE-002 鎖妖塔 DOS 參照正在等使用者確認，禁止畫新角色／場景或替換正式美術；可閱讀盤點並提出下一批工作。
- 不提交 Git、不 push、不部署、不調整 Sites 私人權限、不存取部署憑證。本次修復留在工作目錄交給 Codex 驗收。既有網址已部署的版本不會自動跟著你的改動更新。
- 保留私人原型定位與既有核心規則；除真實重現的流程錯誤外，不大改遊戲設計或平衡。
- 請自主完成本批可驗證成果；碰到權限拒絕／登入限制，記錄具體阻礙，不假稱已執行。

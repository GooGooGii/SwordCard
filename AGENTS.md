# Codex 工作入口 — SwordCard

本專案統一命名為 SwordCard，使用 Three.js／React Three Fiber 網頁版，並沿用原 SwordCard Git 歷史與 GitHub 儲存庫。舊 Godot 版本可從歷史復原，不再作為目前建置入口。唯一主要工作目錄為 C:/Users/USER/source/repos/SwordCard；不要再把新版當成另一個 Xiaoyao 專案。

1. 每次工作開始先讀 [TASKS.md](TASKS.md)、[docs/PROGRESS.md](docs/PROGRESS.md) 與 [CLAUDE.md](CLAUDE.md) 的架構、指令與美術規則。
2. `TASKS.md` 是 Codex 和 Claude Code 共用的任務分派清單。先認領、註明修改範圍，再動手；表內建議分工不代表已有人開始工作。
3. 避免修改其他進行中任務負責的檔案。共享入口或樣式需在清單內寫清交接；先讀 `git status --short` 與相關 diff，不刪除或覆蓋對方未提交內容。
4. 完成一段、改變範圍、遇到阻礙與交接時更新自己的任務。程式實作、技術測試與使用者美術驗收分開記錄，不冒稱對方已完成或在工作。
5. 提交只包含自己確認的變更，不批次 stage 對方工作。`CLAUDE.md` 的 Claude 署名規則只適用於 Claude，不替 Codex 的工作加上該署名。
6. 新使用者指示優先於舊設計文件；目前場景朝 3D 呈現，原作起始選單已製作。涉及美術仍先查看 PAL1 原作遊戲圖，展示來源與可辨識元素，再做畫面驗收。2026-10-05 最新使用者授權：自行推進全部內容；Codex 對照原作圖後，主觀判斷相似度超過 90% 可直接製作／接入，不需逐張詢問，交由使用者完成後試玩細調。仍要實際查看並記錄原作圖、版本與辨識元素；主觀視覺估計不得冒充量化測量或使用者驗收。低於此門檻先自行重做，再決定是否需要問。

測試與建置：`npm run build`、`npm test`。新場景需有桌機與手機橫向版面驗證，尺寸模擬不得寫成 Android 實機效能通過。

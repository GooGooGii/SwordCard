# 手機外出遊玩 — QA-002

2026-10-05，Codex。**網址交付 100%，Sites 私人 HTTPS 部署 succeeded。**

[開啟逍遙](https://xiaoyao-private-play.googoo00166.chatgpt.site)

手機橫向開啟網址，使用建立站點的同一 ChatGPT 帳號登入即可。站點是雲端靜態部署，外出不需連家中 Wi-Fi，也不需電腦開機；載入遊戲需網路。私人存取沒有改成公開分享。

存檔存在各瀏覽器 localStorage；電腦、手機、不同網址與不同瀏覽器各自獨立。需要搬移時，使用遊戲存檔畫面的匯出／匯入；此部署未實作雲端同步。

## 驗證與版本

- production 建置成功；89 個測試通過／1 跳過。
- 正式血池：桌機 1280×720、手機 844×390 DPR2 觸控、高／低畫質，三藥品、六遺物、八手牌；藥品治療、出牌、長按預覽／鬆開不出牌，0 瀏覽器錯誤、0 HUD 超界、0 舊血池背景請求。見 [驗證記錄](previews/blood-release/validation.json)。
- 手機尺寸與觸控是 Chromium 模擬，尚未實體 Android／iPhone 驗收。
- 部署源 commit：`4b45d07d3b996ff0db375118a359c624997bea57`（隔離靜態 checkout）；該版本包含當時工作目錄中已接正式遊戲流程的 App.tsx 建置，原專案的 Claude 未提交源碼保持原樣。
- project：`appgprj_6ac335e5df98819185fb2d64d85bfff3`。
- version：`appgprj_6ac335e5df98819185fb2d64d85bfff3~appgver_c46675e6e1d081918b3866b8998ad1b4`。
- deployment：`appgdep_6ac338750a888191adb12cceb8103c3a`。

## 後續更新

1. 先讀 TASKS.md 並認領；保留對方的未提交改動。
2. 建置與必要測試／畫面驗證完成後，執行 `node tools/hosting/prepare-mobile-site.mjs`。它只將 dist 複製到指定 `hosting/mobile`，保留既有 `.openai/hosting.json` project_id。
3. 沿用 [Sites 技能](C:/Users/USER/.codex/plugins/cache/openai-curated-remote/sites/1.0.0-b/skills/sites/SKILL.md)，為同一 project 取得短期 source write credential，以 site-workflow helper 在隔離 checkout 提交、推送、打包。credential 只經隱藏 stdin，不放檔案／命令列／日誌。
4. Windows helper 需在程序 PATH 加 `C:\Program Files\Git\bin`，並設 `TAR_OPTIONS=--force-local`；archivePath 用 `C:/Users/USER/source/repos/Xiaoyao/hosting/xiaoyao-mobile.tar.gz`，避免 tar 把磁碟代號解讀為遠端主機。
5. 保留 owner-private audience，傳 pushed commit SHA 與匹配 archive 給 private save-and-deploy。非終態才查 deployment status；succeeded 回報原網址。禁止再次建立另一站。

`/hosting/` 已忽略；本專案只保存 tools/hosting/site.json 的非機密身分與準備腳本。站點版本只含必要靜態建置，不上傳原專案 Git、開發工具或 Claude 未提交來源。

## QA-003 網址更新（2026-10-05）

修復全新手機的存檔匯入入口，已在相同私人網址部署 succeeded；無需另建站。正式 TitleMenu 明確允許無本機存檔時進入讀檔／匯入，原型仍不允許無記憶續玩。正常入口、touch 劇情／地圖／戰鬥、重載讀檔、真實剪貼簿匯出、乾淨 context 匯入與錯誤輸入拒絕，共 9 項通過，瀏覽器錯誤 0。89 測試通過／1 跳過，建置與新文字自帶字型完成。

更新源 commit：`af638ce5bb579f64f83161428e85ab8457db489c`；version：`appgprj_6ac335e5df98819185fb2d64d85bfff3~appgver_e516dc03f0f48191b9e10b0b8c9b0c42`；deployment：`appgdep_6ac35151c3c08191b55b5d481bb2290e`。

手機搬移：原裝置遊戲「選單 → 匯出存檔」複製文字，再在手機「舊的回憶 → 匯入存檔」貼上並按匯入；存到第 3 欄，選該欄續玩。各裝置沒有自動同步，手機首次需自行搬移。[驗證與截圖](MOBILE_FLOW_QA.md)。


## SCENE-003 最新部署 — 2026-10-05

原網址更新成功：23 場 Three.js 完整地面／道具，修正高敌人裁切，112 測試通過（1 跳過）、22 個正式場景桌機／手機 44 張截圖全部通過。隔離靜態 source commit `8f50639fafdbc4360bfb138abf7be2bf64b20f70`；deployment `appgdep_6ac3643c6c9c819188cdfb2ffa12e725`，status `succeeded`。女媧神殿目前是故事節點，3D 模組另經舞台驗證。外出手機同一 ChatGPT 帳號登入即可；實體 Android 仍待使用者試玩。

## CHARACTER-001 完整模型版（2026-10-05）

原私人手機網址更新成功（100% 部署交付），場景 23/23、可操作角色 GLB 5/5。月如／阿奴／巫后的原作造型與三動作模型已接入，保留 2D 選項；正式 App.tsx 源碼整合。build、112 測試（1 跳過）、三模型／六視角／24 動畫幀、4 正式戰鬥桌機／手機畫面、9 項手機觸控／存檔驗證通過。仍是尺寸／觸控模擬，未宣稱實體 Android/iPhone 通過。

靜態源 commit：67754de2713b133a90b3cec38211c7da8f056928；version：appgprj_6ac335e5df98819185fb2d64d85bfff3~appgver_c60b292c7d6081918a6f8c9d8f9b957b；deployment：appgdep_6ac36ee9b5088191a9f7824b229bd6c1，succeeded。見 [模型與 QA](CHARACTERS_3D.md)。

## MOBILE-001 橫向入口（2026-10-05）

已部署（100% 實作／網址交付）。手機直向顯示「橫向全螢幕」，開始／繼續故事也嘗試 fullscreen → landscape lock；需要使用者點擊，支援與權限受瀏覽器／OS 限制。拒絕／不支援顯示手動旋轉，並可繼續查看；桌面不顯示提示。5 項 API 成功／失敗模擬、9 項手機流程、112 測試（1 跳過）及 build 通過，未宣稱實體手機鎖定成功。

靜態源 a7fb07bdfa64aee5a5b4a46a6dc2eb3d02e6ed86；deployment appgdep_6ac37f07e9908191870104b2c103fe32 succeeded；[詳細驗證](MOBILE_ORIENTATION.md)。

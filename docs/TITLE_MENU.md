# 3D 起始選單

2026-10-04：依使用者確認的《仙劍奇俠傳一》DOS 原版起始選單製作。

原作參考：[DOS 版遊戲心得與起始選單](https://taipeigoodgood.pixnet.net/blog/posts/11380278150)，[參考圖片](https://imgur.com/dmPTBvE)。保留黑底暖光、攤開的竹簡、斜放的帶鞘長劍、左後方的酒葫蘆，以及中央「新的故事／舊的回憶」兩行選單。

`src/menu/TitleStillLife.tsx` 使用 Three.js 幾何、程序材質、實時燈光與陰影。竹簡文字是公版李白《俠客行》，不把原作截圖當成場景背景。待機鏡頭緩慢移動；系統要求減少動態效果時保持靜止。主選單與戰場分別延遲載入，起始頁不下載角色 GLB。兩個畫面首次載入後保留 Canvas root，隱藏畫面設 `frameloop="never"` 停止渲染，避免卸載 drei Html 的 DOM root 時出現 React 重入與血條遺失。直接進壓力測試時不預載主選單。

2026-10-05：Claude Code 已在工作區將 `App.tsx` 接上正式遊戲；此入口檔由 Claude 提交，選單與原型模組由 Codex 提交。

- **新的故事**：一般網址開正式存檔欄與難度選擇，再開始九章行程。
- **舊的回憶**：一般網址選擇正式存檔並接續旅程；沒有存檔時禁用。
- `?stress`、`?perf`、`?battle`、`?resume` 保留戰鬥原型驗收入口；原型的返回／續玩保存真氣、手牌與各角色 HP，演出中禁止返回。
- 原型使用 `xiaoyao.prototype-memory.v1`，與正式存檔獨立；正式存檔與選單回呼由 Claude 負責。

驗證：`npm run build`、`npm test`，瀏覽器驗收初次進入、新遊戲、返回、續玩，以及手機橫向構圖。此項不包含 Android WebView 實機效能驗收。

2026-10-05 最新建置通過，全套測試 74 通過、1 跳過；原有選單視覺預覽在 `docs/previews/title-menu-*.jpg`。技術提交不代表使用者已完成美術驗收。

舊預覽抓到了載入畫面，2026-10-05 已重新擷取並實際查看完整桌機與手機畫面；截圖工具 `node tools/stage/capture-title.mjs` 會等待 Canvas、延遲載入與字型完成，兩次流程皆無瀏覽器錯誤。


## MENU-002 直向黑畫面修正（2026-10-05）

使用者手機直向截圖只有文字、背景幾乎全黑。以正式建置 390×727 和 360×800 重現：鏡頭距離乘以 1.35/aspect，但霧仍固定 12–23，靜物落在黑霧外緣。新增 titleFraming 純函式，使霧距離與遠裁切面隨同 fit 調整；保留橫向原有 12–23 霧與光照／模型。不是缺少素材，也不以提高全場曝光取代修正。

驗收：117 測試通過、1 跳過（含 5 個 framing 回歸）；build 通過。四尺寸正式建置截圖，直向→橫向→直向後背景仍可見，瀏覽器錯誤 0；回到直向會正常再次顯示橫向提示，點「先繼續查看」可看背景。這是瀏覽器觸控／版面模擬，未宣稱實體 Android 已驗收。

[修正前直向](previews/title-fog-before/title-menu-portrait.jpg)、[修正後直向](previews/title-fog-after/title-menu-portrait.jpg)、[修正後橫向](previews/title-fog-after/title-menu-mobile.jpg)、[轉回直向](previews/title-fog-after/title-menu-rotated-back.jpg)。截圖工具可用 TITLE_QA_URL 指定正式建置預覽，涵蓋桌機／橫向／兩種直向與轉向。

發布成功：沿用 https://xiaoyao-private-play.googoo00166.chatgpt.site ，deployment appgdep_6ac38532dea881919d3778480f7e0cd9 succeeded；靜態 source commit 611fc30839ab8ac5518c92f0333c269664c37077。

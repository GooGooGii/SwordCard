# 全戰場 Three.js 接入 — SCENE-003

2026-10-05，Codex。本批把剩餘 22 場改成真正 Three.js 地面與道具；加上已確認血池，共 23 場。原圖背景仍保留給明確自訂 Backdrop 的相容路徑，正式預設不再投影 JPG。

使用者最新授權自行推進，完成後試玩細調。原作 DOS 圖已逐張實際查看：[圖與來源](art-references/all-scenes/README.md)。每場辨識特徵與配色保留在 `src/stage/scenes/palSceneRecipes.ts`。相似度是視覺判斷，沒有量化 90% 的實測數字，也不代表使用者已驗收全部美術。

- 客棧保留灰綠／夜間藍灰斜磚、紅木格窗、燈籠、圓桌與長凳。
- 林家堡採紅木擂台與細金邊；塔頂採明王原作深紅橫紋，沒有另加屋頂。
- 岩洞依原作分別採青綠或灰褐岩壁；亂葬崗包含破碑、下凹墓穴與棺木。
- 尚書府採花園石磚、神木林採巨幹盤根、火麒麟洞採黃紅環流、水底迷宮採青黑波狀岩紋。
- 保留鏡頭、隊伍站位、戰鬥規則與已確認血池。正式戰鬥敵人最大高度改為 1.95，修復固定鏡頭裁掉頭部；模型、意圖與落點共用高度。

## 驗證

`npm run build` 通過；`npm test` 112 個通過、1 個跳過。22 個新場景逐一驗證 1–3 人雙方站位沒有被道具遮住、地面高度一致、20 draw／30,000 三角面預算與 geometry／material 重複清理防護。

[舞台畫面與資料](previews/all-scenes/validation.json)：23 場 × 桌機／手機橫向；[正式戰鬥資料](previews/all-scenes-release/validation.json)：22 場實際章節節點 × 桌機／手機，三人、三藥品、六法寶、八手牌，檢查 HUD 超界、瀏覽器錯誤與旧 JPG 請求。女媧神殿在九章流程是故事節點，僅使用獨立舞台測試，不為湊場景數改成戰鬥。

[生命週期](previews/all-scenes-lifecycle/validation.json)：同一 Canvas 血池↔新十里坡往返 14 次，暖機後 GPU 資源穩定，隱藏停止渲染、高低画質正常。正式手機觸控流程／重載／剪貼簿匯出入：[9 項通過](previews/all-scenes-mobile-flow/validation.json)。這些是桌機瀏覽器觸控與尺寸模擬，沒有冒稱實體 Android 效能驗收。

## 試玩

沿用[私人手機網址](https://xiaoyao-private-play.googoo00166.chatgpt.site)。部署資料在 [MOBILE_PLAY.md](MOBILE_PLAY.md)。既有九章、卡牌、劇情、音樂、存檔與地圖安排保持可玩；人物呈現仍依設定與現有資產使用 3D 模型／2D 立繪後備。可在使用者試玩後再調整造型、難度與手機效能。

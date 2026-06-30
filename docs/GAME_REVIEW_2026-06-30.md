# SwordCard 工作室視角 Review（2026-06-30）

> 範圍：製作人 / 設計 / 工程 / QA 四個視角。
> 依據：當前程式碼盤點、smoke test 實跑、四層 + 組隊 balance baseline 觀測值、
> 自 2026-06-10 上一份 `GAME_REVIEW_2026-06.md` 以來 106 個 commit 的差異。
> 定位：上一份報告的 15 項計畫（`IMPROVEMENT_PLAN_2026-06.md`）**已 15/15 全清**，本份是新狀態的重新體檢，不重述舊結論。

---

## 0. 總評

20 天內清掉整份改善計畫、又分叉出一套完整網頁版（`webgame/`）。產能極高，但開始出現
**範圍擴散**、**文件失真**、**單檔肥大** 三個結構性訊號，平衡的撕裂點也從「李逍遙過弱」
移動成「阿奴無敗場 / 趙靈兒終幕墊底 / 組隊免費勝利」。

---

## 1. 製作人視角 — 範圍與健康度

1. **`webgame/` 已是第二個完整遊戲（404 檔 / 108MB）。** 需要一個明確定位決策：
   行銷 demo（→ 凍結、不追本體平衡）還是未來主線（→ 為何還養 Godot 本體）。
   兩套各自維護數值/內容，**漂移是時間問題**。建議在 CLAUDE.md 寫死定位。
2. **CLAUDE.md 偏離現實**（本批已修一部分）：`main.gd ~2000 行`（實際 12,274）、
   藥品數 31/34（實際 37）。onboarding 契約的數字失真會侵蝕信任。
3. **零 telemetry**：所有節奏/平衡判斷都靠 BattlePolicy 模擬。8 幕單輪 ≈2.5h，
   短征已加但非預設。沒有留存數據，無法驗證「玩家實際打到哪一幕棄坑」。

## 2. 設計視角 — 平衡重心移動，未收斂

分級成長 baseline（註解自承這層才是「真實場景」）：

| 角色 | Lv5 | Lv10 | Lv15 | Lv20 |
|---|---|---|---|---|
| 李逍遙 | 100 | 97 | 77 | 93 |
| 趙靈兒 | 100 | 83 | 50 | **37** ← 新地板 |
| 林月如 | 100 | 100 | 63 | 50 |
| **阿奴** | **100** | **100** | **100** | **100** ← 無敗場 |

1. **阿奴在每個分級檔位都 100%**，全測試套件無一場會輸。蠱毒繞過護體，且分級 boss 陣容
   沒有任何「吃毒/抗 DoT」剋星（毒流剋星石長老只擺在中段閘門）。終幕 spread 趙 37 ↔ 阿奴 100 = **63pp**。
   - 建議：後期 boss（鎮獄明王或拜月教主）加吸毒/毒上限機制 + 趙終幕直傷再上修一階。
   - 失真注記：BattlePolicy「照疊毒餵 boss、真人可繞」→ 阿奴 100 部分偏心；但 **趙 37 是真問題**。
2. **組隊 = 免費勝利**：`duo_li_anu / trio` baseline 皆 100%。切人太便宜 + 敵 HP ×1.35/人補正不足。
   需決策：組隊是「變化模式」（明說不平衡）還是要真調。

## 3. 工程視角 — god object + 被吞的錯誤

1. **`main.gd` = 12,274 行 / 386 函式的上帝物件**，同時是 pause/debug menu、所有 screen、
   地圖輸入、戰鬥 UI、boon、shop、event、history、achievement、transition。最大可維護性債
   （commit `2a30a50` 曾因整檔 parse fail 連鎖炸 smoke test）。
   - 建議（漸進）：抽出低耦合 screen 控制器 `shop_screen.gd` / `event_screen.gd` / `map_screen.gd` /
     `boon_screen.gd`，各吃 run_state + 回呼、不碰戰鬥 alias。光搬 shop/event/map 可掉 3–4k 行。不大重寫。
2. **【本批已修】QA gate 印 ERROR 卻報 passed**：`_sfx()`（及 `_play_bgm()`）用絕對路徑 get_node，
   detached node 下丟 ERROR；測試非致命 print 照過。已加 `is_inside_tree()` 守衛 + CI 對 `ERROR:` 行判失敗。

## 4. QA 視角

1. **Baseline 層級半數飽和**：5 個 baseline dict 中 3 個（基礎/UPGRADED/MID_UPGRADED）全 100%，
   只能偵測 regression 下掉、偵測不到 buff。可合併飽和層成單一「上界守門」，細靈敏度集中在 MID / LEVELED。
2. **缺 UI 層 headless 覆蓋**：32 測試重戰鬥/資料/存檔；main.gd 386 個 UI 函式只靠肉眼截圖。
   抽 screen 控制器後即可補純函式測試（上面那個 `_use_potion` ERROR 正是 UI 路徑無 contract 所致）。
3. **未追蹤 `_relic_popup_preview.png.import`**：並行美術 session 產物，需決定入庫或 .gitignore
   （孤兒 .import 在 CI 首次匯入可能出事）。

---

## 5. 優先序

| 優先 | 項目 | 視角 | 狀態 |
|---|---|---|---|
| P0 | `_sfx`/`_play_bgm` 加 is_inside_tree 守衛 + CI ERROR tripwire | 工程/QA | ✅ 本批完成 |
| P0 | CLAUDE.md 同步（main.gd 行數、藥品數 37） | 製作人 | ✅ 本批完成 |
| P1 | 趙靈兒終幕上修 + 後期 boss 加抗毒機制（拉阿奴下凡） | 設計/平衡 | 待辦 |
| P1 | 決策：組隊平衡定位 / webgame demo-or-主線 | 製作人 | 待辦 |
| P2 | 抽 shop/event/map screen 控制器出 main.gd | 工程 | 待辦 |
| P2 | 合併飽和 baseline 層 + 補 UI 純函式測試 | QA | 待辦 |
| P3 | 最小本地 telemetry（run 結束寫勝率/死因，補節奏盲區） | 製作人/數據 | 待辦 |

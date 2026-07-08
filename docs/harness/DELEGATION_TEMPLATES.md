# 派工 Prompt 模板（DELEGATION_TEMPLATES）

> 讀者：未來的主模型。派 subagent 時**直接抄對應模板填空**，不要即興發揮——
> 歷史教訓是即興派工最常漏「驗收條件」和「回報格式」，agent 就回來一大坨檔案內容。
> 【】是填空處。model / agent 型別的選法見 `DISPATCH.md` §2–3。

## 共用尾巴（每個模板結尾都要帶）

```
回報格式：
- 第一行先講結論
- 證據一律用 檔案路徑:行號，不要貼大段檔案內容
- 長產物寫到【落檔路徑，如 docs/ 或暫存 _report.md】，回傳路徑即可
- 最後一行固定：「驗收：PASS/FAIL/PARTIAL — <一句證據>」（PARTIAL = 部分條件過，逐條說明哪條沒過）
- 全文不超過 30 行
```

---

## 1. 搜尋 / 定位（subagent_type: `Explore`，model 省略）

```
目標：找出【要找什麼：函式/慣例/所有呼叫點/資料流】，因為【動機：我接下來要改什麼】。
範圍：【目錄或檔案範圍；不確定就寫「整個 repo，排除 assets/」】。搜尋廣度：【medium / very thorough】。
已知線索:【已知的關鍵字、類名、大概位置；沒有就寫「無」】。
驗收條件：每個相關位置都列出 檔案:行號＋一句它是做什麼的；如果找不到，明說「未找到」並列出你搜過的模式。
注意：scripts/main.gd 有 12,000+ 行，用 Grep 定位後只讀片段，不要整檔讀。
```
（＋共用尾巴）

**填好的範例**：
> 目標：找出所有讀取 `state["enemy_hp"]` 的位置，因為我要改多敵 alias 同步邏輯，需要知道有誰依賴這個 alias。
> 範圍：scripts/，搜尋廣度 medium。已知線索：battle_controller.gd 的 `_sync_active_enemy_to_state`、effect_resolver.gd。
> 驗收條件：每個讀寫點列 檔案:行號＋讀還是寫＋一句用途；找不到的話列出搜過的 pattern。

## 2. 實作（subagent_type: `general-purpose`，model: `sonnet`）

```
目標：實作【功能/修復】，因為【動機】。
規格：【具體行為：輸入→輸出、UI 長什麼樣、數值多少】。
範圍：只改【檔案清單】；不要動【明確排除項，至少寫「不要動 BALANCE_BASELINES 和其他未列出的檔案」】。
必讀脈絡：CLAUDE.md 的「常見地雷」與「Key Conventions」；【其他相關檔案:行號】。
驗收條件：
1. godot --headless --path . -s scripts/smoke_test.gd > _smoke_out.txt 2>&1 → 檔尾有 "SwordCard smoke test passed."、exit 0、且全檔無 "ERROR:" 行
2.【功能自身的可驗證判準，如：新測試 _test_xxx 通過】
3.【UI 改動才加：render 截圖並 Read 確認【預期看到什麼】，看完刪 PNG+.import】
做完刪你產生的暫存檔。遇到地雷清單裡的狀況照清單處理，不要自創 workaround。
```
（＋共用尾巴）

**填好的範例**：
> 目標：新增藥品「七星海棠」（rare，對單敵 15 傷害＋3 蠱毒），因為使用者要補一瓶毒系攻擊藥。
> 規格：id `qixing_haitang`，effects `[{"kind":"damage","amount":15},{"kind":"poison","amount":3}]`，描述「劇毒名花，入藥見血封喉。」
> 範圍：只改 scripts/potion_catalog.gd、scripts/smoke_test.gd（藥品數 37→38 的鎖數測試）、docs/design/POTIONS.md（清單同步）。不要動其他檔案。
> 必讀脈絡：CLAUDE.md 地雷清單；docs/design/POTIONS.md 的資料模型段。
> 驗收條件：1. smoke 導檔綠且 exit 0；2. `_test_potion_catalog` 對 38 種藥全過；3. POTIONS.md 清單含新藥一行。

## 3. 重構（subagent_type: `general-purpose`，model: `sonnet`；>5 檔或動核心資料流 → `opus`）

```
目標：把【現狀】重構成【目標形狀】，因為【動機】。
不變式（最重要）：行為完全不變——重構前先跑一次 smoke 確認基準是綠的，重構後再跑必須同樣綠；
BALANCE_BASELINES 一個數字都不准動（動了 = 你改到了行為，回頭找原因）。
範圍：【檔案清單】。禁止順手修 bug 或改行為——發現 bug 記下來回報，不要修。
驗收條件：
1. 重構前後 smoke 都綠（兩次都導檔留證據）
2.【結構性判準，如：main.gd 減少 N 行 / 新模組有 class_name 並過 --import】
```
（＋共用尾巴）

## 4. 研究（web / 文件）（subagent_type: `general-purpose`；Claude Code 功能問題改用 `claude-code-guide`）

```
目標：查清楚【問題】，因為【這會決定什麼決策】。
要分清「來源說的」和「你推論的」，推論要標明。
每個結論附來源 URL 與（可判斷時）發布日期；互相矛盾的來源都列出來。
查不到就回報「查不到」＋你試過的關鍵字，不要編。
驗收條件：【決策需要的具體問題清單】每題都有「答案＋來源」或「查不到」。
產出寫到【路徑】，主回報只給每題一行結論。
```
（＋共用尾巴）

## 5. 審查 / 驗收（subagent_type: `verifier`；高風險判斷 model: `opus`）

```
待驗對象：【diff 範圍 / 檔案清單 / 「宣稱已完成的功能 X」】。
背景：【一兩句這改動要達成什麼——不要附實作過程的推理，讓它自己看】。
逐條驗收條件：
1.【可執行判準】
2.【可執行判準】
3.【...】
只驗證不修改；宣稱「已通過」的項目要重跑確認；條件不可驗證就回報不可驗證。
```
（＋共用尾巴）

**填好的範例**：
> 待驗對象：scripts/save_manager.gd 與 scripts/run_state.gd 的 v2→v3 migration（宣稱已完成）。
> 背景：potions 結構加了 charges 欄位，舊存檔要能無損升級。
> 逐條驗收條件：
> 1. smoke 導檔綠且 exit 0，其中 `_test_save_migration` 與 potion 相關 5 測全過
> 2. Grep 確認 migrate() 有 version 2 的 case 且舊 keys 未被 erase
> 3. SAVE_VERSION 常數 == 3

---

## 使用備忘

- 獨立任務**同一則訊息並行派**；有依賴就等前一個結果。
- 派出去就不要自己同步做同一件事。
- agent 回報後：結論要在你給使用者的回覆裡復述（使用者看不到 agent 訊息）。
- 模板不合用的任務型態：照「三件套」自組（目標與動機 / 驗收條件 / 回報格式），並考慮把新型態加進本檔（規則見 MAINTENANCE.md）。

# 判斷力判準（JUDGMENT）

> 讀者：未來在這個 repo 工作的主模型。這份把「什麼時候該做什麼」寫成可查表的判準，每條附正反例。
> 「怎麼派、派給誰」的機制在 `DISPATCH.md`。卡住時先查這份，再行動。

## §1 何時該升級模型（辨識訊號；升級的操作方式見 DISPATCH §5）

任一訊號成立 → 升級（或你已是最高可用模型 → 問使用者）：

- **訊號 A：任務需要同時持有 ≥3 個子系統的交互**。本 repo 的典型：改 damage 公式（EffectResolver + CardFormat.predict_enemy_damage 雙實作同步 + smoke 9 組合測試 + BALANCE_BASELINES 全部牽動）；改戰鬥 state 欄位（牽動 player/enemy 兩套 alias sync 共四個函式）。
- **訊號 B：兩次修復嘗試產生兩種不同的新錯誤**（不是同一個錯沒修好，是越修越歪）。
- **訊號 C：東西「能動了」但你說不出為什麼之前不能動**。不懂根因的修復在這個 repo 的歷史裡都會回來咬人。

**正例**：改了 EffectResolver 的 vulnerable 計算，smoke 的傷害預測一致性測試掛掉；改了兩次，換不同組合 fail → 這是雙實作同步問題（訊號 A+B 同時成立），停手，派 opus 帶完整失敗軌跡讀兩邊完整路徑。
**反例**：smoke test 報某新卡缺 `art_path` → 機械問題，補圖或 `art_id` 借圖即可，升級是浪費。

## §2 何時算真的完成（Definition of Done）

**驗證 = 執行過並看到預期結果，不是「程式碼看起來對」。** 沒跑對應驗證 = 沒完成，不准對使用者說「完成」。

| 改動型態 | 完成判準（指令與預期） |
|---|---|
| 任何 .gd 邏輯 | `godot --headless --path . -s scripts/smoke_test.gd > _smoke_out.txt 2>&1` → 檔尾有 `SwordCard smoke test passed.`、exit 0、且全檔無 `ERROR:` 行（CI tripwire 會擋）；看完刪暫存 |
| 新增 `class_name` | 先 `godot --headless --path . --import`（單獨跑，不要鏈 smoke），再跑 smoke |
| UI / 動畫 | 用對應的 render 工具截圖（render_effects / render_battle_ui / render_event / render_battle_backgrounds .gd）→ **Read 那張圖** → 能用一句話說出「圖上哪個元素證明改動生效」→ 刪 PNG+`.import`。跑了截圖但沒 Read = 沒驗 |
| 平衡調整 | 重跑 smoke 看實際勝率 → 按 CLAUDE.md「平衡 regression 失敗時怎麼處理」分類 → 故意調整要更新 `BALANCE_BASELINES` 並在 commit message 寫方向與原因 |
| RunState 結構改動 | migration case + round-trip smoke 測試（參考 `_test_save_migration`）都綠 |
| 新增卡 / 敵人 / 藥 | smoke 綠（資料完整性 assert 會抓缺圖缺欄位）＋ 對照 `docs/PAL1_CANON.md` 確認正史依據＋同步對應 docs/design 清單 |
| 文件 / 制度檔 | read-back：實際 Read 關鍵段落確認寫進去了；檔內引用的路徑用 Glob 驗證存在 |

**正例**：改了出牌特效 → 跑 render_effects.gd → Read `_qijianzhi.png` → 「劍氣粒子現在從手牌位置出發而不是畫面中央」→ 刪暫存 → 完成。
**反例**：改了卡片數值 → 跑 smoke → 輸出幾百行沒導檔也沒 grep 關鍵字 → 宣告完成。歷史上這正是「assert 假卡死、passed 根本沒印」被漏掉的方式。

## §3 何時該停下來問使用者

問之前先自查：這是「使用者才能做的決定」還是「我懶得查」？後者自己查。該問的四類：

1. **破壞性動作**：刪 assets、對未 commit 檔案跑 `git checkout --`/`reset --hard`、整批重置 `BALANCE_BASELINES`、改 SAVE_VERSION 語意。
2. **設計支柱衝突**：新內容在 PAL1 正史找不到依據、平衡改法會消滅某角色的獨特解法、新機制讓某決策失去代價（對照 CLAUDE.md 三支柱）。
3. **Scope 翻倍**：修 A 途中發現真正該修的是 B，且 B 的範圍超過原任務 2 倍 → 報告發現、附建議、等指示；不要順手做完。
4. **品味題**：卡牌命名、flavor 文案、美術風格取捨 → 產 3 個候選＋各自理由讓使用者選，不要自己定案。這是模型等級差距最大的地方，一個平庸定案會永久留在遊戲裡。

**正例**：做毒系新卡時發現想要的效果需要新 effect kind，而加新 kind 會牽動 EffectResolver + 藥品 + smoke 多處 → 停，報告兩個方案（複用既有 kind 的降級版 vs 完整新 kind）＋建議，等使用者選。
**反例**：兩個等價的 helper 函式命名、測試該放哪個位置、要不要先跑 smoke → 自己決定照慣例做。問這種問題是把決策成本轉嫁給使用者。

## §4 方向錯了的訊號（該換路，不是再試一次）

任一成立 → 停止當前路線，寫下已試軌跡，換方法或按 §3 上報：

- **同一個測試在兩種不同修法後仍 fail** → 多半改錯層了（改錯檔案？雙實作沒同步？測試本身過時？）先驗證你對故障的理解，再修。
- **為了讓測試過而加特例分支**（`if test_mode` / 硬編某個值）→ 你在騙測試，不是在修 bug。
- **修法違反 CLAUDE.md 地雷清單**（例：smoke「卡死」想加 timeout 硬等、想把 `--import` 鏈進指令）→ 地雷清單就是前人踩過的坑，先照清單處理。
- **預估 30 分鐘的事做了兩輪還在發散**（改動檔案數超過預估 2 倍、或開始動「順便發現」的東西）→ 收手，回到原任務最小改動。

**與 §1 的分工**（「連錯兩次」同時觸發兩邊時的優先序）：先走本節——驗證你對故障的理解、換切入點；換路之後若判斷「理解沒錯，是複雜度超出我」（§1 訊號 A / C 也成立）才升級模型（操作見 DISPATCH §5）。分不出是哪種就直接升級——升級自帶 fresh 視角。無論走哪條，同一方法總共不超過兩輪（DISPATCH §5 的總上限）。

**正例**：smoke test 看起來「卡死」→ 想起地雷清單「assert 假卡死」→ 輸出導檔看 `SCRIPT ERROR` → 找到真正的 assert 行號。（錯誤做法：調大 timeout 再跑一次。）
**反例（不該換路的情況）**：指令第一次失敗是因為路徑打錯 → 修路徑重跑即可。一次性的低級錯誤不是方向錯訊號，別因此推翻整個方法。

## §5 品質底線怎麼驗（高風險分級）

**基本底線**（每次改動都適用，違反任一 = 不合格）：
- typed GDScript（有型別註記，跟周圍程式碼一致）
- 不用 `assert()` 寫正式邏輯；`_test_*` 內用 `_check`
- 新卡/敵人有美術與正史依據；`.import` 檔入庫
- 改動有對應 smoke 覆蓋（新機制要加測試，不是只有手動確認）

**高風險改動**（任一成立 → 驗收必須派 fresh-context `verifier`，見 DISPATCH §6）：
- 動到存檔格式 / migration（壞了使用者丟進度）
- 動到 damage 計算或 alias sync（雙實作、四個 sync 函式，最容易錯層）
- 動到 `BALANCE_BASELINES`（錯的 baseline 會讓之後所有 regression 失去意義）
- 一次改動 >5 個檔案

**正例**：改了 v2→v3 save migration → 自己跑 smoke 綠了 → 仍派 verifier 給它三條驗收條件（migration 測試綠 / 舊檔欄位保留 / round-trip 不丟卡）獨立重驗。
**反例**：自己寫的 migration 自己跑一次測試就簽收——實作時「以為欄位叫 X」的錯誤假設，在自驗時會再騙你一次。fresh context 才會用檔案裡實際的欄位名去驗。

## §6 制度補不了的事（誠實條款）

拆解、驗證、多樣本評審能補**執行品質**；以下補不了，遇到就照指示繞：

- **品味與美感**（命名語感、文案風格、美術判斷）→ §3 第 4 類：多案＋使用者選。不要假裝制度能讓小模型寫出《幽冥仙途》的語感。
- **模糊的產品方向題**（「組隊要不要真調平衡」這類製作人決策）→ 用 CLAUDE.md 設計支柱裁決；支柱裁不了的直接問使用者，不要自己拍板。
- **全新架構判斷**（引入新系統、大重構路線）→ 產 2–3 個方案各附取捨，`Plan` agent + opus 出第二意見，最終讓使用者選。
- 以上情境中，「明說做不到、把選擇交回使用者」是合格行為，不是失敗。

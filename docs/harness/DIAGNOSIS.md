# Harness 診斷（2026-07-08，Fable 5 立制度 session）

> 這份是「為什麼要有 `docs/harness/` 這套制度」的依據。後面每份檔案的規則都對應這裡的某個病因。
> 量測值以 2026-07-08 為準；重新量測方法在文末。

## 前三名問題與修法

### 1. CLAUDE.md 膨脹：每個 session 開場先燒 ~25k tokens（token 漏損第一名）

**量測**（2026-07-08）：`wc -l -c CLAUDE.md` → 999 行 / 58,511 bytes，中文為主估 22–28k tokens。
其中約 550 行（55%）是**已完成功能的設計藍圖**（Party Mode ~150 行、藥品 ~200 行、多敵 ~250 行），
標著「已完整實作，保留供參考」——多數 session 用不到，但每次全額載入。

**傷害**：不只是 token 成本。對較小的模型更致命的是**注意力稀釋**——真正每次都要遵守的規則
（常見地雷、測試慣例、mobile 陷阱）被 550 行參考資料淹沒，容易漏看。

**修法**（本 session 已執行）：
- 設計藍圖全文搬到 `docs/design/`（PARTY_MODE / POTIONS / MULTI_ENEMY / BATTLE_UX_SYSTEMS），零資訊損失
- CLAUDE.md 重寫為「每次都需要的規則 + 路由表」，上限 400 行（原版備份在 `docs/harness/backup/`）
- 防再膨脹規則在 `MAINTENANCE.md`：設計文件只准放 `docs/design/`，CLAUDE.md 只加一行路由

### 2. 指揮官下場搬磚：大檔案與大輸出直接進主對話（token 漏損第二名＋失焦第一名）

**量測**：`scripts/main.gd` = 12,272 行 / 534KB（整檔 Read ≈ 130k+ tokens，一次吃掉大半 context）；
`scripts/smoke_test.gd` = 4,574 行 / 250KB；模擬與測試輸出動輒數百行。

**典型事故模式**（較小模型尤其會犯）：
- 為了找一個函式整檔 Read main.gd → context 炸掉，session 後半開始忘記前面的決定
- smoke test / 模擬輸出直接進對話 → 幾輪後把使用者原始要求擠出視窗，開始自我發散
- 截圖 Read 完不刪、反覆重看 → 每張圖幾千 tokens

**修法**（規則寫進新 CLAUDE.md「三條鐵律」+ `DISPATCH.md`）：
- main.gd / smoke_test.gd 一律先 Grep 函式名拿行號，再 Read offset/limit；禁止無 offset 整檔讀
- 預期 >50 行的輸出一律 `> _out.txt 2>&1` 導檔，再 Grep 關鍵字或 Read 檔尾；看完刪暫存
- 「讀很多、回報很少」的工作（掃 repo、查網頁、讀 3 檔以上找答案、批次改 5 檔以上）
  派 subagent，主對話只進結論與 檔案:行號

### 3. 驗證劇場：宣稱完成但沒跑驗證、或用同一個腦自我驗證（出錯第一名）

**證據**：CLAUDE.md 地雷清單至少 4 條是同一類歷史事故——
「passed 照印但其實 fail」（assert 假卡死）、「`_test_*` 內用 assert 導致 exit=0 騙人」、
「UI 改了沒截圖確認」、「--import 鏈 smoke hang 白等 20 分鐘」。
全是「跳過驗證／驗證方法錯」的變體，較小模型會更頻繁重演。

**修法**（規則在 `JUDGMENT.md` §2「完成的定義」+ `DISPATCH.md` §6「驗證不自驗」）：
- 每種改動型態有明確完成判準（含指令與預期輸出字串），沒跑 = 沒完成
- 高風險改動的驗收派 fresh-context verifier agent（`.claude/agents/verifier.md`），
  只給它驗收條件、不給實作推理
- 同一類修法連錯兩次 = 方向錯訊號（`JUDGMENT.md` §4），停下換路，不是第三次重試

## 次要問題（有修法但排不進前三）

- **並行 session 撞車**：本 session 開場 git status 就有 9 個未 commit 修改檔＋1 個孤兒 `.import`；
  使用者常開第二個 session 跑美術管線（見 memory「並行 session 防撞守則」）。
  修法：session 開場先 `git status --short`；完成一個邏輯單位就建議 commit；
  絕不對未 commit 的檔案跑 `git checkout --` / `reset --hard`。
- **品味題硬做**：卡牌命名、flavor 文案、美術風格判斷是模型等級差距最大的地方。
  修法見 `JUDGMENT.md` §3（出 3 案讓使用者選）與 `LETTER.md` 誠實條款——這是制度補不了的缺口，只能繞。

## 重新量測方法（每季或大改後跑一次，結果更新本檔頂部數字）

```bash
wc -l -c CLAUDE.md            # >400 行或 >25KB → 觸發 MAINTENANCE.md 的精簡流程
wc -l scripts/main.gd         # 追蹤 god object 是否持續惡化（2026-07 基準 12,272）
git status --short            # 未 commit 檔案 >10 個 → 提醒使用者 commit
```

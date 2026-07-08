# 模型調度守則（DISPATCH）

> 讀者：未來在這個 repo 工作的主模型（Sonnet / Opus / Haiku 等級）。
> 這份講「怎麼派」（機制、模型選擇、升降級）；「什麼時候該派 / 該停」的判斷訊號在 `JUDGMENT.md`；
> 派工 prompt 直接抄 `DELEGATION_TEMPLATES.md`。三份不重複，衝突時以本檔為準（機制類）。

## 1. 核心原則：指揮官不下場

主對話（你）只做：決策、看 diff、跟使用者溝通、1–3 個檔案的直接實作。
以下工作**派 subagent**，主對話只進結論與 檔案:行號：

| 觸發條件（任一成立就派） | 派什麼 |
|---|---|
| 回答問題需要讀 3 個以上檔案、或掃目錄結構 | `Explore` |
| 需要查網頁 / 官方文件 | `general-purpose`（或 Claude Code 功能問題用 `claude-code-guide`） |
| 批次改 5 個以上檔案（已解出的模式重複套用） | `general-purpose` + 便宜模型 |
| 跑長時間模擬 / 大量測試並解讀結果 | `general-purpose` |
| 驗收你自己（或別的 agent）做完的工作 | `verifier`（見 §6） |

**反面——這些不要派**（派了反而更慢更貴）：
- 單點查找且你知道位置 → 直接 Grep / Read
- 你接下來就要 Edit 的檔案 → 本來就得 Read，自己讀自己改
- 已經派出去的搜尋 → 等結果，不要自己再搜一遍
- 派工前自己先花 1–2 個 Grep 確認任務範圍（scout inline），再派——盲派會拿到答非所問的結果

## 2. 本環境可用機制（2026-07-08 實測；每次用前以當下 session 的工具 schema 為準，不要憑印象）

- **Agent 工具**：`subagent_type` 可用 `general-purpose` / `Explore` / `Plan` / `claude` / `claude-code-guide` / `verifier`（自訂，見 §6）。
  `model` 參數 2026-07 實測 enum 為 `sonnet` / `opus` / `haiku` / `fable`；未來以當下 session 的 schema 為準。
  **Agent 工具沒有 effort 參數**——不要塞，會 InputValidationError。不確定用什麼 model 就省略（繼承主模型）。
- **並行**：互相獨立的 agent 在**同一則訊息**一起發；預設背景執行，完成會通知你，**不要輪詢**。
  要接續某個 agent 的 context 用 `SendMessage`（帶 agent ID / name），不要重開新的。
- **自訂 agent**：`.claude/agents/<name>.md`（frontmatter 可設 `model` / `tools`），是「固定角色＋固定模型」的長效做法。
- **Workflow 工具**：需要使用者明確 opt-in（說「用 workflow」/「ultracode」）才能用；它的 `agent()` 才有 `effort` 參數（`low`–`max`）。使用者沒開口就用 Agent 工具。
- **Skills**：`code-review`（等級參數 low/medium/high/xhigh/max）、`verify`（實跑驗證改動）、`simplify`、`gamestudio`（遊戲開發全流程）、`deep-research`。任務對得上就先用 skill，不要重造。

## 3. 模型選擇表

| 任務型態 | model | 理由 |
|---|---|---|
| repo 搜尋 / 定位 | 省略（繼承主模型），用 `Explore` | 搜尋品質吃推理，繼承最穩 |
| 機械批次套用（模式已解出、有逐檔清單） | `haiku` | 便宜；錯了成本低（見 §5 升級） |
| 一般實作 / 修 bug / 寫測試 | `sonnet` | 性價比基準線 |
| 跨子系統設計、計畫（動 3+ 子系統） | `opus`，用 `Plan` | 需要同時持有多系統交互 |
| 對抗審查 / 第二意見 / 高風險驗收 | `opus`（或省略），用 `verifier` | 驗證品質決定下限 |
| 品味題（卡牌命名、flavor 文案） | `opus` 產 3 案 → **使用者選** | 制度補不了品味，見 JUDGMENT §3 |
| Claude Code / API 功能問題 | 省略，用 `claude-code-guide` | 它查官方文件，不憑記憶 |

主模型本身是 Opus 時：1–3 檔實作留在主對話即可；主模型是 Haiku 時：任何非機械任務都往上派 `sonnet`。

## 4. 派工三件套 + 回報合約

每個派工 prompt 必含三件套（模板見 `DELEGATION_TEMPLATES.md`）：

1. **目標與動機**：要什麼＋為什麼要——動機讓 agent 在小決策上不用回來問你
2. **驗收條件**：可執行的判準（跑什麼指令、預期輸出哪個字串、哪個檔案該存在）；寫不出驗收條件 = 你自己還沒想清楚，先想
3. **回報格式**：規定它回什麼、不准回什麼

**回報合約**（寫進每個派工 prompt 的固定尾巴）：
- 第一行先講結論（成功/失敗/找到什麼）
- 證據用 `檔案路徑:行號`，不貼大段檔案內容
- 長產物（報告、清單、log）寫到檔案，只回傳路徑
- 最後一行固定格式：`驗收：PASS/FAIL/PARTIAL — <一句證據>`
- 全文 ≤ 30 行

Agent 的回報只有你看得到，使用者看不到——**重要結論要在你的最終回覆裡復述**，不要只說「agent 做完了」。

## 5. 升降級路徑

- **haiku 錯一次 → 直接升 sonnet 重做**。不要 debug haiku 的產出（debug 成本 > 重做成本）
- **sonnet 在同一子任務連錯兩次 → 升 opus**，且必須帶完整失敗軌跡：試過什麼、每次的錯誤輸出、目前的假設。沒有軌跡的升級 = 讓 opus 重走一遍彎路
- **降級**：opus/sonnet 解出的模式（例如「這 20 個檔案都要把 X 改成 Y」）→ 寫成逐檔明確清單 → 派 haiku/sonnet 批次套用
- **同一件事最多重試兩輪**。第三輪之前必須換方法（換模型、換切入點、或拆小），或按 JUDGMENT §3 停下問使用者
- 主模型自己也適用：你（主模型）在同一問題卡兩輪 → 派 opus subagent 帶完整軌跡，或問使用者

## 6. 驗證不自驗

寫程式的腦不能當驗收的腦——實作時的假設會原封不動帶進驗證裡。

- **驗收派 fresh-context agent**：用自訂 `verifier` agent（`.claude/agents/verifier.md`）。給它「驗收條件清單＋待驗對象」，**不要給實作過程的推理**（會污染它）
- **檔案類產出**：read-back——驗證檔案存在、行數合理、關鍵段落實際讀出來核對
- **程式碼**：跑 smoke test（指令與成功判準見 CLAUDE.md「Run / Test」）；UI 改動必須實機截圖（CLAUDE.md「實機渲染截圖」）
- **高風險判斷**（平衡調整方向、架構選型）：第二意見——派一個 agent 獨立解同一題，比對結論；或產 3 案由使用者/評審 agent 選優
- 什麼算「高風險」的判準在 `JUDGMENT.md` §5

## 7. 踩坑紀錄（派工相關的教訓寫這裡，格式見 MAINTENANCE.md）

- （2026-07-08 建檔，暫無）

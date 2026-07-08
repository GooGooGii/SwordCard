# 制度檔案維護協議（MAINTENANCE)

> 讀者：未來的主模型。這份規定 CLAUDE.md 與 `docs/harness/` 怎麼安全地演化。
> 制度檔案清單：`CLAUDE.md`、`docs/harness/{DIAGNOSIS,DISPATCH,JUDGMENT,DELEGATION_TEMPLATES,MAINTENANCE,LETTER}.md`、`.claude/agents/verifier.md`。

## 1. 改之前

- **先備份**：目標檔已被 git 追蹤且工作樹乾淨（`git status --short <檔>` 無輸出）→ git 就是備份，直接改；
  有未 commit 改動 → 先 `cp <檔> docs/harness/backup/<檔名>.bak-<YYYYMMDD>` 再改。
- **先讀本檔 §2 的紅線**，確認你要改的東西不在紅線內。

## 2. 什麼可以自己改、什麼要先問使用者

**可以自己改（隨做隨改，不用問）**：
- 往 CLAUDE.md「常見地雷」加新地雷（格式見 §3）
- 往 DISPATCH §7、或各檔的教訓區**追加**踩坑紀錄
- 往 JUDGMENT 的判準**補充正反例**（不改判準本身）
- 往 DELEGATION_TEMPLATES 加新任務型態的模板
- 更新 DIAGNOSIS 的量測數字（重跑文末指令後）
- 修正確定過時的事實（工具改名、檔案搬家）——但要在改動處註記日期

**紅線（動之前必須先問使用者）**：
- 刪除或放寬任何既有規則（門檻數字、鐵律、地雷條目、紅線本身）
- 改 CLAUDE.md 的設計支柱、內容創作原則
- 改升降級門檻（DISPATCH §5 的次數）或 DoD 判準（JUDGMENT §2）
- 把 docs/design/ 或其他長文內容貼回 CLAUDE.md（永遠違規：設計文件放 docs/design/，CLAUDE.md 只加一行路由）
- 刪 `docs/harness/backup/` 裡的備份

判斷原則：**加例子、加紀錄、修錯字 = 自由；改規則語意、刪東西 = 先問。**

## 3. 踩坑教訓寫回哪裡、什麼格式

踩了坑（浪費 >15 分鐘、或同一問題第二次出現）就在**當次 session 內**寫回，不要「之後再補」：

| 教訓類型 | 寫到 |
|---|---|
| 工具 / shell / Godot / CI 的坑 | CLAUDE.md「常見地雷」 |
| 派工失敗模式（agent 答非所問、模型選錯） | DISPATCH §7 |
| 判斷失誤（該問沒問、該停沒停、假完成） | JUDGMENT 對應 § 的反例 |
| 遊戲設計 / 平衡的教訓 | `docs/BALANCE_REPORT.md` 或 docs/design/ 對應檔 |
| 使用者偏好、跨專案的事 | memory（`~/.claude/projects/.../memory/`），不是 repo |

**格式**（一條一段，可直接執行）：
```
- **不要 X / 要先 Y**：一句症狀 + 一句根因 + 正確做法（含指令或檔名）。（YYYY-MM-DD）
```
反面示範：「注意 smoke test 可能有問題」——沒有症狀、沒有做法，等於沒寫。

## 4. 大小預算與精簡流程

| 檔案 | 上限 | 超過時 |
|---|---|---|
| CLAUDE.md | 400 行 | 觸發精簡 |
| docs/harness/ 各檔 | 300 行 | 觸發精簡 |

精簡流程（超標的那次 session 順手做，或提醒使用者排程做）：
1. 合併重複條目（同一教訓的多次變體 → 留最完整的一條）
2. 一年以上沒再踩過、且根因已被結構性修掉的條目 → 搬到 `docs/harness/archive/<檔名>-<YYYY>.md`（不是刪除）
3. 長參考內容 → 抽成 docs/ 新檔＋路由一行
4. 精簡屬於「刪東西」→ 動手前列出要刪/搬的清單問使用者

memory 的精簡另有工具：skill `anthropic-skills:consolidate-memory`。

## 5. 防退化檢查（每季或使用者要求時跑一次）

```bash
wc -l CLAUDE.md docs/harness/*.md   # 對照 §4 上限
git status --short                   # 制度檔有沒有長期未 commit 的漂移
```
- 抽查 3 條規則：規則引用的檔案 / 函式 / 工具還存在嗎？（用 Grep/Glob 驗，失效就照 §2 修正並註記）
- 檢查 DISPATCH §2 的模型清單是否仍與當下 Agent 工具 schema 一致
- 結果更新進 DIAGNOSIS 的量測數字

## 6. 這套制度的由來

2026-07-08 由 Fable 5 session 建立（該 session 的診斷依據見 `DIAGNOSIS.md`、交接與展望見 `LETTER.md`）。
原版 999 行 CLAUDE.md 備份在 `docs/harness/backup/CLAUDE.md.bak-20260708`。

# AI 平衡驅動器（Agent-Driven Full-Run Harness）

把「平衡評估」從**隨機 AI 出牌**換成**真實決策**：在一整個 run 的每個決策點，交由
AI agent（Claude）決定，遊戲用 headless 事件串口真的執行，玩完輸出 transcript + 結果，
再據此寫平衡報告。

> 為什麼：`smoke_test.gd` 的 `_simulate_random_battle` 隨機選 affordable 卡，
> 從不換人、不指定目標、不打 combo、不規劃牌組。它測的是「隨機手在時限下的表現」，
> 不是「會玩的人」。詳見 `docs/BALANCE_REPORT.md`。

## 組成

| 檔案 | 角色 |
|---|---|
| `scripts/ai_run_engine.gd` | `AiRunEngine`（RefCounted）。無 UI、同步狀態機的 run 引擎。重用真實底層系統（RunState / MapGenerator / **真實 BattleController** / EffectResolver / EventRunner / ShopInventory / 各 catalog）。`next_view()` 給決策點，`apply(choice)` 套用並推進。 |
| `tools/ai_run.gd` | `SceneTree` 包裝，把引擎接上**檔案協定**（互動模式）或內建 policy（auto 模式）。 |
| `scripts/smoke_test.gd::_test_ai_run_engine_smoke` | 防鏽測試：用內建啟發式 policy 同步跑完幾場、檢查抵達終局與 RunState 一致性。 |

**戰鬥 100% 用真實 `BattleController`**（平衡問題的核心，零失真）。地圖 / 獎勵 / 加護 / 休息 /
事件 / 商店重用純生成器，套用變更在引擎內鏡像 main.gd（只動 RunState；不碰 UI）。

> 既有 `smoke_test.gd` 的隨機 AI balance regression **保留不動**——它仍是 CI 的快速防回歸。
> 本驅動器是「我親自玩」的按需質性工具，不進 CI gating。

## 跑法

```bash
# 互動模式（我逐回合玩）：headless 即可，無需 rendering
godot --headless --path . -s tools/ai_run.gd

# 無人值守（內建啟發式 policy 自動跑完，僅供煙霧驗證；很粗淺、不代表會玩）
AIRUN_AUTO=1 godot --headless --path . -s tools/ai_run.gd
```

環境變數：

| 變數 | 預設 | 說明 |
|---|---|---|
| `AIRUN_PARTY` | `li_xiaoyao` | 逗號分隔角色 id，隊長在前（`li_xiaoyao,zhao_linger,lin_yueru`） |
| `AIRUN_ASC` | `0` | ascension 難度層級 |
| `AIRUN_SEED` | `0` | run seed，0=隨機 |
| `AIRUN_AUTO` | `0` | `1`=用內建 policy 自動跑完，不等檔案 |
| `AIRUN_AUTO_BATTLE` | `off` | 混合委派（見下）：`off`=每個戰鬥回合都問 agent；`normal`=自動打非 boss 戰、boss 戰交給 agent；`all`=自動打所有戰鬥、agent 只決定 meta |
| `AIRUN_SESSION` | （空） | 多開時的 session 名；空=用 repo 根 legacy 檔名，非空=用 `_ai_runs/<session>/` 隔離 |

## 混合委派（加速：少 round-trip）

一整個 8 幕 run ≈ 500 個決策點，其中**絕大多數是雜兵戰逐張出牌**——這些用內建啟發式 policy
就能打贏，不需要 agent 逐張思考。每個決策點都是一次 `Read view → 決策 → Write cmd` 的
round-trip，是互動模式最大的時間成本。

**混合委派**讓例行戰鬥交給啟發式自動打、只把需要 agent 智慧的 meta 決策（加護/路線/獎勵/
商店/事件/休息）與 boss 戰 surface 出來。實測一趟 zhao_linger run：引擎內部 498 步，
`AIRUN_AUTO_BATTLE=normal` 下 agent 只需處理 ~100 個決策點、`battle_turn` 僅 4 次（皆 boss）；
`all` 模式更只剩純 meta（map / reward / event…），雜兵戰一個都不 surface。

兩種觸發方式（可並用）：

1. **env 級**：`AIRUN_AUTO_BATTLE=normal`（甜蜜點，保留 boss 戰術交給 agent）或 `all`（最快）。
2. **agent 隨需**：在任一 `battle_turn` 寫 `choice: "auto"` → 該場戰鬥**剩餘回合**全部交給啟發式
   打完，下一個 view 直接跳到戰後（獎勵/地圖）。適合 agent 看一眼局面、判斷「這場穩贏」就一鍵帶過。

> 取捨：啟發式 policy 的戰術不如真人精算（尤其阿奴毒流這種 setup-payoff 牌組）。
> 要量測「會玩的人」的**戰鬥**真實上限時用 `off`（或只對關鍵戰用 agent、其餘 `auto`）；
> 要快速評估「**整個 run 的策略線**（牌組/路線/獎勵）」時用 `normal` / `all` 最划算。

## 檔案協定（互動模式）

**單開**（`AIRUN_SESSION` 為空，repo 根目錄）：

| 檔 | 寫入方 | 內容 |
|---|---|---|
| `_ai_view.json` | 驅動器 | `{ seq, kind, phase_label, run, state, options }` — 當前決策點 |
| `_ai_cmd.json` | 我（agent） | `{ seq, choice }` — 我的決策（`choice` 是給 `apply()` 的字串） |
| `_ai_result.json` | 驅動器 | run 結束的終局摘要 |
| `_ai_transcript.json` | 驅動器 | 逐事件紀錄 |

**多開**（設 `AIRUN_SESSION=<name>`）：上述四檔改放 `_ai_runs/<name>/{view,cmd,result,transcript}.json`，
各 session 互不干擾。`_ai_runs/` 已在 `.gitignore`。

**循環**：驅動器寫 `_ai_view.json`（seq=N）→ 我讀局面、寫 `_ai_cmd.json`（**seq 必須等於 N**）→
驅動器套用、推進、寫出新的 `_ai_view.json`（seq=N+1）。我每次寫完 cmd 後**重讀 `_ai_view.json`**
看 seq 是否前進來確認被消費。run 結束 → 寫 `_ai_result.json` + `_ai_transcript.json` 後 `quit()`。

> 讀 `_ai_view.json` 用 Read 工具（正確顯示中文）；不要用 Windows console `cat`（cp950 會變亂碼，但檔案本身是合法 UTF-8）。

### `kind` 與對應的 `choice` 字串

| kind | 局面（state） | choice 寫法 |
|---|---|---|
| `boon` | 起始加護選項 | boon id，或 `skip` |
| `map` | 當前列可前往的節點 | 節點 index（如 `2`） |
| `battle_turn` | energy / 手牌(含 cost·效果·需否目標·預覽) / 我方·敵方 HP·護體·狀態·intent·預測傷害；另帶 `is_boss` 旗標 | `play <手牌index> [敵index]`、`switch <隊伍index>`、`potion <藥格>`、`end`、`auto`（把這場剩餘回合委派給啟發式打完）|
| `reward` | 卡牌三選一 | 卡 index，或 `skip` |
| `boss_relic` | Boss 遺物三選一 | relic id，或 `skip` |
| `rest` | 調息 / 打磨 | `heal`，或 `upgrade <可升級index>` |
| `event` | 事件樹節點 prompt + 可見選項 | 選項 id（樹會自動往下走 / 結算 outcome） |
| `shop` | 卡/遺物/藥/服務 | `card <i>`、`relic <id>`、`potion <i>`、`remove`→`remove <deckidx>`、`upgrade`→`upgrade <i>`、`cancel`、`leave` |
| `done` | — | （終局，無需回應） |

每個 view 都帶 `run`（act / floor / gold / 全隊 HP / relics / potions / observe_tokens），給全局視野。

## 我（agent）怎麼玩

1. 啟動互動模式（背景）。
2. 用 Read 開 `_ai_view.json`，依 `kind` 與 `state` 做**真實策略決策**。
3. 用 Write 寫 `_ai_cmd.json`（帶相同 `seq`）。
4. 重讀 `_ai_view.json` 確認 seq 前進，回到 2。
5. 看到 `kind: done` 或 `_ai_result.json` 出現即結束；讀 transcript 寫報告。
6. 完事 `taskkill` godot、刪除 `_ai_*.json` 暫存（同 render-probe 清理慣例）。

## 多 agent 同時測試（平行掃多組組合）

要一次評估「不同角色 × 不同 seed × 不同難度」的矩陣時，平行開多個驅動器、每個由一個 subagent
親自玩，可大幅縮短牆鐘時間。每個驅動器用獨立 `AIRUN_SESSION`，協定檔自動隔離到 `_ai_runs/<session>/`。

**啟動 N 個背景驅動器**（各帶不同 session / party / seed）：

```bash
# 範例：4 角色各跑一場（同 seed 比角色，或不同 seed 比運氣）
AIRUN_SESSION=li  AIRUN_PARTY=li_xiaoyao  AIRUN_SEED=1001 godot --headless --path . -s tools/ai_run.gd   # 背景
AIRUN_SESSION=zl  AIRUN_PARTY=zhao_linger AIRUN_SEED=1001 godot --headless --path . -s tools/ai_run.gd   # 背景
AIRUN_SESSION=lyr AIRUN_PARTY=lin_yueru   AIRUN_SEED=1001 godot --headless --path . -s tools/ai_run.gd   # 背景
AIRUN_SESSION=anu AIRUN_PARTY=anu         AIRUN_SEED=1001 godot --headless --path . -s tools/ai_run.gd   # 背景
```

> Windows PowerShell：用 `$env:AIRUN_SESSION="li"; $env:AIRUN_PARTY="li_xiaoyao"; ...` 設好再呼叫，
> 或用 `Start-Job` 把每個程序丟到背景。多個 godot headless 程序彼此獨立，共用唯讀的 `.godot` import
> cache，互不干擾。

**派 subagent 各玩一個 session**：對每個 session 派一個 subagent，指令它「只讀 / 寫
`_ai_runs/<session>/view.json` ↔ `cmd.json`，依 `kind` 做真實策略決策，直到 `result.json` 出現」，
最後把該 session 的 `result.json` + `transcript.json` 摘要回報。主控彙整成平衡矩陣。

要點：
- 每個 subagent **只碰自己 session 的目錄**，避免互踩。
- seq 對齊邏輯不變（view seq=N → cmd seq=N → view seq=N+1），只是路徑換成 session 目錄。
- 全部跑完後刪 `_ai_runs/`（或各自 session 子目錄）清理。
- 想比「角色強弱」固定同一組 seed；想比「運氣區間」同角色掃多個 seed。配合不同聰明程度的
  subagent 指令，即可重現「聰明選擇＋運氣」的難度光譜（見 balance methodology 記憶）。

## 失真說明（drift caveats）

- **戰鬥**：零失真（真實 BattleController + EffectResolver + DeckManager）。
- **生成器**：重用（MapGenerator / ShopInventory / EventRunner / `_make_*` / gold 公式）。
- **套用邏輯**：在引擎內鏡像 main.gd UI handler 的 RunState 變更。已知簡化：
  商店未計入「詛咒加價」surcharge（視為 ×1.0）；藥品/卡牌掉落對話框簡化為直接給予。
  這些對平衡訊號影響極小；`_test_ai_run_engine_smoke` 守住引擎不爛。

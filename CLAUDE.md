# SwordCard — Architecture & Conventions

私人粉絲向原型：仙俠卡牌戰鬥，靈感來自仙劍奇俠傳 1（PAL1）。
第二靈感：《幽冥仙途》（減肥專家）——只取「幽/冥/血/魂/影/蝶」的命名語感，用於阿奴等鬼冥系卡牌風格（既有例：幽魂噬影、化蝶歸夢、逆影遁法、骨絡通心、血魔化心）；**不照搬**該書招式名，PAL1 正史永遠優先。

## 路由表（先查這裡，需要時才讀長文件）

| 你正要做的事 | 先讀 |
|---|---|
| 派 subagent、選 model | `docs/harness/DISPATCH.md` |
| 判斷「完成了沒」「該不該問使用者」「卡住了」 | `docs/harness/JUDGMENT.md` |
| 寫派工 prompt | `docs/harness/DELEGATION_TEMPLATES.md`（5 種模板直接抄） |
| 改 CLAUDE.md 或 `docs/harness/` 檔案 | `docs/harness/MAINTENANCE.md`（有紅線，先讀） |
| 在這個環境第一次跑 session | `docs/harness/LETTER.md` |
| 動組隊 / 藥品 / 多敵 / 戰鬥 UX 細節 | `docs/design/PARTY_MODE.md`、`POTIONS.md`、`MULTI_ENEMY.md`、`BATTLE_UX_SYSTEMS.md` |
| 新增卡 / 敵人 / 事件（先查正史） | `docs/PAL1_CANON.md` |
| 平衡調整 | `docs/BALANCE_REPORT.md` |
| AI 親玩整個 run 評平衡 | `docs/AI_BALANCE_HARNESS.md` |
| 遊戲開發全流程（規劃/QA/交接） | Skill `gamestudio` |

### 三條鐵律（歷史上燒掉最多 context 的三種方式，違反前先想清楚）

1. **不要整檔 Read `scripts/main.gd`**（12,000+ 行，整檔 ≈ 130k tokens）。先 Grep 函式名拿行號，再 Read offset/limit 只讀那一段。`scripts/smoke_test.gd`（4,500+ 行）同理。
2. **長輸出一律導檔**：smoke test、模擬、任何預期超過 50 行輸出的指令都 `... > _out.txt 2>&1`，再 Grep 關鍵字或 Read 檔尾。看完刪暫存檔（`_*.txt`、`_*.png` 及其 `.import`）。
3. **大量讀取型工作派 subagent**：掃 repo、查網頁、讀 3 個檔以上才能回答的問題、批次改 5 檔以上 → 照 `docs/harness/DISPATCH.md` 派工，主對話只進結論與 檔案:行號。

## 設計支柱（Design Pillars）

新功能 / 內容 / 平衡調整前先問：**「踩哪根支柱？」** 不踩任何支柱、或違背某根支柱的東西，預設不做（範圍擴散的剎車）。三根支柱優先序由上而下：

1. **仙劍正史的「再體驗」，不是換皮 roguelike。** PAL1 canon 是對 StS 的差異化護城河。卡牌 / 敵人 / 接續（如隱龍窟蛇妖死召狐妖）要忠於正史；長期目標是讓**地圖與 run 結構也承載「餘杭→蘇州→苗疆」的旅程感**，而非只是匿名節點。違反例：為機制而加的無正史依據敵人 / 卡。

2. **四角色 = 四種解法，而非四種強度。** 李逍遙=連擊速攻、趙靈兒=debuff late-bloomer、林月如=續航反擊、阿奴=毒流引擎——**每種節奏都該有自己最強與最弱的場景**。當「選角」變成「選對就贏」這根支柱就斷了。調平衡時優先收斂 spread、給每角一個剋星場景，而非齊頭拉強度（現況數字見 `docs/BALANCE_REPORT.md`）。

3. **每個決策都該有代價（roguelite 的稀缺契約）。** 出牌、選點、買東西、切人都該是取捨；「躺著全買 / 免費勝利」就是支柱破裂。現況裂縫：幕 3 起經濟通膨、組隊 duo 勝率仍過高（見 `docs/BALANCE_REPORT.md` §六、§九）。

> 製作人級決策（`webgame/` demo-or-主線、組隊是否真調平衡）用支柱裁決：踩不到支柱 1–3 的，要嘛明確劃為「opt-in 變化模式（明說不平衡）」，要嘛凍結，不靠產能硬推。

## 內容創作原則

**優先使用 PAL1 原有素材，不足時才自創；自創需與仙俠風格一致。**

| 類別 | PAL1 可參考的素材 |
|---|---|
| 角色 / 招式 | 李逍遙（御劍術、劍法）、趙靈兒（靈族神術）、林月如（劍術、刀術）、阿奴（**苗疆巫術**：蠱術、驅鬼、攝魂、巫醫——蠱毒只是其一，勿把她做成純毒師）|
| 敵人 / 頭目 | 山賊、各地妖魔鬼怪、中Boss（蜈蚣大王、毒蛇、殭屍）、最終Boss |
| 地圖 / 地名 | 餘杭、蘇州、苗疆、南詔、鎖妖塔、林家堡、拜月教壇 |
| 劇情事件 | PAL1 劇情中的關鍵場景、支線任務、奇遇地點 |
| 遺物 / 道具 | PAL1 中的道具、法寶、符咒 |

新增內容前先查 **`docs/PAL1_CANON.md`**（角色出身/武器、NPC、地點、Boss、法寶、名場面、SwordCard 取用對照）。

## Tech Stack

- **Godot 4.6**（mobile renderer, ETC2/ASTC textures）
- **GDScript**（typed）。沒有 C# / GDExtension。
- **Target**: Windows desktop + Android phone。強制橫向。
- **CI**: GitHub Actions, `barichello/godot-ci:4.6` container。每次 push 自動跑 smoke test，失敗阻擋 APK / Web build（見 `.github/workflows/`）。CI 另有 ERROR tripwire：log 出現任何 `ERROR:` 行就 fail，本地 smoke「passed」不代表 CI 會過。

## Run / Test

```bash
# 啟動編輯器
godot --path .

# 跑全部 smoke tests (~3 秒)；輸出導檔看檔尾（見鐵律 2 與地雷「assert 假卡死」）
godot --headless --path . -s scripts/smoke_test.gd > _smoke_out.txt 2>&1

# Headless boot 檢查所有腳本 parse
godot --headless --path . --quit

# 加新 class_name 後要重新 import 才會註冊到 global（只有這時才需要）
godot --headless --path . --import
```

成功判準：`_smoke_out.txt` 檔尾出現 `SwordCard smoke test passed.`、exit code 0、**且全檔無 `ERROR:` 行**（CI tripwire 會擋，本地先自查：`grep "ERROR:" _smoke_out.txt`）。

### 實機渲染截圖（驗證 UI / 動畫）

改動 UI 或出牌特效動畫後，**必須用實機渲染截圖肉眼確認**（純推理看不出大小 / 位置 / 時機）。
專案根目錄兩支 `SceneTree` 工具，pattern：開真場景 → 跑幾幀 → `save_png()`：

- **`render_effects.gd`** — 出牌動畫截圖。改頂部 `SHOTS`（每筆 `[card_id, frame, label]`，frame≈秒數×60）與 `ENEMY_IDS`。內建 `CARD_ANIM` 表把 card_id 對到 `_animate_*`（新增動畫時補這表）。
- **`render_battle_ui.gd`** / **`render_event.gd`** / **`render_battle_backgrounds.gd`** — 戰鬥 UI / 奇遇畫面 / 戰鬥背景截圖。pattern 相同（`start_run` → 灌狀態 → 開某 screen）；改哪類畫面就用哪支，都不合用就仿照現有的加一支。

```bash
godot --headless --path . --import        # 只有特效/卡圖剛新增、沒匯入過才需要
# 務必 windowed，不要 --headless（headless 無 rendering，截圖全黑）
godot --path . -s render_effects.gd       # 輸出 res://_<label>.png
```

截圖用 Read 工具開圖檢視；**看完刪暫存 PNG（`_*.png` 及其 `.import`）**。

### AI 平衡驅動器（agent 親自玩一整個 run）

評估「會玩的人」整個 run 的真實平衡用 **`tools/ai_run.gd`**：headless 跑整個 run，每個決策點透過檔案協定（`_ai_view.json` ↔ `_ai_cmd.json`）交給 agent 決定，戰鬥用真實 BattleController。引擎在 `scripts/ai_run_engine.gd`。

```bash
godot --headless --path . -s tools/ai_run.gd               # 互動：agent 逐回合玩
AIRUN_AUTO=1 godot --headless --path . -s tools/ai_run.gd  # 內建粗淺 policy（僅煙霧驗證）
```

完整協定見 `docs/AI_BALANCE_HARNESS.md`。玩完刪 `_ai_*.json` 暫存。

## Project Layout

```
scenes/main.tscn         入口場景（極簡，主要邏輯在 scripts/main.gd）
scripts/
  main.gd                主控制器，所有 screen 都在這裡建構（~12,300 行——god object，待抽 screen 控制器；讀取見鐵律 1）
  ui_factory.gd          純 UI 工廠 (style_box, hp_bar, card_label, ...)
  theme_colors.gd        13 個 semantic 色常數
  card_format.gd         卡片/敵人 action 純格式化（顏色、名稱、intent badge、傷害預測）
  damage_popup.gd        戰鬥中浮動傷害/治療/格擋數字
  bestiary.gd            跨 run 持久化的敵將擊敗紀錄（user://bestiary.cfg）
  ascension.gd           難度層級 A0-A20（對齊 StS），cumulative modifiers（user://progression.cfg）
  debug_menu.gd          F1 開發者選單（CanvasLayer，桌面限定）
  pause_menu.gd          暫停選單（CanvasLayer）
  hand_fan.gd            手牌扇形排列
  battle_controller.gd   戰鬥流程（回合、出牌、敵人動作、多敵、召喚、party sync）
  effect_resolver.gd     卡片/敵人 effect → state mutation
  deck_manager.gd        抽牌堆/棄牌堆/手牌
  run_state.gd           跨節點的 run 狀態（角色、HP、deck、relics、地圖、藥品）
  save_manager.gd        user://savegame.json 讀寫 + 版本/損毀處理
  settings_manager.gd    音量、全螢幕（手機平台略過）
  map_generator.gd       隨機地圖（9-11 層 + boss）+ ACT_ENCOUNTERS 遭遇表
  map_link_layer.gd      地圖連線渲染
  map_node_icon.gd       地圖節點圖示
  relic_icon.gd          遺物圖示 + 觸控彈出說明
  relic_catalog.gd       56 件遺物資料
  potion_catalog.gd      37 種藥品資料（single source）
  game_data.gd           角色 / 敵人 / 卡片資料
  event_data.gd          奇遇節點資料
  smoke_test.gd          所有測試（SceneTree-based，讀取見鐵律 1）
  data/                  CharacterData / CardData / EnemyData / RelicData
assets/
  art/                   背景、肖像、卡圖（規範見 assets/art/ART_GUIDE.md）
  ui/                    地圖節點圖示、詩句
  fonts/
```

## Key Conventions

### UI 建構

**全部用程式碼建構**，沒用 .tscn 場景檔（除了 main.tscn 入口）。三個 helper 模組分工：

- **`UIFactory`**：建構性的純 helper（傳入參數、回傳 Control / StyleBox / 動畫）
- **`ThemeColors`**：13 個 semantic 色常數
- **`CardFormat`**：卡片 / 敵人 action 的格式化與分類（純函式）

```gdscript
# UIFactory
var panel = UIFactory.make_panel()
var button = UIFactory.main_menu_button("開始", true)
var label = UIFactory.card_label("HP", 14, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
var bar = UIFactory.hp_bar(ThemeColors.HP_FILL, ThemeColors.HP_BG_DARK)
var tex = UIFactory.load_texture(path)         # 有 cache

# CardFormat
var pred = CardFormat.predict_enemy_damage(action, battle.state) # {raw, blocked, dealt}
var needs_enemy = CardFormat.requires_enemy_target(card)         # drag-to-play 用
# 另有 card_type_name / card_color / card_rarity_color / intent_badge / enemy_action_effect_summary

# DamagePopup：DamagePopup.spawn(self, pos, 15, "damage")，type 有 "damage"/"heal"/"block"
```

**同步地雷**：`CardFormat.predict_enemy_damage` 跟 `EffectResolver` 的 from-enemy damage 路徑是**兩份要同步的實作**，smoke test 用 9 組 (block, vuln, weak, attack) 組合驗證一致。改 damage 計算時兩邊一起改，漏了 smoke test 會抓出來。

新增 helper 的規則：**沒碰 self state 的就抽出去**（純函式優先）。
只有 `main.gd` 裡留兩個 wrapper：`_title()` 跟 `_button()`（與其他 identifier 子字串衝突，不適合 replace_all 拆走）。

### 色彩

13 個常用色集中在 `ThemeColors`：`ACCENT_GOLD`/`BORDER_GOLD`/`HIGHLIGHT_GOLD`（金色品牌）、`TEXT_LIGHT`/`TEXT_DIM`/`TEXT_MUTED`（文字）、`PANEL_BG`/`PANEL_NAVY`/`PANEL_NAVY_HOV`/`PANEL_NAVY_PRS`（面板/按鈕）、`OVERLAY_BG`（popup 底）、`HP_FILL`/`HP_BG_DARK`（血條）。
帶 alpha 的 tint（`Color("c8b46f", 0.38)`）保持 inline——是 per-callsite 透明度選擇，不是 semantic 色。

### Mobile (Android) 特殊處理

- 暫停由 `_toggle_pause_menu()` 處理，Esc + 螢幕暫停按鈕 + Android 返回鍵三條路徑都會通
- 返回鍵走 `NOTIFICATION_WM_GO_BACK_REQUEST`，**不要**只監聽 KEY_ESCAPE
- Safe area 由 `_apply_safe_area_margins()` 套用到 root MarginContainer + pause button 位置
- App 切背景時（`NOTIFICATION_APPLICATION_PAUSED` / `WM_WINDOW_FOCUS_OUT`）自動 save
- **不要**在執行階段呼叫 `DisplayServer.window_set_mode(FULLSCREEN)`——會把 Android immersive mode 打回視窗模式（`SettingsManager.apply_runtime()` 已用 `OS.has_feature("mobile")` 擋掉）
- Tooltip 在觸控設備無法顯示——遺物說明改用 `PopupPanel`（見 `relic_icon.gd`）
- 卡片 hover 同時連 `mouse_entered/exited`（桌面）和 `button_down/up`（觸控）

### 存檔

- `user://savegame.json` 是 atomic write（先寫 `.tmp` 再 rename）；解析失敗會備份壞檔到 `user://savegame.corrupt.json`
- `save_version` 寫在檔內，`load_save()` 自動走 `SaveManager.migrate()` 升級
- `RunState.to_dict()` / `from_dict()` 是 single source of truth，**新欄位兩邊都要加**
- 純加新欄位不用升版本，`from_dict` 用 `data.get(key, default)` 回退即可

**升 SAVE_VERSION 的流程**（只在破壞性結構改動時：改欄位名/型別、移除欄位）：
1. `SaveManager.SAVE_VERSION += 1`
2. `migrate()` 的 match 加新 case（舊版號 → 新版號的欄位轉換；舊 keys 留著不刪）
3. `migrate()` 的 while 迴圈會自動把 v0 → v1 → v2 串起來
4. `RunState.from_dict()` 只處理新版欄位
5. smoke test 加 migration 測試（參考 `_test_save_migration`）

### 戰鬥輸入體驗與周邊系統（摘要）

細節（旗標名、觸發時序、Ascension modifier 接線圖）→ **`docs/design/BATTLE_UX_SYSTEMS.md`**。改這些系統前先讀該檔對應段落：

- End Turn 二段確認（1 秒內再按=立即結束；打卡自動取消警告）
- 出牌：桌面點兩下或拖拉；**手機只能拖拉**；長按 0.5s=預覽不出牌（`_suppress_next_card_play` 旗標）
- 拖拉判定：`CARD_DRAG_THRESHOLD = 14px`；`CardFormat.requires_enemy_target()` 決定是否要拖到敵人
- 戰敗 retry（滿血扣 1 遺物）；戰鬥中遺物清單 popup；路線總覽 popup
- 敵將圖鑑（`user://bestiary.cfg`，獨立於存檔）
- Ascension A0–A20（cumulative，對齊 StS；改 modifier 數值記得同步 `Ascension.describe()`）
- Boss phase 2（HP<50% 換招式組）與 Boss 接續 `successor`（蛇妖死召狐妖）——**兩者互斥**
- 種子分享 / 每日挑戰（`RunState.map_seed`；同 seed 地圖 deterministic）

### Debug menu（桌面開發用）

**F1** 切換，只在 `!OS.has_feature("mobile")` 建構、run 進行中可開。快捷：+100 Gold / Full Heal（戰鬥中會同步 `battle.state["player_hp"]` 並 `_refresh_battle()`）/ Add Random Card / Add Random Relic / Give Random Potion / Spawn Test Minion / Jump to Boss（只跳 encounter_index，仍要手動點 boss 開戰）。每個動作 `print("[DEBUG] ...")`。
加新動作：`debug_menu.gd` 加 signal + `_build()` 連按鈕；`main.gd` 加 `_dbg_*()` handler 並在 `_build_debug_menu()` connect。

### 戰鬥資料流

```
main.gd
  ├─ run_state: RunState          # 整個 run 的進度
  └─ start_next_battle(enemy)
       └─ BattleController.setup(run_state, character, enemy)
            ├─ state: Dictionary  # 戰鬥內 mutable state
            ├─ deck: DeckManager  # 抽/棄/手
            └─ resolver: EffectResolver  # 純 dict mutation
```

- `state` 是 plain Dictionary，鍵名固定（見 `BattleController.setup()`）
- 卡片 effect 都是 `{"kind": "damage", "amount": 10}` 形式，`EffectResolver._resolve_effect()` 中央 switch
- 狀態衰減（poison/weak/vulnerable）在 `BattleController.start_turn()` 跟 `begin_enemy_phase()`，不在 resolver
- **兩套 alias 同步模式**（改戰鬥欄位最容易漏的地方）：`state["player_*"]` 是 active 隊員的 alias（`_sync_state_to_active` / `_sync_active_to_state`）；`state["enemy_*"]` 是 active 敵人的 alias（`_sync_state_to_active_enemy` / `_sync_active_enemy_to_state`）。加新戰鬥欄位時檢查這四個函式要不要跟著加。

## 測試

`scripts/smoke_test.gd` 是 SceneTree-based，覆蓋：資料完整性、戰鬥機制、save round-trip 與 migration、地圖生成、傷害預測一致性、Party（6 測）、藥品（5 測）、多敵/召喚（13 測）、Bestiary、Ascension、Boss phase、事件、seed determinism、平衡 regression（`BattlePolicy` 啟發式出牌，deterministic）。

- 新增測試：`_initialize()` 加 `_test_xxx()` 呼叫 + 實作該函式
- **`_test_*` 內用 `_check(cond, msg)`，不要用 `assert()`**（原因見地雷清單）
- 成功判準：print `"SwordCard smoke test passed."` 且 exit 0，CI 用 grep 該字串判定

### 平衡 regression 失敗時怎麼處理

`_test_balance_regression()` 用起始牌組 + `BattlePolicy` 跑 30 場固定 seed 模擬。基準 `BALANCE_BASELINES` 寫死在 smoke_test.gd 頂部，容差 `BALANCE_TOLERANCE_PP = 15` 百分點。fail 時先分類：

1. **意外 regression**（沒故意改平衡）→ 回頭查是哪個改動害的；多半是 EffectResolver off-by-one 或 BattleController 狀態順序改了
2. **故意的平衡調整** → 重跑看實際勝率 → 新觀測值寫進 `BALANCE_BASELINES` → commit message 寫清楚「故意調整：X 從 100% → 80%，因為...」
3. **整套機制大改** → 暫時把該角色從 `BALANCE_BASELINES` 移掉（印觀測值不 assert）→ 穩定後補回

容差 15pp 是 30 場樣本的雜訊空間，不是「小調整」的緩衝；調整若在容差內就是無關緊要的改動，不用更新 baseline。

## 常見地雷

- **不要在指令前綴 `cd` / `Set-Location`**：工作目錄已是專案根目錄。複合指令帶 `cd <path>; ...` 會觸發 Claude Code 的 path-resolution-bypass 安全檔板、強制人工核准（任何權限模式都關不掉）。直接用相對路徑跑
- **不要用 inline heredoc 寫含大括號的 JSON**：`cat > x.json << 'EOF' {"..."} EOF` 會觸發 expansion-obfuscation 安全檔板、強制人工核准。寫 JSON 檔改用 **Write 工具**，或 `python -c "import json; json.dump(obj, open('x.json','w'))"`
- **加新 `class_name` 後報「identifier not declared」**：跑一次 `godot --headless --path . --import` 重建 global class cache
- **跑 smoke test 不要鏈 `--import`**：`-s scripts/smoke_test.gd` 直接跑。只有「新增 `class_name`」才需要先 `--import`。鏈 `--import && smoke` 曾在背景管線下 hang 20 分鐘（import 卡住、後續搶 import lock）
- **smoke test 的 assert 失敗 = 看起來像「卡死」**：assert 失敗會中途 abort `_initialize`、來不及 `quit(0)`，SceneTree 空轉；再用 `| tail` 管線錯誤訊息會被 buffer 蓋掉。**輸出導檔**（`> _out.txt 2>&1`）就能看到 `SCRIPT ERROR: Assertion failed. at: ...`。已加 watchdog（abort 後 5 秒 `quit(1)`）
- **`_test_*` 函式用 `_check(cond, msg)` 不要用 `assert()`**：assert 在 `_test_*` 內失敗只 abort 該 func、不 abort `_initialize`，「passed」照印、exit=0 騙人。`_check` 累計 `_smoke_failures`，結尾 >0 則 `quit(1)`。`_initialize` 頂層的資料完整性檢查仍用 `assert()`（失敗就該 abort，watchdog 接手）
- **新增卡牌必須有美術**：smoke test assert 每張獎勵卡 `art_path` 存在。新卡要嘛放 `assets/art/cards/<id>.png`，要嘛 `make_card(..., art_id="既有卡id")` 借圖，否則直接 abort（→ 假卡死）
- **.import 檔不要 .gitignore**：CI 首次匯入找不到配置、build 掛掉。`.gitattributes` 已規範換行，不要手動覆蓋
- **不要把 `assert()` 用在正式邏輯**：release build 會剝掉，副作用丟失
- **不要在 `_clear_root()` 後立刻存取舊 UI 變數**：`queue_free()` 延遲釋放但變數已 dangling，下一行重建就好

## 已完成功能（摘要＋指路；動它們之前先讀對應設計檔）

### Party Mode → `docs/design/PARTY_MODE.md`
- 主備制：active 1 人 + 後排 0–2 人，最多 3 人；每角色**獨立 deck**；死者留備位可救
- 數值：Energy `3+(n-1)/2`；敵 HP 每多 1 隊員 ×1.85（`PARTY_ENEMY_HP_STEP=0.85`）；後排每回合 +1 HP；每回合免費切 1 次、再切 1 energy、切入者 +2 護體
- 存檔 SAVE_VERSION=2（v1→v2 migration 已寫）；`characters[0]` 是隊長

### 藥品系統 → `docs/design/POTIONS.md`
- 37 種藥，single source = `scripts/potion_catalog.gd`，**smoke test 鎖死數量==37**（加藥要同步改測試與設計檔清單）
- 3 藥格；戰鬥中點擊使用（`_use_potion` → `resolver.resolve_effects_list`）；商店 2 瓶（`ShopInventory.build_potions`）；戰後掉落一般 20% / boss 60%；存檔不升版

### 多敵人系統 → `docs/design/MULTI_ENEMY.md`
- 1–3 敵同場；AOE 用 effect kind `damage_all`/`poison_all`/`weak_all`/`vulnerable_all`
- 召喚：`summon` kind + `EnemyData.summon_pool` + `spawn_enemy()`（上限 3、召喚物無 loot、`is_summoned` 旗標）
- 遭遇組：`MapGenerator.ACT_ENCOUNTERS` 加權表 + `choose_enemies_for_act(act, pool)`

## 美術資源狀況

- 敵人肖像：原 5 隻 placeholder（`flower_spirit`/`red_eye_imp`/`zombie_thrall`/`centipede_brood`/`tower_wisp`）已於 2026-06-30 補上獨立專屬圖（`assets/art/enemies/<id>.png`）；重繪風格參考見 `docs/ENEMY_ART_PROMPTS.md`
- 卡圖 `_ls` 後綴（`lxy_jinchan_ls` 等 4 張）是「傳說光效版」插圖，對應 rare 強化卡，已作為獨立 card ID 使用，無需 `art_id`
- 美術規範與管線見 `assets/art/ART_GUIDE.md`

## Git Workflow

- main branch 直接 push，沒有 PR review 流程（個人專案）
- commit message 用 conventional commits：`fix(scope):`、`refactor:`、`test:`、`chore:`、`ci:`
- **session 開場先 `git status --short`**：使用者常開並行 session 跑美術管線，工作樹常有別人的未 commit 改動——不要動不是你改的檔案，絕不對未 commit 檔案跑 `git checkout --` / `reset --hard`
- 完成一個邏輯單位就建議使用者 commit（防並行 session 撞車）

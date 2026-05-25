# SwordCard — Architecture & Conventions

私人粉絲向原型：仙俠卡牌戰鬥，靈感來自仙劍奇俠傳系列。

## 內容創作原則

**優先使用仙劍奇俠傳 1（PAL1）的原有素材，不足時才自創。**

在新增下列內容時，請先對照仙劍奇俠傳 1 的設定：

| 類別 | PAL1 可參考的素材 |
|---|---|
| 角色 / 招式 | 李逍遙（御劍術、劍法）、趙靈兒（靈族神術）、林月如（劍術、刀術）、阿奴（蠱術、毒術）|
| 敵人 / 頭目 | 山賊、各地妖魔鬼怪、中Boss（蜈蚣大王、毒蛇、殭屍）、最終Boss |
| 地圖 / 地名 | 餘杭、蘇州、苗疆、南詔、鎖妖塔、靈劍山莊、拜月教壇 |
| 劇情事件 | PAL1 劇情中的關鍵場景、支線任務、奇遇地點 |
| 遺物 / 道具 | 仙劍奇俠傳 1 中的道具、法寶、符咒 |

自創內容只在 PAL1 原有資料庫無法滿足需求時使用，並應與仙俠風格一致。

## Tech Stack

- **Godot 4.6** (mobile renderer, ETC2/ASTC textures)
- **GDScript** (typed). 沒有 C# / GDExtension。
- **Target**: Windows desktop + Android phone. 強制橫向。
- **CI**: GitHub Actions, `barichello/godot-ci:4.6` container

## Run / Test

```bash
# 啟動編輯器
godot --path .

# 跑全部 smoke tests (~3 秒)
godot --headless --path . -s scripts/smoke_test.gd

# Headless boot 檢查所有腳本 parse
godot --headless --path . --quit

# 加新 class_name 後要重新 import 才會註冊到 global
godot --headless --path . --import
```

CI 會在每次 push 自動跑 smoke test，失敗就阻擋 APK / EXE build（見 `.github/workflows/`）。

## Project Layout

```
scenes/main.tscn         入口場景（極簡，主要邏輯在 scripts/main.gd）
scripts/
  main.gd                主控制器，所有 screen 都在這裡建構（~2000 行）
  ui_factory.gd          純 UI 工廠 (style_box, hp_bar, card_label, ...)
  theme_colors.gd        13 個 semantic 色常數
  card_format.gd         卡片/敵人 action 純格式化（顏色、名稱、intent badge、傷害預測）
  damage_popup.gd        戰鬥中浮動傷害/治療/格擋數字（Label，self-managed tween）
  bestiary.gd            跨 run 持久化的敵將擊敗紀錄（user://bestiary.cfg）
  ascension.gd           難度層級 A0-A4，cumulative modifiers + 解鎖紀錄（user://progression.cfg）
  debug_menu.gd          F1 開的開發者選單（CanvasLayer，桌面限定）
  pause_menu.gd          暫停選單（CanvasLayer）
  hand_fan.gd            手牌扇形排列
  battle_controller.gd   戰鬥流程（回合、出牌、敵人動作）
  effect_resolver.gd     卡片/敵人 effect → state mutation
  deck_manager.gd        抽牌堆/棄牌堆/手牌
  run_state.gd           跨節點的 run 狀態（角色、HP、deck、relics、地圖）
  save_manager.gd        user://savegame.json 讀寫 + 版本/損毀處理
  settings_manager.gd    音量、全螢幕（手機平台略過）
  map_generator.gd       隨機地圖（9-11 層 + boss）
  map_link_layer.gd      地圖連線渲染
  map_node_icon.gd       地圖節點圖示
  relic_icon.gd          遺物圖示 + 觸控彈出說明
  relic_catalog.gd       56 件遺物資料
  game_data.gd           角色 / 敵人 / 卡片資料
  event_data.gd          奇遇節點資料
  smoke_test.gd          所有測試（SceneTree-based）
  data/                  CharacterData / CardData / EnemyData / RelicData
assets/
  art/                   背景、肖像
  ui/                    地圖節點圖示、詩句
  fonts/
```

## Key Conventions

### UI 建構

**全部用程式碼建構**，沒用 .tscn 場景檔（除了 main.tscn 入口）。三個 helper 模組分工：

- **`UIFactory`**：建構性的純 helper（傳入參數、回傳 Control / StyleBox / 動畫）
- **`ThemeColors`**：13 個 semantic 色常數
- **`CardFormat`**：卡片 / 敵人 action 的格式化與分類（純函式、給定 data 算出顯示用的字串和顏色）

```gdscript
# UIFactory
var panel = UIFactory.make_panel()
var button = UIFactory.main_menu_button("開始", true)
var label = UIFactory.card_label("HP", 14, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
var bar = UIFactory.hp_bar(ThemeColors.HP_FILL, ThemeColors.HP_BG_DARK)
UIFactory.shake_node(node, 8.0, 0.25)
var tex = UIFactory.load_texture(path)         # 有 cache

# CardFormat
var name_text = CardFormat.card_type_name(card.card_type)        # "攻擊" / "技能" / "能力"
var card_bg = CardFormat.card_color(card.card_type, affordable)  # 灰/紅/綠/紫
var border = CardFormat.card_rarity_color(card)                  # 升級金 / rare 紫 / uncommon 青 / common 灰
var badge_text = CardFormat.intent_badge(enemy_action)           # "[攻擊] [防守]"
var summary = CardFormat.enemy_action_effect_summary(action)     # "傷害 9 / 蠱毒 +2"
var pred = CardFormat.predict_enemy_damage(action, battle.state) # {raw, blocked, dealt}
var needs_enemy = CardFormat.requires_enemy_target(card)         # drag-to-play 用

# DamagePopup（戰鬥內浮動數字）
DamagePopup.spawn(self, target.global_position, 15, "damage")    # 紅 -15 飄升
DamagePopup.spawn(self, target.global_position, 8, "heal")       # 綠 +8
DamagePopup.spawn(self, target.global_position, 12, "block")     # 藍 +12
```

`CardFormat.predict_enemy_damage` 跟 `EffectResolver` 的 from-enemy damage 路徑同步，
smoke test 用 9 組 (block, vuln, weak, attack) 組合驗證兩者一致。改 damage 計算邏輯
時要兩邊一起改、smoke test 會把不一致抓出來。

新增 helper 的規則：**沒碰 self state 的就抽出去**（純函式優先）。

**只有 `main.gd` 裡留兩個 wrapper**：`_title()` 跟 `_button()`，因為 `_title(` / `_button(` 跟其他 identifier 子字串衝突，不適合 replace_all 拆走。

### 色彩

13 個常用色集中在 `ThemeColors`：
- `ACCENT_GOLD` / `BORDER_GOLD` / `HIGHLIGHT_GOLD`：金色品牌
- `TEXT_LIGHT` / `TEXT_DIM` / `TEXT_MUTED`：文字
- `PANEL_BG` / `PANEL_NAVY` / `PANEL_NAVY_HOV` / `PANEL_NAVY_PRS`：面板/按鈕
- `OVERLAY_BG`：暫停 / popup 底色
- `HP_FILL` / `HP_BG_DARK`：血量條

帶 alpha 的 tint（`Color("c8b46f", 0.38)`）保持 inline——它們是 per-callsite 透明度選擇，不是 semantic 色。

### Mobile (Android) 特殊處理

- 暫停由 `_toggle_pause_menu()` 處理，Esc + 螢幕暫停按鈕 + Android 返回鍵三條路徑都會通
- 返回鍵走 `NOTIFICATION_WM_GO_BACK_REQUEST`，**不要**只監聽 KEY_ESCAPE
- Safe area 由 `_apply_safe_area_margins()` 套用到 root MarginContainer + pause button 位置
- App 切到背景時 (`NOTIFICATION_APPLICATION_PAUSED` / `WM_WINDOW_FOCUS_OUT`) 會自動 save
- **不要**在執行階段呼叫 `DisplayServer.window_set_mode(FULLSCREEN)`，會把 Android 的 immersive mode 打回視窗模式（`SettingsManager.apply_runtime()` 已用 `OS.has_feature("mobile")` 擋掉）
- Tooltip 在觸控設備無法顯示——遺物說明改用 `PopupPanel`（見 `relic_icon.gd`）
- 卡片 hover 同時連 `mouse_entered/exited`（桌面）和 `button_down/up`（觸控）

### 存檔

- `user://savegame.json` 是 atomic write（先寫 `.tmp` 再 rename）
- 載入時 JSON 解析失敗會把壞檔備份到 `user://savegame.corrupt.json`
- `save_version` 寫在檔案內、`load_save()` 自動走 `SaveManager.migrate()` 升級
- `RunState.to_dict()` / `from_dict()` 是 single source of truth，新欄位記得兩邊都加

#### 升 SAVE_VERSION 的流程

當你做了破壞性的 RunState 結構改動（改欄位名、改型別、移除欄位），照這步驟：

1. `SaveManager.SAVE_VERSION += 1`（例如 1 → 2）
2. 在 `migrate()` 的 match 加新 case：
   ```gdscript
   match version:
       0:
           pass  # legacy → v1，欄位結構相同
       1:
           # v1 → v2: 把舊欄位 foo 改名成 bar
           if data.has("foo"):
               data["bar"] = data["foo"]
               data.erase("foo")
   ```
3. `migrate()` 的 while 迴圈會自動把 v0 → v1 → v2 串起來
4. `RunState.from_dict()` 只需處理新版欄位，不用看舊欄位（migrate 已處理）

不改結構但加新欄位（純加）通常不用升版本，`from_dict` 用 `data.get(key, default)` 就好。

### 戰鬥輸入體驗

- **End Turn 確認**：按下「結束回合」時若還有靈力且手上有可打的卡，按鈕文字變成「再按確認 / 剩 X 點靈力」並 flash 黃光。
  1 秒內再按一次 → 立即結束；過 1 秒 → 自動結束。
  期間若打了任一張卡 → 警告自動取消（`_cancel_end_turn_warning`，由 `play_card` 觸發）
- **長按卡片預覽**：在手牌卡片上按住 0.5 秒，跳出滿版 overlay 並排展示「當前卡（260×360）」與「升級後預覽」。
  按住期間鬆開即關閉、且**不會觸發出牌**（`_suppress_next_card_play` 旗標在 `_on_card_button_pressed` 攔截）
- **卡片打出方式**：
  - **點兩下打出（僅桌面）**：第一下選取（`set_selected_button` 抬起、`_selected_hand_card` 記下），第二下確認 `play_card`。
    行動裝置（`OS.has_feature("mobile")`）`_on_card_button_pressed` 直接 return，不允許點擊出牌。
  - **拖拉打出（桌面 + 手機皆支援）**：按下後移動超過 `CARD_DRAG_THRESHOLD = 14 px` 進入 drag mode，卡片跟著手指/游標跑。
    `CardFormat.requires_enemy_target(card)` 為 `true`（damage / poison / weak / vulnerable / consume_energy / poison_burst）
    要拖到敵人 portrait 附近（grow 80 px 的 hit box）才算命中；其他自身卡（block / heal / draw / energy / power）
    只要拖出手牌區才算打出。drop 期間 enemy/player portrait 會 modulate 高亮提示。
    drop 無效 → `hand_row.relayout()` snap back。drop 後 `_suppress_next_card_play` 攔截後續 `pressed` 訊號避免雙重觸發
  - **長按預覽**（見上）：純檢視，鬆開不出牌
- **戰敗 retry**：`show_result(false)` 不再立刻 `SaveManager.clear()`，而是多一顆「重打這一場（滿血，扣 1 件遺物）」按鈕。
  其他三顆按鈕（重新角色 / 重選角色 / 主選單）的 callback 才各自 clear save
- **戰鬥中遺物清單**：left_dock 多一顆「遺物 (N)」按鈕，點開 PopupPanel 顯示所有遺物名稱 + 描述（按稀有度上色）。
  popup 內的 icon `mouse_filter = IGNORE`，避免再觸發 RelicIcon 自己的單張 popup
- **路線總覽**：`show_progress_screen` 的「路線總覽」按鈕開 popup，列出全部層數的節點 badge 字串
  （`★` 當前 / `✓` 已過 / `·` 待選），顏色依狀態漸層
- **敵將圖鑑**：主選單「敵將圖鑑」按鈕進入 `show_bestiary()`。9 個敵將（6 一般 + 3 boss）3 欄 grid。
  未擊敗顯示黑色 silhouette + `???` + `尚未交手`；擊敗後顯示肖像、名字、HP、擊敗次數、所有 intent。
  資料寫在 `user://bestiary.cfg`（獨立於 savegame，abandon run 不會清掉）；`_complete_battle_victory` 呼叫 `Bestiary.mark_defeated(enemy.id)`
- **難度層級 (Ascension)**：主選單「開始遊戲」按鈕下方有 `◀ 難度: A0 ▶` picker，描述當前層級會 buff/nerf 什麼。
  5 級 cumulative（A0 標準 → A1 一般 HP +20% → A2 加 boss HP +20% → A3 加 起始 HP -15% → A4 加 銅錢 -25%）。
  完成 A_N 的 run 後 `Ascension.mark_cleared(N)` 解鎖 A_(N+1)。Run 中的層級存在 `RunState.ascension_level`，
  舊存檔自動 default 為 0（`from_dict` 用 `data.get("ascension_level", 0)`）。
  Modifier 套用點：
    - `start_run`：套 `Ascension.starting_hp_multiplier`
    - `start_next_battle`：套 `Ascension.enemy_hp_multiplier` 到 battle.state（區分 boss / 一般）
    - `_battle_gold_reward`：套 `Ascension.gold_multiplier`
  改 modifier 數值記得更新 `Ascension.describe()`
- **Boss phase**：`EnemyData.phase_2_actions` 是可選的第二招式組。`BattleController._check_phase_transition()`
  在 `play_card` 結算傷害後檢查，HP * 2 < max_hp 時 `phased = true`、`action_index` 歸零、log 提示。
  `next_enemy_action` 會在 phased 後改抽 phase_2_actions。3 個 boss 都已配對應的 phase 2 招式。
  舊存檔的 EnemyData 沒這欄位也不會 crash（`from_dict` 用 `data.get("phase_2_actions", [])`）
- **種子分享 / 每日挑戰**：主選單除了「開始遊戲」（隨機 seed），還有「每日挑戰」（用今天日期 hash）和「輸入種子」（彈窗 LineEdit，任意字串 hash 成 int）。
  `start_run` 流程：`seed(pending_seed if non-zero else randi())` → `_make_encounter_choices()` → `randomize()` 恢復隨機。
  Seed 存在 `RunState.map_seed`，progress screen 顯示在難度 A_N 旁邊方便截圖分享。
  Smoke test 驗證同 seed 兩次 generate 結構一致

### Debug menu (桌面開發用)

按 **F1** 切換，只在 `!OS.has_feature("mobile")` 時建構、只在 run 進行中可開啟。

快捷動作：
- **+100 Gold** — 直接加銅錢
- **Full Heal** — 補滿 HP，若正在戰鬥中也同步 `battle.state["player_hp"]` + `_refresh_battle()`
- **Add Random Card** — 從 `selected_character.reward_pool` 隨機加一張到牌組
- **Add Random Relic** — 從 `RelicCatalog.all()` 過濾 slot=general + 未持有，隨機加一個
- **Jump to Boss** — `encounter_index = encounter_choices.size() - 1` + 重畫地圖，玩家還是要手動點 boss 開戰

每個動作都會 `print("[DEBUG] ...")` 到 stdout，方便回頭追蹤是哪一步動了狀態。

加新 debug 動作的步驟：`debug_menu.gd` 加新 signal + 在 `_build()` 連個按鈕；`main.gd` 加 `_dbg_*()` handler 並在 `_build_debug_menu()` connect。

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

- `state` 是 plain Dictionary，沒做型別包裝。鍵名固定（見 `BattleController.setup()`）。
- 卡片 effect 都是 `{"kind": "damage", "amount": 10}` 形式，`EffectResolver._resolve_effect()` 中央 switch
- 狀態（poison/weak/vulnerable）的衰減在 `BattleController.start_turn()` 跟 `begin_enemy_phase()` 處理，不在 resolver 裡

## 測試

`scripts/smoke_test.gd` 是 SceneTree-based，跑 32 個獨立測試：

- 資料完整性（角色 / 敵人 / 卡片）
- 戰鬥機制（虛弱/破綻/格擋/中毒/能量耗盡/power 疊加/poison_burst）
- 多回合戰鬥完整流程 + victory HP 同步
- Save round-trip (RunState ↔ dict ↔ JSON)
- SaveManager 完整 save→load→from_dict 循環
- Save migration framework（v0 → 當前版本，欄位保留）
- 地圖生成：30 次 random seed 都無孤兒節點、boss 可達
- 傷害預測一致性：CardFormat.predict_enemy_damage vs EffectResolver 跨 9 組組合
- 卡片目標分類（CardFormat.requires_enemy_target 對 12 種 effect 組合）
- Party：3 人隊 round-trip、v1→v2 migrate、switch + 全滅判定、state sync、自動切人、starter weapons
- Bestiary persistence：clear → mark → kill_count 累加 → load_all round-trip
- Ascension persistence + modifier 計算（A0-A4 解鎖、HP / gold 倍數）
- Boss phase transition（3 boss 都有 phase_2_actions、HP <50% 觸發切換、next_enemy_action 用新招式）
- Event variety（至少 10 種 variant，欄位齊全，MapGenerator pool 包含全部）
- Map seed determinism（同 seed 兩次 generate 結構完全一致）
- 平衡 regression（基礎）：4 角色 vs 山賊頭目，30 場隨機 AI 無時限，全 100%（純 regression 偵測）
- 平衡 regression（中段）：4 角色 vs 蜈蚣大王，10 回合時限，30 場。
  zhao_linger baseline 20%（雙向偵測），其餘 100%（regression-only）。
  詳見「平衡 regression 失敗時怎麼處理」

新增測試：在 `_initialize()` 加一個 `_test_xxx()` 呼叫，然後實作該函式用 `assert()`。

成功要 print `"SwordCard smoke test passed."` 並 `quit(0)`，CI 用 grep 該字串判定成功。

### 平衡 regression 失敗時怎麼處理

`_test_balance_regression()` 對每個角色用起始牌組 + 隨機 AI 出牌，跑 30 場固定 seed 模擬。基準 (`BALANCE_BASELINES`) 寫死在 smoke_test.gd 頂部，容差 `BALANCE_TOLERANCE_PP = 15` 個百分點。

當 assert fail 時要先判斷是哪種狀況：

1. **意外的 regression**（沒有故意改平衡，但測試掛了）
   → 看是哪張卡 / 哪個 effect / 哪個 relic 的改動讓勝率掉下來，回頭檢查
   → 多半是 EffectResolver 改 effect 處理時有 off-by-one，或 BattleController 的狀態順序改了

2. **故意的平衡調整**（例如把李逍遙弱化、把山賊強化）
   → 重新跑 `godot --headless --path . -s scripts/smoke_test.gd` 看實際勝率
   → 把新觀測值寫進 `BALANCE_BASELINES`
   → 在 commit message 寫清楚「故意調整：X 從 100% → 80%，因為...」

3. **整套機制大改**（換了戰鬥系統、加了新卡片類型）
   → 暫時把該角色從 `BALANCE_BASELINES` 移掉（會印觀測值但不 assert）
   → 改完穩定後再補回 baseline

容差 15 pp 是給隨機 AI 的雜訊空間，不是給「小調整」的緩衝；如果你做的調整在容差內，那其實就是無關緊要的改動，可以不更新 baseline。

## 常見地雷

- **加新 `class_name` 後 Godot 報「identifier not declared」**：跑一次 `godot --headless --path . --import` 重建 global class cache
- **.import 檔不要 .gitignore**：CI 端首次匯入時會找不到對應的 .import 配置、build 直接掛掉。`.gitattributes` 已規範換行
- **不要把 `assert()` 用在正式邏輯**：release build 會被剝掉，assert 內的副作用會丟失
- **不要在 `_clear_root()` 後立刻存取舊 UI 變數**：`queue_free()` 是延遲釋放但變數已是 dangling，下一行重建就好

## Party Mode

組隊功能已實作。**主備制**（active 1 人 + 後排 0–2 人），最多 3 人組隊。下面內容是 implementation reference；改設計時請更新。

### 鎖定的設計決策

| 維度 | 決定 |
|---|---|
| 戰鬥模型 | **主備制（Pokemon 風）**：1 人 active 上場、最多 2 人後排，只有 active 被打 / 出牌 |
| 隊伍大小 | **1–3 人自由**。1 人 = 現在的單機體驗，組隊是 opt-in |
| Deck | **每角色獨立** draw / discard / hand（per-character `DeckManager`）|
| 死亡角色 | **保留在備位**（HP=0 不可上場、不會被踢出隊伍）；未來可被「復活卡 / event」救回 |
| 專武 | **每人各拿自己的** starter weapon（`add_relic(weapons_for_character(char.id)[0])` for each）|
| 重複角色 | **不允許**，同 character ID 唯一 |
| 隊長 | `characters[0]` 永遠是隊長；character select 時可改順序，run 開始後鎖死 |
| 存檔 | SAVE_VERSION **1 → 2**，要寫 migration |

### 預設數值（實作時可調）

- **Energy**：`3 + (party_size - 1)` → 1 人 3、2 人 4、3 人 5
- **後排回血**：每回合 turn-end，活著的後排（HP > 0）+ 2 HP（封頂 max_hp）
- **切換成本**：每回合可免費切 1 次；同回合再切要花 1 energy
- **Active 戰死**：強制免費 switch 到第一個活著的後排；全滅才 `is_defeat`

### 資料模型

`RunState` 從單角色改成陣列形式：

```gdscript
# 之前
var character: CharacterData
var hp / max_hp / power_bonus: int
var deck: Array[CardData]

# 之後
var characters: Array[CharacterData] = []           # 1–3 人，characters[0] 是隊長
var character_hps: Array[int] = []
var character_max_hps: Array[int] = []              # 已套 ascension starting_hp_multiplier
var character_power_bonus: Array[int] = []          # power 是 per-char buff
var character_decks: Array[Array[CardData]] = []    # 每人獨立 deck
var active_character_index: int = 0
# relics / gold / encounter_index / pending_rest_heal / ascension_level / map_seed 維持全隊共用
```

### BattleController 改動策略

**最低破壞性原則**：保留 `state["player_*"]` 作為「指向當前 active player 的 alias」，每次 switch 時 `_sync_state_to_active()` 寫回陣列、再 `_sync_active_to_state()` 把新 active 拷貝到 alias。**EffectResolver 內部邏輯幾乎不用改**。

```gdscript
state = {
    "energy": ...,
    "enemy_*": ...,
    "players": [
        {"name": ..., "hp": ..., "max_hp": ..., "block": 0, "poison": 0, "weak": 0, "vulnerable": 0, "power": ...},
        ...,
    ],
    "active_player_index": 0,
    "switched_this_turn": false,
    "player_hp": ..., "player_block": ...,  # alias，自動同步
}
var decks: Array[DeckManager] = []
func active_deck() -> DeckManager: return decks[state["active_player_index"]]
```

Sync 呼叫時機：
- `start_turn` / `play_card` / `resolve_enemy_phase` 結束 → `_sync_state_to_active()`
- `switch_active` 之後 → `_sync_active_to_state()`
- `start_turn` 開頭 → 後排回血 + reset `switched_this_turn`

`is_defeat` 改成「全員 HP <= 0」；active 戰死時 `_check_battle_end` 先試 `_force_switch_to_first_alive`。

### Save migration v1 → v2

```gdscript
match version:
    0: pass  # legacy v0 視為 v1
    1:
        data["character_ids"] = [data.get("character_id", "")]
        data["character_hps"] = [int(data.get("hp", 0))]
        data["character_max_hps"] = [int(data.get("max_hp", 0))]
        data["character_power_bonus"] = [int(data.get("power_bonus", 0))]
        data["character_decks"] = [data.get("deck", [])]
        data["active_character_index"] = 0
        # 舊 keys 留著不刪，from_dict 不會讀它們
```

`SaveManager.SAVE_VERSION += 1`，`RunState.from_dict` 只看新版 keys。

### UI 變動範圍

- **character_select**：多選 + 排序（先選的自動成為隊長，可上下移）。最多 3 人勾選才能「出戰」
- **battle 畫面**：active portrait 維持原大小；左側豎排 1–2 個後排小頭像（90×90）+ 小 HP 條；點後排頭像 = `switch_active(該 index)`，死亡 / 同人灰掉
- **left_dock**：加「切換 1/1 免費」狀態文字
- **show_progress_screen 狀態列**：改顯示「李 30/40 · 趙 25/35 · 林 0/40」三人 HP
- **手牌**：只顯示 active 的（其他角色 deck 在他們各自的 draw pile）

### 影響面 checklist

| 系統 | 怎麼處理 |
|---|---|
| `Ascension.starting_hp_multiplier` | 對每個 `character_max_hps[i]` 各乘一次 |
| `Ascension.enemy_hp_multiplier` | 不變（敵人血量不依隊伍 size scale）|
| Relic `acquire_triggers` 的 `max_hp_bonus` | MVP：給隊長；之後可改全隊 |
| `_battle_gold_reward` | 不變（全隊共享 gold）|
| `_dbg_full_heal` | 滿血所有角色 |
| `_dbg_add_card` | 加到 active 角色的 deck |
| `show_result` | victory = 走完最後一層即可（不要求全員活）；defeat = 全員 HP <= 0 |
| balance regression test | 加 1 人 / 2 人 / 3 人三組 baseline |
| Bestiary / map / event / shop | 不變 |

### 實作狀態

| Phase | 內容 | Commit |
|---|---|---|
| 1. 資料層 | RunState 陣列化、property aliases、SaveManager v1→v2 migrate | `feat(party): phase 1` |
| 2. BattleController | `state.players` + `decks` + `_sync_*` + `switch_active` + 後排 +2 HP/回合 + 全滅判定 + active 死自動切 | `feat(party): phase 2` |
| 3. character select | 多選 + 排序 + 隊長 ★ + 出戰按鈕 | `feat(party): phase 3` |
| 4. battle UI | 後排頭像 widget（點擊切換）+ active 肖像/HP/狀態 hot-swap + 切換次數提示 | `feat(party): phase 4` |
| 5. ascension/relic/UI 整合 | 主選單存檔摘要、map status popup、debug full heal、retry 全隊回滿 | `feat(party): phase 5` |
| 6. 測試補強 | 8 個新 smoke test 覆蓋 round-trip / migrate / switch / state sync / 自動切人 / 專武 | (含在各 phase) |

### Smoke test 覆蓋

- `_test_party_round_trip` — 3 人隊 RunState ↔ dict round-trip
- `_test_save_migration` — v1 單角色存檔 → v2 1 人隊伍（character_decks 不丟卡）
- `_test_party_switch_and_defeat` — energy=5、第一次切免費、第二次扣 1、全滅 = `is_defeat`
- `_test_party_state_sync` — 切換 → 狀態跟著角色 slot 走（切回原人 block/poison 保留）
- `_test_party_auto_switch_on_death` — active 死 → `_force_switch_to_first_alive`；全滅才 defeat
- `_test_party_starter_weapons` — 每人都拿到自己的專武（如有定義）

### 已知未實作 / 之後再說

- 復活機制（卡片 / event 救回倒下的後排）— 死人停留在隊伍中等待救援的基礎結構已就緒
- 多人隊 balance regression baseline — 隨機 AI 不會主動切換，跑出來不太能反映實戰
- 切換時的視覺過場動畫（目前是 portrait hot-swap）

### 風險與防呆

1. **EffectResolver 同步 bug**：`_sync_*` 漏欄位 → 狀態錯亂。
   **對策**：smoke test 寫「切換 → 打卡 → 切回 → 確認原 player 狀態被保留」測試。
2. **存檔遷移漏欄位**：v1 → v2 漏 `character_decks` → 老存檔載入後 deck 空。
   **對策**：migration test assert `restored.character_decks[0].size() > 0`。
3. **平衡崩盤**：3 人隊預期戰力 1.5×–2× 單人。
   **對策**：先不改 enemy HP，跑 balance regression 看實際勝率變化、再決定要不要 scale。
4. **死亡角色卡塞滿手牌**：因為每人獨立 deck，**死人的 deck/hand 不會被別人抽到**，無此問題。

## Git Workflow

- main branch 直接 push，沒有 PR review 流程（個人專案）
- commit message 用 conventional commits：`fix(scope):`、`refactor:`、`test:`、`chore:`、`ci:`
- `.gitattributes` 已規範換行；不要手動覆蓋

## 藥品系統（Potions）

目前**完全未實作**。下面是設計藍圖；實作時按 Phase 順序來。

### 鎖定的設計決策

| 維度 | 決定 |
|---|---|
| 攜帶上限 | **3 格**（固定；未來遺物可擴到 4） |
| 使用時機 | **戰鬥中任意時刻**（自己回合或敵人回合皆可；不消耗靈力） |
| 戰鬥外使用 | **不允許**（藥效設計假設在戰場才有意義） |
| 丟棄 | 戰鬥外長按藥格可丟棄（清出格子） |
| 稀有度 | common / uncommon / rare，決定效果強度與售價 |
| 同格疊放 | **不允許**（每格只能放 1 瓶） |
| Save | `RunState.potions: Array[Dictionary]`，存 id + 暫無其他欄位 |

### PAL1 藥品參考

| 藥品名 | 效果 | 稀有度 |
|---|---|---|
| 回春丹 | 回復 15 HP | common |
| 靈力丹 | 本回合靈力 +2 | common |
| 護體符 | 獲得 10 護體 | common |
| 解毒散 | 清除所有蠱毒 | common |
| 靈蛇膽 | 施加敵人 3 層破綻 | uncommon |
| 虎骨酒 | 本場戰鬥攻擊力 +3（power） | uncommon |
| 金瘡藥 | 回復 30 HP | uncommon |
| 天靈丹 | 回復 50 HP | rare |
| 仙人遺血 | 回復 40 HP＋本場攻擊力 +2 | rare |
| 月魂草 | 抽 3 張牌＋本回合靈力 +1 | rare |

### 資料模型

新增 `scripts/potion_catalog.gd`：

```gdscript
class_name PotionCatalog
extends RefCounted

static func all() -> Array[Dictionary]:
    return [
        {"id": "huichun_dan",  "display_name": "回春丹",  "rarity": "common",
         "description": "回復 15 點生命。",
         "effects": [{"kind": "heal", "amount": 15}]},
        {"id": "lingli_dan",   "display_name": "靈力丹",  "rarity": "common",
         "description": "本回合靈力 +2。",
         "effects": [{"kind": "energy", "amount": 2}]},
        # ... 其餘依表格補齊
    ]

static func by_id(id: String) -> Dictionary:
    for p in all():
        if p["id"] == id:
            return p
    return {}

static func price_of(potion: Dictionary, is_black_shop: bool) -> int:
    var base: int = 40
    match potion.get("rarity", "common"):
        "uncommon": base = 65
        "rare":     base = 95
    if is_black_shop:
        base = int(ceil(base * 1.2))
    return base
```

`RunState` 加欄位（不升 SAVE_VERSION，`from_dict` 用 `data.get("potions", [])` 回退空陣列）：

```gdscript
var potions: Array[Dictionary] = []   # max 3 元素，每個是 PotionCatalog.all() 的一筆
```

`to_dict()` / `from_dict()` 各加一行：
```gdscript
# to_dict
result["potions"] = potions.duplicate()
# from_dict
potions = []
for p in (data.get("potions", []) as Array):
    potions.append(p as Dictionary)
```

### 戰鬥中 UI

`_build_battle_scene()` 在 left_dock 最上方（能量珠上面）加「藥格列」：

```
[藥格 0] [藥格 1] [藥格 2]
```

- 各格 **48×48**（compact: 38×38），有瓶子圖示或名稱縮寫
- 空格顯示灰色虛線框
- 點擊已有藥 → 立即使用，呼叫 `_use_potion(slot_index)`
- `_use_potion(i)` 流程：
  1. 取出 `run_state.potions[i]`
  2. 呼叫 `battle.resolver._resolve_effects_from_list(effects, battle.state)` （需在 EffectResolver 加此 public helper）
  3. `run_state.potions.remove_at(i)`
  4. `_refresh_battle()`（刷新 HP、Block、Energy 顯示）
  5. `DamagePopup.spawn(...)` 顯示效果數字

戰鬥外（地圖/事件/商店）：左上角或固定位置顯示 3 個小藥格；長按可丟棄，無點擊使用。

### 商店整合

`show_shop_node()` 在 services_row 旁邊加「藥品列」，最多展示 **2 瓶**隨機藥品：

- 由 `ShopInventory` 的新 static `build_potions()` 方法生成（從 `PotionCatalog.all()` shuffle 取 2）
- 藥格顯示名稱＋價格＋「購買」按鈕
- 背包滿（已有 3 瓶）時按鈕 disable，tooltip 提示「藥格已滿」
- `run_state.current_shop_potions` 存放本次商店的藥品快照（同 `current_shop_inventory` 的模式）
- `shop_discount` relic 效果同樣套用到藥品售價

### EffectResolver 擴充

加 public helper（讓藥品和未來其他系統也能呼叫）：

```gdscript
func resolve_effects_list(effects: Array, state: Dictionary) -> Array[String]:
    var log_lines: Array[String] = []
    for effect: Dictionary in effects:
        log_lines.append_array(_resolve_effect(effect, state))
    return log_lines
```

同時 `_resolve_effect` 需支援藥品特有 kind（若有）：
- `"cure_poison"`：清除 `state["player_poison"] = 0`
- 其餘（heal / energy / block / power / draw / vulnerable / weak）已有支援，直接複用

### Save migration

不升 `SAVE_VERSION`。`from_dict` 對 `potions` 用 `data.get("potions", [])` 回退即可。
若未來重構 potions 結構（例如加 charges 欄位）才升版本。

### 實作狀態

| Phase | 內容 | Commit |
|---|---|---|
| 1. 資料層 | `potion_catalog.gd`（10 種藥）＋ `RunState.potions` + to/from_dict | `feat(potion): phase 1` |
| 2. EffectResolver | `resolve_effects_list()` helper + `cure_poison` kind | `feat(potion): phase 2` |
| 3. 戰鬥 UI | left_dock 藥格列 + `_use_potion()` + DamagePopup + 戰鬥外小格顯示 | `feat(potion): phase 3` |
| 4. 商店整合 | `ShopInventory.build_potions()` + 商店藥品列 + 丟棄功能 | `feat(potion): phase 4` |
| 5. 來源補充 | 戰鬥後掉落（小機率）＋ event_data 新增給藥獎勵 | `feat(potion): phase 5` |
| 6. 測試補強 | smoke test：catalog 完整性、use_potion 效果、save round-trip | （含在各 phase） |

### Smoke test 覆蓋

- `_test_potion_catalog` — 10 種藥都有 id / display_name / effects，PotionCatalog.by_id 能找到
- `_test_potion_save_roundtrip` — RunState 放 2 瓶藥 → to_dict → from_dict → 藥品保留
- `_test_potion_use_heal` — 戰鬥 state 接 resolve_effects_list(heal 15) → player_hp 正確增加
- `_test_potion_cure_poison` — 有 3 層蠱毒 → 使用解毒散 → player_poison = 0
- `_test_potion_old_save_compat` — 無 potions 欄位的舊存檔 → from_dict 不 crash，potions = []

### 影響面 checklist

| 系統 | 處理方式 |
|---|---|
| 平衡 regression | 不影響（測試用固定 AI，不主動用藥） |
| Debug menu | 加「Give Random Potion」快捷按鈕 |
| Bestiary / map | 不變 |
| 遺物 `max_potion_slots` | Phase 1 不加；預留 `RunState.max_potion_slots` 屬性供未來遺物用 |
| 戰鬥外丟棄 UI | Phase 3 一起做；地圖畫面右側固定小格 |

### 已知未實作 / 之後再說

- 戰鬥中使用動畫（目前 DamagePopup 已夠用）
- 丟棄確認 dialog（直接長按丟棄，不另加 confirm）
- 多人隊藥品使用對象（Phase 3 MVP：藥品效果只作用在 active 角色；heal 系列之後可改成「選擇目標」）

## 多敵人系統（Multi-Enemy Mode）

目前**完全未實作**（戰場嚴格 1v1）。下面是設計藍圖；實作時按 Phase 順序來。
靈感來自 Slay the Spire；Boss 可以**召喚小怪**為核心新機制。

### 鎖定的設計決策

| 維度 | 決定 |
|---|---|
| 戰場規模 | **1–3 敵人**同時上場。普通節點 1–2 敵、後期 act 可 3 敵；**boss 戰開場 1 敵**（boss 可召出小怪）|
| 卡片目標 | 三種：`single`（拖到敵人 / 點 active）、`aoe`（一鍵全打）、`self`（純自身）|
| AOE 卡實作 | **新 effect kind `damage_all` / `poison_all` / `weak_all` / `vulnerable_all`**，不是 card-level flag。跟既有 effect kind 系統一致 |
| Active target | 點敵人 portrait 設定 active；hover 預覽 intent；drag 直接命中該敵 |
| Alias 策略 | `state["enemy_*"]` 永遠是「active enemy 的 alias」，自動同步。**EffectResolver 內部邏輯幾乎不用改** — 同 Party Mode 策略 |
| Action 順序 | 每敵獨立 `action_index`、`phased`；敵人回合按陣列順序逐個結算 |
| 各敵獨立 phase 2 | Boss 才有，但邏輯通用（每敵可有 phase_2_actions）|
| Loot | 戰鬥結束總和：每敵各算 1 次 gold，但召喚物不掉 loot（避免無限刷）|
| 召喚物 EXP | baseline 30% EXP（弱化版 ≈ 弱化獎勵）|
| Bestiary | 召喚物計入圖鑑（獨立 entry，跟其原型分開）|
| 阿奴開場 poison passive | 套到**全部敵人**（PAL1「下蠱」直覺一致）|
| 林月如反擊 passive | 反擊 → 打到「上一個攻擊她的敵人」（需 `state["last_attacker_index"]`）|
| 召喚上限 | 戰場同時最多 **3 敵**（含召喚物）。已滿時 boss 的召喚 action 失效（無聲 fallback 或改播 flavor log）|
| 召喚物來源 | 每個 boss 在 EnemyData 定義 `summon_pool: Array[String]`，召喚時從中隨機抽 1 |
| 召喚時機 | 透過新 effect kind `summon` 放在 boss `actions` 或 `phase_2_actions` 內，與其他招式輪替 |
| 勝利條件 | 全部敵人（含召喚物）都死才算勝。Boss 死後留下的小怪要清乾淨 |

### 資料模型

`BattleController` 從單敵改成陣列形式：

```gdscript
# 之前
var enemy: EnemyData
var action_index: int = 0
var phased: bool = false

# 之後
var enemies: Array[EnemyData] = []           # 1–3 敵，clone()'d
var enemy_action_indices: Array[int] = []    # 每敵獨立輪替
var enemy_phased: Array[bool] = []           # 每敵獨立 phase 2

# 向後相容 getter
var enemy: EnemyData:
    get:
        var idx: int = state.get("active_enemy_index", 0)
        return enemies[idx] if idx < enemies.size() else null
```

### state 結構

```gdscript
state = {
    "enemies": [
        {"name": ..., "hp": ..., "max_hp": ..., "block": 0,
         "poison": 0, "weak": 0, "vulnerable": 0,
         "intent": {...}, "loot_table": [...]},
        ...,
    ],
    "active_enemy_index": 0,
    # alias（自動同步到 enemies[active_enemy_index]）
    "enemy_name": ..., "enemy_hp": ..., "enemy_max_hp": ...,
    "enemy_block": ..., "enemy_poison": ...,
    "enemy_weak": ..., "enemy_vulnerable": ...,
    "enemy_loot_table": ...,
    "last_attacker_index": 0,  # 林月如反擊指向
    # players / energy / ... 同 Party Mode 不變
}
```

Sync 呼叫時機：
- `set_active_enemy` 之後 → `_sync_active_enemy_to_state()`
- `play_card` / `resolve_enemy_phase` 結算完 → `_sync_state_to_active_enemy()`
- 敵人死亡 / 召喚物加入 → enemies 陣列變動後 `_recompact_active_index()`

### 新 EnemyData 欄位

```gdscript
@export var summon_pool: Array[String] = []  # 召喚可挑的敵人 id；空 = 不召喚
```

### 新 effect kinds

```gdscript
"damage_all":      對全部活著的敵人各造成 amount（套用 power/weak/vulnerable）
"poison_all":      所有敵人各加 amount 蠱毒
"weak_all":        所有敵人各加 amount 虛弱
"vulnerable_all":  所有敵人各加 amount 破綻
"consume_energy_damage_all": 耗盡靈力、每點對全敵 amount 傷害
"summon":          {"kind": "summon", "count": 1[, "enemy_id": "..."]}
                   未指定 enemy_id → 從當前 boss.summon_pool 隨機抽
                   戰場已滿（>=3）→ 拒絕，log "戰場已滿" flavor
```

### 召喚機制 BattleController API

```gdscript
const MAX_ENEMIES_PER_BATTLE: int = 3

func spawn_enemy(enemy_id: String) -> bool:
    if enemies.size() >= MAX_ENEMIES_PER_BATTLE:
        return false
    var template: EnemyData = GameData.enemy_by_id(enemy_id)
    if template == null:
        return false
    var clone: EnemyData = template.clone()
    enemies.append(clone)
    enemy_action_indices.append(0)
    enemy_phased.append(false)
    state["enemies"].append({
        "name": clone.display_name,
        "max_hp": clone.max_hp,
        "hp": clone.max_hp,
        "block": 0, "poison": 0, "weak": 0, "vulnerable": 0,
        "intent": {}, "loot_table": GameData.loot_table_for(clone.id),
    })
    add_log("%s 召喚出 %s！" % [_enemy_display_name(), clone.display_name])
    return true
```

新增 `GameData.enemy_by_id(id)` 註冊表 helper。

### 新弱版 EnemyData（召喚物用）

| ID | display_name | HP | 招式（示意） | 用於 |
|---|---|---|---|---|
| `water_tentacle` | 水妖觸手 | 22 | 鞭打 6 / 防 8 / 纏繞 weak 2 | 拜月教主 phase 2 |
| `red_eye_imp` | 赤眼幼魈 | 18 | 撓擊 5 / 怒吼 weak 1 | 赤眼山魈 phase 2 |
| `tower_wisp` | 鎖妖塔殘魂 | 16 | 魂吸 4+poison 1 | 山靈巫后 phase 2 |
| `centipede_brood` | 蜈蚣幼蟲 | 14 | 啃噬 4+poison 2 | 蜈蚣大王 phase 2 |
| `zombie_thrall` | 殭屍奴 | 20 | 抓撲 6 / 守 5 | 殭屍大帥 phase 2 |

5 個召喚物，每個 boss 至少 1 種可召喚物。Bosses 的 `summon_pool` 對應補上。

### UI 變動範圍

- **enemy_row**：水平 row，最多 3 個 portrait（單敵時居中、保留現在 1v1 視覺）
- **active 高亮**：金色邊框；其他敵半透明，hover 時 modulate 提亮
- **每敵獨立**：HP bar / block badge / status line / intent badge / feedback label
- **drag-to-play**：拖到任一 portrait hit box → 命中該敵
- **AOE 卡 drag**：拖出手牌區即可（不需要指定目標）；視覺上 3 敵同時 flash
- **召喚動畫**：新敵 portrait scale 0.7→1.0 + alpha 0→1，0.4s fade-in
- **多敵 enemy_row layout**：3 敵時自動縮 portrait size（從 200x200 → 160x160）；compact mode 再縮 20%
- **CardFormat.predict_enemy_damage**：簽名改 `(action, state, enemy_index)`，可預測對任一敵的傷害

### EffectResolver 改動

`_resolve_effect` 對 `damage / poison / weak / vulnerable` 仍透過 `state["enemy_*"]` alias 結算（指向 active）。
新 `*_all` kinds 直接遍歷 `state["enemies"]` 陣列，每敵套同樣公式。

```gdscript
"damage_all":
    var amount = int(effect.get("amount", 0))
    for i in range(state["enemies"].size()):
        var enemy_slot = state["enemies"][i]
        if int(enemy_slot["hp"]) <= 0:
            continue
        _resolve_damage_on_enemy_slot(enemy_slot, amount)
```

`_resolve_damage_on_enemy_slot` 是新 helper，從現有 damage 邏輯抽出。

### Save migration

**不升 `SAVE_VERSION`**。戰鬥中的 state 不存在 savegame.json 裡（只存 run 進度），所以多敵改動對存檔格式無影響。

### MapGenerator + encounter 表

```gdscript
const ACT_ENCOUNTERS: Dictionary = {
    1: [
        {"enemies": ["bandit"],       "weight": 4},
        {"enemies": ["beast"],        "weight": 4},
        {"enemies": ["bandit_pup", "bandit_pup"], "weight": 2},  # 雙弱敵
    ],
    2: [...],
    # ...
}
```

`MapGenerator.choose_enemies_for_act(act)` → 加權隨機選一組（替代既有 `enemies_for_act` 的單敵選法）。

### 影響面 checklist

| 系統 | 怎麼處理 |
|---|---|
| `_simulate_random_battle` | 接受 `Array[EnemyData]`，內部單敵就退化成現行為 |
| balance_matrix.gd | 同上；加多敵 scenarios |
| `BALANCE_BASELINES*` | 單敵情境不變；新增 multi-enemy 組 baselines |
| `_test_balance_leveled_progression` | 不變（boss 永遠 1 敵，但要考慮召喚物影響） |
| `loot_table_for` | 召喚物無 loot（spawn_enemy 把 loot_table 設空陣列）|
| `_battle_gold_reward` | 加總所有死敵的 loot；召喚物不計 |
| 阿奴 battle_start poison passive | 改套到全部敵人；spawn_enemy 不觸發（避免無限刷毒）|
| 林月如 first_block_counter passive | 用 `last_attacker_index` 指定目標 |
| Boss `phase_2_display_name` 變身 | 不變（每敵獨立 phased flag）|
| Bestiary | 召喚物各自獨立 entry |
| Debug menu | 加「Spawn Test Minion」快捷 |

### 實作狀態（規劃）

| Phase | 內容 | Commit |
|---|---|---|
| 1+2. 資料層 + AOE | BattleController state 陣列化、alias 同步、EffectResolver 加 `*_all` kinds | `feat(multi-enemy): phase 1+2 data layer + AOE` |
| 3+3.5. 多體回合 + 召喚 | per-enemy `action_index` / `phased` / intent；`summon` effect kind + `spawn_enemy()` + `EnemyData.summon_pool` | `feat(multi-enemy): phase 3 turn + summon` |
| 4. 戰鬥 UI | enemy_row、active 高亮、drag 命中個別敵、AOE 視覺、召喚物 fade-in | `feat(multi-enemy): phase 4 UI` |
| 5+8. 內容 | MapGenerator + 弱版 EnemyData + 5 召喚物 + 改造 5–6 張卡用 `*_all` | `feat(multi-enemy): phase 5+8 content` |
| 6+7. 測試 + baseline | smoke test 多敵 round-trip / damage 路由 / 召喚 / 切換 active / AOE；balance_matrix 加多敵 scenarios | `feat(multi-enemy): phase 6+7 tests` |

預估 5 個 commits，~1500 行。

### Smoke test 覆蓋（規劃）

- `_test_multi_enemy_setup` — 3 敵 setup → state["enemies"].size() == 3、alias 同步到 enemies[0]
- `_test_multi_enemy_damage_routing` — 單體 damage 只打 active；切換 active 後再打、原敵 HP 不變
- `_test_multi_enemy_aoe` — damage_all 5 → 3 敵 HP 都 -5
- `_test_multi_enemy_partial_kill` — 中間敵死後 → enemies 陣列重組 / active_index 修正
- `_test_multi_enemy_victory` — 全敵死 → is_victory；boss 死但召喚物還活 → 戰鬥繼續
- `_test_summon_basic` — spawn_enemy → enemies +1、state 同步、log 出現
- `_test_summon_cap` — 已 3 敵時 spawn → 拒絕，回傳 false
- `_test_summon_unknown_id` — spawn 不存在 id → 拒絕
- `_test_anu_passive_multi_enemy` — battle_start → 全敵 poison +5

### 風險與防呆

1. **Alias 漂移**：active 切換後 alias 沒同步 → 狀態錯亂。
   **對策**：smoke test 寫「打卡 → 切 active → 打卡 → 切回 → 確認原敵 state 保留」。
2. **AOE 卡完全 break baseline**：改卡瞬間舊 baseline 全失效。
   **對策**：Phase 7 之前 baseline 保留；改卡後立即重跑、新 baseline 與舊並存。
3. **多目標卡動畫複雜**：3 敵同時受擊很亂。
   **對策**：AOE 卡飛中央、3 敵同步 flash + shake；單體卡飛指定敵不變。
4. **召喚物無限刷**：boss 每回合都召 → 戰場永遠滿。
   **對策**：MAX_ENEMIES_PER_BATTLE = 3；boss 召喚 action 在 action_index 輪替中佔比 ≤ 1/4。
5. **召喚物拖戰**：玩家把 boss 打到剩 1 HP，boss 一直召喚拖時間。
   **對策**：召喚物可被 AOE 一鍋端；boss 死後不再有新召喚（即使其他敵還活著）。
6. **UI mobile 擠壓**：3 敵在小螢幕擠在一起。
   **對策**：3 敵時自動縮 portrait；compact mode 再縮 20%。
7. **存檔向後相容**：戰鬥中 state 不存檔，無影響。

### 已知未實作 / 之後再說

- 召喚物可被「魅惑/控制」反過來幫玩家打 boss
- 多敵戰場的 boss action targeted 指定（boss 打 active vs 打全隊）— MVP 先用既有 player_* alias 套用
- 多敵 boss（2 boss 同場）— scope 太大，目前一律 1 boss
- 召喚物獨立的 phase 2 — 弱化版不需要
- 玩家「召喚」卡（如召喚劍靈助戰）— 需要新 effect kind `summon_ally`，留給未來


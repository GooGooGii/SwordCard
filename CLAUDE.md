# SwordCard — Architecture & Conventions

私人粉絲向原型：仙俠卡牌戰鬥，靈感來自仙劍奇俠傳系列。

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
- **戰敗 retry**：`show_result(false)` 不再立刻 `SaveManager.clear()`，而是多一顆「重打這一場（滿血，扣 1 件遺物）」按鈕。
  其他三顆按鈕（重新角色 / 重選角色 / 主選單）的 callback 才各自 clear save

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

`scripts/smoke_test.gd` 是 SceneTree-based，跑 19 個獨立測試：

- 資料完整性（角色 / 敵人 / 卡片）
- 戰鬥機制（虛弱/破綻/格擋/中毒/能量耗盡/power 疊加/poison_burst）
- 多回合戰鬥完整流程 + victory HP 同步
- Save round-trip (RunState ↔ dict ↔ JSON)
- SaveManager 完整 save→load→from_dict 循環
- Save migration framework（v0 → 當前版本，欄位保留）
- 地圖生成：30 次 random seed 都無孤兒節點、boss 可達
- 傷害預測一致性：CardFormat.predict_enemy_damage vs EffectResolver 跨 9 組組合
- 平衡 regression：4 角色 vs 第一個敵人，每角色 30 場隨機 AI 模擬

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

## Git Workflow

- main branch 直接 push，沒有 PR review 流程（個人專案）
- commit message 用 conventional commits：`fix(scope):`、`refactor:`、`test:`、`chore:`、`ci:`
- `.gitattributes` 已規範換行；不要手動覆蓋

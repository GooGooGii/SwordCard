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
  main.gd                主控制器，所有 screen 都在這裡建構（2100+ 行）
  ui_factory.gd          純 UI 工廠 (style_box, hp_bar, card_label, ...)
  theme_colors.gd        13 個 semantic 色常數
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

**全部用程式碼建構**，沒用 .tscn 場景檔（除了 main.tscn 入口）。常用元件都在 `UIFactory`：

```gdscript
var panel = UIFactory.make_panel()              # 預設樣式面板
var button = UIFactory.main_menu_button("開始", true)
var label = UIFactory.card_label("HP", 14, ThemeColors.TEXT_LIGHT, HORIZONTAL_ALIGNMENT_LEFT)
var bar = UIFactory.hp_bar(ThemeColors.HP_FILL, ThemeColors.HP_BG_DARK)
UIFactory.shake_node(node, 8.0, 0.25)          # 抖動動畫
var tex = UIFactory.load_texture(path)         # 有 cache
```

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
- `save_version` 寫在檔案內、載入時驗證
- `RunState.to_dict()` / `from_dict()` 是 single source of truth，新欄位記得兩邊都加

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

`scripts/smoke_test.gd` 是 SceneTree-based，跑 15 個獨立測試：

- 資料完整性（角色 / 敵人 / 卡片）
- 戰鬥機制（虛弱/破綻/格擋/中毒/能量耗盡/power 疊加/poison_burst）
- 多回合戰鬥完整流程 + victory HP 同步
- Save round-trip (RunState ↔ dict ↔ JSON)
- SaveManager 完整 save→load→from_dict 循環
- 地圖生成：30 次 random seed 都無孤兒節點、boss 可達

新增測試：在 `_initialize()` 加一個 `_test_xxx()` 呼叫，然後實作該函式用 `assert()`。

成功要 print `"SwordCard smoke test passed."` 並 `quit(0)`，CI 用 grep 該字串判定成功。

## 常見地雷

- **加新 `class_name` 後 Godot 報「identifier not declared」**：跑一次 `godot --headless --path . --import` 重建 global class cache
- **.import 檔不要 .gitignore**：CI 端首次匯入時會找不到對應的 .import 配置、build 直接掛掉。`.gitattributes` 已規範換行
- **不要把 `assert()` 用在正式邏輯**：release build 會被剝掉，assert 內的副作用會丟失
- **不要在 `_clear_root()` 後立刻存取舊 UI 變數**：`queue_free()` 是延遲釋放但變數已是 dangling，下一行重建就好

## Git Workflow

- main branch 直接 push，沒有 PR review 流程（個人專案）
- commit message 用 conventional commits：`fix(scope):`、`refactor:`、`test:`、`chore:`、`ci:`
- `.gitattributes` 已規範換行；不要手動覆蓋

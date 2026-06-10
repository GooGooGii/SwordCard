# 遊玩度優化執行方案（2026-06-10）

> 來源：`docs/GAME_REVIEW_2026-06.md` 總體檢報告。
> 本檔把報告結論落成**可逐項執行的工單**：每項含改動點（檔案級）、步驟、驗證方式。
> 美術需求一律登記 `ART_TODO.md`（不阻塞程式項）；程式項全部「先程式層、美術後補自動升級」。
>
> 驗證工具固定三件套：
> - `godot --headless --path . -s scripts/smoke_test.gd`（全綠才算過）
> - `render_*.gd` 實機截圖肉眼比對（UI 項前後各截一張）
> - `tools/ai_run.gd` AI 平衡驅動器（平衡項用真實決策打）

---

## P0-1 主選單排版重整 ｜排版・第一印象

**目標**：解決「按鈕迷你、懸空、沒有標題」。標題字美術已登記（ART_TODO §13，列最高優先）；程式層先行，不等美術。

| 項 | 內容 |
|---|---|
| 改動點 | `main.gd:show_main_menu()`、`ui_factory.gd:main_menu_button()` |
| 步驟 | ① 按鈕加寬至 ≥260px、高 ≥52px、字級 ≥20、垂直間距 14 → ② 標題改大號程式字（40+，墨描邊已有）置於按鈕列上方，預留 `assets/art/ui/title_swordcard.png` 接點（圖存在則換貼圖）→ ③ 整個選單欄改右側 1/3 豎排（左 2/3 留白給山水），或維持置中但下移收攏 → ④ 難度 picker / 每日挑戰 / 種子按鈕分組（主動作 vs 次動作字級區分） |
| 驗證 | `render_report.gd` 截主選單前後對照；手機解析度（720×1280 橫）再截一張確認 safe area |
| 風險 | 低。純 UI 重排 |

## P0-2 李逍遙中段勝率調查與修正 ｜平衡

**目標**：中段 baseline 李 3% vs 阿奴 83%，差距收斂到 4 角皆落在 20–60% 帶。

| 項 | 內容 |
|---|---|
| 改動點 | `game_data.gd`（passive / 起始牌組 / 阿奴開場毒）、`battle_controller.gd`（若 passive 改規則）、`smoke_test.gd:BALANCE_BASELINES_MID` |
| 步驟 | ① 先量化：用 `tools/ai_run.gd` 親手打李 vs 蜈蚣大王 3 場、阿奴 3 場，確認 3% 是「真弱」還是「隨機 AI 不會打李」→ ② 若真弱，候選修法（擇一，由實測決定）：A. passive「每**場**第一張攻擊 -1 費」改「每**回合**第一張」；B. 起始牌組 3 御劍術其中 1 張換爆發卡；C. 阿奴開場毒 5→3（壓 outlier 而非抬全體）→ ③ 改完重跑 30 場中段模擬，觀測值寫回 `BALANCE_BASELINES_MID`，commit message 註明「故意調整：李 3%→X%，因為…」 |
| 驗證 | smoke test 全綠（四層 baseline）；AI 驅動器再各打 1 場確認手感 |
| 風險 | 中。A 案會連動基礎/升級層 baseline，四層都要重觀測 |

## P1-3 幕間字卡 ×8 ＋ Boss 倒下定場文字 ｜故事

**目標**：用 8×2 段文字建立旅程主線（為什麼一路打過去），Boss 倒下不再直接黑屏。

| 項 | 內容 |
|---|---|
| 改動點 | `game_data.gd`（或新 `scripts/act_intro_data.gd`：`ACT_INTROS[act] = {title, lines}`、`BOSS_OUTROS[boss_id] = line`）、`main.gd`（新 `_show_act_intro()`；`_show_boss_story` 加「無圖時顯示文字定場卡」fallback） |
| 步驟 | ① 寫 8 幕開場文字（2–3 句：幕名＋目的＋鉤子，PAL1 正史對照 `docs/PAL1_CANON.md`）→ ② 每幕第一次進地圖前顯示：幕背景 + 暗角 + 直書/橫書字卡，點擊跳過 → ③ `_show_boss_story` 改成：有圖→圖+一行定場字；無圖→背景+定場字（Boss 劇情圖補上自動升級，ART_TODO §11 既有）→ ④ 終幕 `baiyue_lord` 額外做結局頁：依 `event_flags` / 隊伍組成出 2–3 種結語（基建現成） |
| 驗證 | 新增 smoke test：8 幕都有 intro、9 boss 都有 outro 文字；`render_report.gd` 加截字卡畫面 |
| 風險 | 低。純加法，不動戰鬥流程 |

## P1-4 地圖節點視覺強化 ｜排版

**目標**：節點不再被水墨底圖吃掉；當前/可去/已過一眼可辨。

| 項 | 內容 |
|---|---|
| 改動點 | `map_node_icon.gd`、`map_link_layer.gd`、`main.gd:show_progress_screen()` |
| 步驟 | ① 節點尺寸 ×1.5、底加圓形暗色襯底＋金描邊（程式畫，無需美術）→ ② 路徑線：已走過＝深墨實線加粗、可選＝金色實線、不可達＝淡虛線 → ③ 當前節點呼吸動畫（tween scale 1.0↔1.15）→ ④ 右上圖例改成首次進入顯示一次，之後收成「？」按鈕 → ⑤ compact（手機）模式同步驗證 |
| 驗證 | `render_report.gd` 地圖截圖前後對照（桌面＋手機解析度各一）|
| 風險 | 低 |

## P1-5 戰鬥卡面「圖大字少」改版 ｜排版

**目標**：卡面以圖為主、效果一行摘要；完整文字分流給既有長按預覽。

| 項 | 內容 |
|---|---|
| 改動點 | `main.gd`（手牌卡片建構處）、`card_format.gd`（新 `card_effect_summary(card)` 一行摘要：「9 傷 ×2」「格 12·抽 1」）、`ui_factory.gd` |
| 步驟 | ① CardFormat 加純函式摘要器（傷害/格擋/狀態用短詞＋數字，≤12 字）→ ② 卡面重排：上 60% 卡圖、中名稱、下一行摘要＋費用珠 → ③ 長按預覽（已有）顯示完整描述，確認觸控/桌面都通 → ④ 字階順手統一：定義 4 級（28/20/16/13）進 `UIFactory.FONT_*` 常數，本次先套戰鬥畫面 |
| 驗證 | 新 smoke test：全 161 卡 `card_effect_summary` 非空且 ≤14 字；`render_effects.gd` 截手牌＋長按預覽各一張 |
| 風險 | 中。摘要器要覆蓋全部 effect kind（30+），漏 kind 會顯示空白——smoke test 把門 |

## P2-6 戰績檔案「征途錄」 ｜長期黏著

| 項 | 內容 |
|---|---|
| 改動點 | 新 `scripts/run_history.gd`（`user://history.cfg`，仿 `bestiary.gd` 模式）、`main.gd:show_result()` 寫入＋主選單新按鈕＋新 `show_history()` 畫面 |
| 步驟 | ① 記錄欄位：日期、角色組合、A 層、到達幕/層、勝敗、死因（敵 id）、牌組大小、遺物數、seed → ② 勝敗結算時各寫一筆（上限留 50 筆，舊的滾掉）→ ③ 列表畫面複用 bestiary 的 grid/卷軸樣式 |
| 驗證 | smoke test：寫入→load round-trip、上限滾動、舊檔不存在不 crash |
| 風險 | 低。獨立 cfg，不碰 savegame |

## P2-7 成就 30 條 ｜長期黏著

| 項 | 內容 |
|---|---|
| 改動點 | 新 `scripts/achievements.gd`（定義表＋判定＋`user://achievements.cfg`）、`main.gd`（勝利/結算/事件處掛 `Achievements.check(context)`、主選單入口、達成 toast） |
| 步驟 | ① 首批 30 條全部用**現成資料**判定（Bestiary 全圖鑑、A1–A20 通關、各角色通關、毒 50 層、單回合 40 傷、無傷過 Boss、3 人隊通關、每日挑戰完成…），不為成就加新統計欄位 → ② 需要新統計的（累計傷害等）列第二批，之後再說 → ③ 達成時戰鬥外 toast（金邊橫幅 2 秒） |
| 驗證 | smoke test：每條成就的判定函式餵 mock context 不 crash、已達成不重複觸發 |
| 風險 | 低-中。判定 hook 散在 main.gd，集中走一個 `check()` 入口避免遍地開花 |

## P2-8 升級曲線壓平 ｜平衡 — ✅ 調查後結論：不需改動（2026-06-11）

**調查結果**：`card_data.gd:_upgraded_amount` 的升級公式**已經是** `amount + max(1, ceil(amount×0.25))`
（數值類 +25%、狀態/抽牌/能量 +1）——與 StS 標準一致，單卡升級增幅並不過猛。
報告中「3%→80% 跳躍」是 `BALANCE_BASELINES_MID_UPGRADED` 測試情境的人工複利：
該測試把**整副 12 張同時全升級**（實際遊戲玩家是逐張升級），全副 +25% 疊加自然造成大跳。
結論：升級曲線健康、**不調整**；測試情境的「全升級組」保留原用途（regression 上界偵測）。

## P2-9 隊友 banter 台詞 ｜故事

| 項 | 內容 |
|---|---|
| 改動點 | 新 `scripts/banter_data.gd`（`{trigger, members:[ids], lines:[]}` 池）、`battle_controller.gd`（switch/倒下/勝利處 emit signal）、`main.gd`（顯示：active 肖像旁 2 秒漸隱台詞泡） |
| 步驟 | ① 觸發點三個：切人上場、隊友倒下、戰鬥勝利 → ② 首批台詞：單人通用各 3 句 ×4 角 ＋ 配對組合（李×月如、李×靈兒、靈兒×阿奴、月如×阿奴）各 4 句，共約 30 句 → ③ 同場戰鬥同觸發不重複（記 used set）→ ④ 文案語感對齊 PAL1 角色性格（月如嗆、阿奴活潑、靈兒柔、逍遙痞） |
| 驗證 | smoke test：banter 池欄位齊全、所有 member id 存在；`render_effects.gd` 模式截一張切人台詞畫面 |
| 風險 | 低 |

## P2-10 多人隊 baseline 補洞 ｜平衡・測試

| 項 | 內容 |
|---|---|
| 改動點 | `smoke_test.gd`（隨機 AI 加最簡切人 policy：active HP<30% 且有活隊友→切）、新增 2 人/3 人 baseline 組 |
| 步驟 | ① policy 進模擬器 → ② 跑 2 人（李+阿奴）、3 人（李+趙+林）各 30 場 vs 中段 boss，記觀測值 → ③ 若 3 人隊勝率 >95%＝白給，回頭評估能量 `3+(size-1)` 是否改 `3 + (size-1)//2` 或敵人 HP 按隊伍 size 微調（設計藍圖預留的決策點） |
| 驗證 | smoke 全綠＋新 baseline 進表 |
| 風險 | 中。可能引出「組隊白給」的再平衡，但晚知道不如早知道 |

## P3-11 切人正向 hook ｜玩法

| 項 | 內容 |
|---|---|
| 改動點 | `battle_controller.gd:switch_active()`（切入者 +2 護體）、部分敵人 intent 加「盯防」（對切入者首回合傷害 +25%，挑 3–4 個中後期敵） |
| 驗證 | smoke：`_test_party_switch_*` 系列更新斷言；P2-10 的多人 baseline 重跑 |

## P3-12 短征模式（3 幕速通） ｜玩法

| 項 | 內容 |
|---|---|
| 改動點 | `run_state.gd`（`run_mode: "full"/"short"`，純加欄位不升版）、`main.gd`（主選單入口、act 上限 3、結算判定）、`map_generator.gd`（短征用幕 1/4/8 的敵表抽樣） |
| 驗證 | smoke：短征 round-trip、第 3 幕 boss 後即勝利；獨立 baseline 一組 |

## P3-13 卡圖風格一致性盤點工具 ｜美術 QA

| 項 | 內容 |
|---|---|
| 改動點 | 新 `tools/contact_sheet.gd`（SceneTree：把 167 卡圖按角色拼成數張網格大圖輸出）|
| 步驟 | ① 跑工具 → ② 肉眼掃網格，挑出水墨濃淡/線條最違和的 ~10 張 → ③ 違和清單登記 `ART_TODO.md` 待重生成 |
| 驗證 | 人工肉眼（這項本來就是肉眼工作）|

## P3-14 音訊收尾 ｜風格

| 項 | 內容 |
|---|---|
| 步驟 | ① 抽聽 14 首 BGM 確認同一音色家族（違和者登記重製）→ ② `.wav`→`.ogg` 批次轉檔（AudioManager 已相容，APK 體積直接受益）→ ③ 戰鬥背景色域統一：8 幕背景批次加淡墨 LUT/暗角（Python PIL 批處理），向卡圖色域靠攏 |
| 驗證 | 轉檔後跑一場戰鬥確認 BGM/SFX 正常；背景處理前後 `render_effects.gd` 截圖比對 |

## P3-15 經濟壓力測試 ｜平衡

| 項 | 內容 |
|---|---|
| 步驟 | ① `tools/ai_run.gd` 全程跑一輪（可用 `AIRUN_AUTO_BATTLE=all` focus 模式），逐幕記錄 gold 收入/支出/結餘 → ② 目標曲線：幕 4–6 玩家常態「想買買不起」→ ③ 偏離則調 loot 表或商店價，重跑驗證 |
| 驗證 | 曲線數據寫進 `docs/BALANCE_REPORT.md` |

---

## 美術需求（全部已登記 ART_TODO.md，不阻塞上述程式項）

| 需求 | ART_TODO 位置 | 優先 |
|---|---|---|
| 主選單毛筆題字 `title_swordcard.png` | §13 | **最高**（P0-1 的美術半邊） |
| 水墨 UI 5 件套（宣紙紋/卷軸框/筆觸分隔線/角落墨紋） | §13 | 高 |
| Boss 擊敗劇情圖 ×9（`baiyue_lord` 優先） | §11 | 中（P1-3 文字 fallback 先頂） |
| Boss phase 2 圖 ×2 落檔（tomb_general / centipede_lord） | §6C | 中 |
| 卡圖風格違和重生成（P3-13 盤點後列清單） | §14（新） | 低 |

## 建議執行批次

| 批次 | 項目 | 主要驗證 |
|---|---|---|
| 第 1 批 | P0-1 選單排版、P1-4 地圖視覺 | render 截圖前後對照 |
| 第 2 批 | P0-2 李逍遙調查修正 | AI 驅動器 + baseline 更新 |
| 第 3 批 | P1-3 幕間字卡、P2-9 banter | smoke 資料完整性 + 截圖 |
| 第 4 批 | P1-5 卡面改版 | 摘要器 smoke + 截圖 |
| 第 5 批 | P2-6 征途錄、P2-7 成就 | round-trip smoke |
| 第 6 批 | P2-8 升級曲線、P2-10 多人 baseline | 四層 baseline 重觀測 |
| 第 7 批 | P3 全部（hook/短征/工具/音訊/經濟） | 各項自帶 |

> 每批獨立 commit、跑完整 smoke；UI 批附截圖驗證。批間可穿插美術到貨的接圖工作（接點都已就緒，換圖不改版面）。

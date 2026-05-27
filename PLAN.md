# SwordCard Development Plan

## Project Direction

SwordCard 是仙劍奇俠傳 1 粉絲向原型，Godot 4 開發，Windows + Android 目標平台。
卡牌戰鬥靈感來自 Slay the Spire：回合制、抽/棄牌堆、靈力、敵人意圖、角色專屬牌組、Run 內成長。
內容優先使用 PAL1 原有素材（角色、招式、敵人、地點、道具），不足再自創。

---

## 已實作功能

### 核心戰鬥
- 四名可玩角色（李逍遙、趙靈兒、林月如、阿奴），各有專屬起始牌組（8 張）和獎勵池（10 張）
- 角色被動技能（逍遙折扣、靈兒戰前回血、月如護體反擊、阿奴初始蠱毒）
- 牌組抽/棄/洗牌；每回合抽 5 張、回復靈力
- 效果種類：傷害、護體、治療、蠱毒、虛弱、破綻、抽牌、靈力、自傷、power、consume_energy_damage、poison_burst、revive
- 敵人意圖顯示（攻擊/防禦/狀態 badge）
- Boss 二階段：HP < 50% 觸發 phase_2_actions，招式組切換
- 虛弱/破綻/蠱毒狀態，每回合衰減

### 地圖與 Run 流程（五幕制）
| 幕 | 地點 | 一般敵人 | Boss |
|---|---|---|---|
| 1 | 余杭山間 | 山賊頭目、山林妖獸 | 赤眼山魈 |
| 2 | 蘇州地底 | 劍冢靈影、魅狐幻影、地底殭屍 | 殭屍大帥 |
| 3 | 苗疆蠱土 | 蠱毒妖人、赤蛇妖、毒蜈蚣 | 蜈蚣大王 |
| 4 | 鎖妖塔 | 塔中封魔、鎖妖塔鬼兵 | 山靈巫后 |
| 5 | 拜月決戰 | 拜月教徒、拜月教衛、上古惡靈 | 拜月教主 |

- 每幕獨立隨機地圖（9–11 層 + Boss，樹狀連線不交叉）
- 幕間過場：全員回復 20 HP，顯示 PAL1 劇情銜接文字
- 通關畫面：「通關！仙劍成道」（需打完第五幕）
- 節點類型：戰鬥、事件、商店、休息、Boss

### 事件系統（31 種 variant）
- **基礎 (8)**: shrine、spring、talisman_cache、treasure_chest、ancestor_relic、wandering_sage、moonlit_pool、broken_temple
- **進階 (10)**: yokai_pact、forgotten_altar、ancient_battlefield、alchemy_furnace、ghost_forest、immortal_ruins、spirit_clan_ruins、baiyue_altar、tavern_acquaintance、sword_tomb、miao_healer
- **PAL1 名場面 (9)**: shilipo_sword_god、drunk_swordsman、yinlong_cave、yangzhou_officer、xianling_shrine、lingmiao、flower_thief、flower_spirit、jianling_whisper、aqi_reunion、tangyu_sparring、jiang_waner_grief

每事件可有：
- choices: heal / power / gain_card / upgrade / remove / view_deck / pact / gamble / tainted_power / fight / **observe / leave**
- **sub_choices**: 多階段（先選 approach → 開子選單再選 effect）。已套用：drunk_swordsman / yinlong_cave / baiyue_altar / forgotten_altar / alchemy_furnace
- **choice_filters**: 角色限定選項（shilipo / xianling 趙靈兒 / immortal_ruins 李逍遙）
- **character_outcomes**: 個人化結局文字（baiyue / sword_tomb / xianling / miao_healer / spirit_clan_ruins / tavern_acquaintance 4 chars / drunk_swordsman / jianling 等）
- **observe_text**: 加長觀察文字，玩家可看完再決定要不要進入

### 遺物系統（59 件 = 45 通用 + 8 角色專武 + 6 神器）
- 稀有度：basic、uncommon、rare、legendary、artifact（Boss 特定掉落）
- 效果種類：永久 buff（傷害/HP/draw）、觸發型（戰鬥開始/每回合/擊殺/勝利）
- Boss 擊敗必掉對應神器；無對應神器時隨機掉落；一般戰鬥 25% 機率掉落
- 戰鬥中「遺物 (N)」按鈕查看說明 popup
- 6 神器：拜月神符 / 蜈蚣甲 / 噬靈骨 / 赤眼符印 / 鬼將令牌 / 拜月教旨（5 act boss + moon_worshipper 一般敵）

### 商店
- 一般商店：隨機角色卡 3 張 + 可選遺物
- 黑市：25% 機率出現，30% 機率賣角色專武、可購買移除/升級服務

### 休息節點
- 選項：回復 25% max_hp 或升級 1 張牌

### 組隊系統（Party Mode）
- 1–3 名角色組隊（主備制，Pokemon 風）
- 每角色獨立牌組/HP/護體/蠱毒/靈力等狀態
- Active 死亡自動切到第一個存活後排；全員倒地才判定失敗
- 切換成本：每回合免費 1 次，再切扣 1 靈力
- 後排每回合 end 回復 2 HP
- 靈力 = 3 + (隊伍人數 - 1)

### 難度層級（Ascension A0–A4）
- A1：一般敵人 HP +20%　A2：Boss HP +20%　A3：起始 HP -15%　A4：銅錢 -25%
- 完成 AN 解鎖 A(N+1)

### 種子 / 每日挑戰
- 主選單可選「隨機」「每日挑戰（日期 hash）」「輸入種子」
- 種子顯示在進度畫面，方便截圖分享

### 敵將圖鑑（Bestiary）
- 跨 Run 持久化擊敗紀錄（user://bestiary.cfg）
- 未擊敗顯示黑色剪影 + ???；擊敗後顯示名字/HP/招式

### 存檔 / 讀檔
- user://savegame.json atomic write（先寫 .tmp 再 rename）
- 目前版本：SAVE_VERSION = 3（v1→v2→v3 自動升級）
- 中途離開（App 切背景）自動存檔

### UI / 體驗
- 全程式碼建構 UI（UIFactory、ThemeColors、CardFormat）
- 手牌扇形排列；點兩下出牌、拖拉出牌、長按預覽升級版
- 結束回合確認警告（剩靈力時提示，1 秒後自動確認）
- 戰鬥失敗可「重打此場（扣 1 遺物）」
- 路線總覽 popup（★當前 / ✓已過 / ·待選）
- 地圖節點 icon、連線渲染（MapLinkLayer）
- DamagePopup 浮動數字（傷害/治療/護體/蠱毒/虛弱/破綻）
- 角色切換肖像動畫漸變
- F1 開發者選單（+金幣 / 滿血 / 加卡 / 加遺物 / 跳 Boss）
- 暫停選單（Esc / 實體返回鍵 / 螢幕按鈕）
- Android Safe Area 適配、觸控友善
- 戰鬥手感反饋：HP bar 平滑 tween / 能量珠 pulse / 狀態變化浮字 / 重擊強化震動 / Block badge pulse
- 卡片出牌動畫飛行（根據 effect 自動判斷飛向敵人或自己）

### 多敵人系統（Multi-Enemy Mode，Phase 1–4A 已完成）
- 戰場 1–3 敵人；boss 一律開場 1 敵但可召喚小怪
- BattleController.enemies 陣列化、state["enemies"] / state["active_enemy_index"]
- AOE effect kinds：damage_all / poison_all / weak_all / vulnerable_all
- 召喚機制：EnemyData.summon_pool、effect kind "summon"、spawn_enemy() 上限 3 敵
- 每敵獨立 phase 2、action_index、attack 順序
- UI：水平 enemy row、portrait 點擊切 active、drag 個別命中、active 高亮其他半暗、死敵變灰
- 5 個新召喚物 placeholder：水妖觸手（拜月教主可召喚）
- 9 個新 smoke test 覆蓋（multi enemy setup / damage routing / AOE / partial kill / summon basic+cap+unknown+from_pool / per-enemy phase）

### 角色等級系統（PAL1 對齊）
- 每角色 Lv 1-22 unlock 表（按 PAL1 招式等級 7/11/15/20/24/26/30/34 壓縮對應 game Lv）
- 8 個 lxy unlock、8 個 zhao、6 個 lin、6 個 anu
- 等級驗證 baseline：Lv5/10/15/20 各對應幕 boss 勝率（_test_balance_leveled_progression）

### 主控制器重構（Phase 1 起手，未完成）
- Screen 基底類別 + BestiaryScreen 已抽出
- main.gd 仍 **5237 行**，剩 ~8 個 screen 待抽（main_menu / character_select / progress_screen / battle_scene 等）

### 測試
smoke_test.gd 共 **78 個測試**，涵蓋：
資料完整性、戰鬥機制、多回合流程、存檔 round-trip、存檔遷移、
地圖可達性、傷害預測一致性、隊伍系統、圖鑑、難度、Boss 二階段、
事件多樣性、種子確定性、平衡 regression（基礎 + 中段 + 升級版）、
多敵人 (multi-enemy setup / damage routing / AOE / partial kill /
summon basic+cap+unknown+from_pool / per-enemy phase)、阿奴 multi-enemy passive、
Event Branching（event_runner tree walk ×7 / observe_token ×3 / curse ×6）

### UI 質感 / 動畫精修
- **螢幕間 crossfade**：所有 `show_*()` 切換時自動截舊畫面 → 透明 overlay → tween fade-in (0.22s sine)，零侵入式設計
- **地圖節點呼吸動畫**：當前可選層所有節點 scale 1.0↔1.10 緩動，boss ×1.15；移除依狀態變色的 border（改靠 modulate + 之後要替換的 selected/unselected 圖檔表達）
- **持久 TitleBar**：頂部固定列顯示角色 + HP + 銅錢 + 遺物按鈕（main_menu 以外）
- **戰鬥背景分幕**：5 幕各自 battle_bg_act_1 ~ 5 圖
- **手感修正集（Android 觸控）**：
  - 地圖整片可滑（map_area 設 MOUSE_FILTER_IGNORE，避免左半邊吞觸控）
  - 卡片拖拉敵將命中範圍：桌面 80 px、手機 160 px
  - 拖卡時鄰近卡的 hover 自動鎖住（避免抖動）
  - 卡片拖拉統一桌面 + 手機路徑
- **角色立繪去背**：portraits/ 4 張 + battle_characters/ 24 張（3 角色 × 6 姿勢 + 阿奴手動）+ enemies/ 19 張全部透明背景
- **奇遇事件插圖**：31/31 全部完成（每個 variant 各自獨立背景）
- **遺物美術**：56 張 ink-wash 風格遺物圖
- **卡片框美術**：attack / power / skill 各自獨立框型升級（原圖備份在 _card_frame_backup/）

---

## 待辦 / 下一步

### 未開始（Multi-Enemy Mode 後續 phases）
> Phase 1–4A 已完成（核心 multi-enemy 戰鬥流程 + 召喚機制）；4B 以後尚未動工。

- [ ] **Phase 4B：戰鬥手感 polish**（~170 行）
  - 召喚物 fade-in tween（scale 0.7→1.0、alpha 0→1，0.4s）
  - 敵人死亡淡出（alpha + 灰階）
  - AOE 卡視覺：3 敵同步 flash + shake
  - AOE 卡飛行：飛到 row 中央而非單一敵
  - Damage popup spawn 在正確敵 portrait（不只 active）
  - Compact mode 自動觸發（3 敵時強制 compact）
- [ ] **Phase 5+8：內容**（~230 行）
  - MapGenerator encounter 表（act 2+ 加雙弱敵 combos）— 0/N 加入
  - 4 個新弱版 EnemyData：山賊小弟 / 妖獸幼獸 / 蠱毒徒弟 / 拜月小卒 — **0/4 已加**
  - 4 個召喚物：red_eye_imp / tower_wisp / centipede_brood / zombie_thrall（每 boss 至少 1 種）— **1/5 已加**（只有 water_tentacle）
  - 6 張卡用 `*_all` 改造：萬劍訣 / 御蜂術 / 九龍訣 / 萬蠱蝕天 / 旋風咒 / 乾坤一擲 — **3 次 damage_all 出現在 game_data**，需逐張驗證
- [ ] **Phase 6+7：測試 + baseline**（~250 行）
  - balance_matrix 加多敵 scenarios（act 2+ 雙弱敵 vs 4 chars）
  - smoke test 加 AOE 卡命中所有敵測試
  - 更新 BALANCE_BASELINES 含多敵情境

### 進行中（Event Branching — 奇遇分支故事化）
> **核心框架已完成**：13/31 事件已轉成分支故事樹，curse / observe token / 戰鬥回流都上線。
詳見 [`docs/EVENT_BRANCHING.md`](docs/EVENT_BRANCHING.md)。
- [x] **P1 Schema + Runner** — `event_runner.gd`（191 行）tree walker、requires 過濾、UI 徽章（`e0e4ee0`）
- [x] **P2 Event UI 改版** — `show_event_node()` 多層樹走訪 + 葉節點 resolver（`ec781b7`）
- [x] **P3 戰鬥回流** — 事件戰鬥敗不直接 game over（`01b78a7`）
- [x] **P4 Curse 牌系統** — `curse_catalog.gd` 6 張 curse + 滯留結算（`3764adc`）
- [x] **P5 observe Token** — `RunState.observe_tokens` + `next_battle_buffs`（`ef41450`）
- [~] **P6 新 effect kinds** — permanent_power / next_battle_buff / gain_relic_pool / gain_card_pool / gain_curse 已做；**`act_modifier` 仍未實作**（main.gd:3667 push_warning）
- [x] **P7 內容 A（Batch A 6 事件）** — `99ff292`
- [x] **P8 內容 B（Batch B 6 事件含戰鬥）** — `c43a306`（8 條 battle 葉節點）
- [ ] **P9 內容 C（剩餘 18 事件轉 tree）** — 目前走 legacy 扁平 fallback
- [ ] **P10 戰鬥用敵人**（event-only enemies）— Batch B 暫借既有敵人
- [~] **P11 Smoke tests** — 17 個事件相關測試已上（event_runner ×7 / observe ×3 / curse ×6 / variety ×1）

剩餘缺口：`act_modifier` effect kind、P9 的 18 個事件轉 tree、P10 專屬敵人。

### 高優先（影響玩法完整度）
- [x] **Boss 專屬神器** — 5 act boss + moon_worshipper 共 6 神器全做完
- [x] **平衡 regression baseline 更新** — 已含 leveled progression + multi-enemy 配套
- [x] **更多 PAL1 事件** — 已擴至 31 種（含 4 名場面 + 觀察/離開機制）
- [x] **奇遇事件插圖 (Event Art)** — 31/31 完成
- [x] **角色立繪去背** — portraits / battle_characters / enemies 三個資料夾全部透明背景
- [x] **遺物美術完整集** — 59/59 遺物圖到位（補上 16 張原本缺圖的通用遺物 art）
- [x] **PAL1 starter 卡片美術** — `ef064ac` 補上起始牌組專屬 art
- [ ] **Card Art 補完** — 60 張卡片 PNG 已有，部分新卡仍用 art_id 借既有圖

### 中優先（體驗提升）
- [x] **Act title 顯示在地圖** — 已實作
- [x] **銅錢差異化** — 已實作
- [x] **牌組視圖** — 已實作
- [x] **卡片出牌動畫** — 已實作（根據 effect 自動判斷飛向）
- [x] **戰鬥手感反饋** — HP bar tween / 能量珠 pulse / 狀態浮字 / 重擊震動 / Block pulse 已實作
- [ ] **main.gd Phase 1 重構繼續** — Bestiary 已抽出（68 行），剩餘 ~8 個 screen 待抽（main_menu / character_select / progress_screen / event_node / shop_node / battle_scene / deck_view / result）
- [ ] **音效（SFX）** — bus 與音量設定已就緒，**0 個音檔**。需 4-8 個 SFX（打牌、命中、治療、被打、end turn、勝利、boss 變身、召喚）

### 低優先（長期）
- [ ] **第六幕 epilogue / 後日談** — 通關後可選地圖？
- [ ] **更多角色** — 酒劍仙？唐鈺？（PAL1 事件中已 cameo）
- [ ] **排行榜 / 統計** — Run 時長、最高幕、常用卡片
- [ ] **音樂 / BGM** — PAL1 BGM 授權研究
- [ ] **卡片升級獨立描述** — 目前用演算法自動改數字，理想是手寫升級文本
- [ ] **多人連線** — 超出原型範疇，待定
- [ ] **多敵 boss 同場戰**（2 boss 同時） — Multi-Enemy Phase 5 之後再說
- [ ] **玩家「召喚」卡**（如召喚劍靈助戰） — 需新 effect kind `summon_ally`

### Pre-existing smoke test 警告（不擋 CI，但該修）
- [x] `upgraded revive description should contain 38` — revive 卡升級描述生成有 bug
- [x] `_test_potion_use_heal` / `_test_potion_cure_poison` 的 `Attempted to free a RefCounted object` 錯誤 — 兩個 potion 測試的測試碼有 leak


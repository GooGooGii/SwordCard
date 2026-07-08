# 戰鬥輸入體驗與周邊系統 — Implementation Reference

> 2026-07-08 自 CLAUDE.md「戰鬥輸入體驗」一節抽出，原文完整保留。全部已實作。
> 改這些系統時更新這份文件；CLAUDE.md 只留一行摘要與路由，不要把本文貼回去。

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
  **20 級 cumulative，對齊 Slay the Spire**（A1 精英更常出現 / A2-4 一般・精英・Boss 傷害+10% /
  A5 Boss戰後回血少 / A6 起始HP-10% / A7-9 一般・精英・Boss HP+25% / A10 起手詛咒 / A11 藥格-1 /
  A12 升級卡機率減半 / A13 Boss金-25% / A14 最大HP-5 / A15 奇遇更糟 / A16 商店漲價 / A17-19 一般・精英・Boss
  招式更刁 / A20 雙Boss）。完成 A_N 的 run 後 `Ascension.mark_cleared(N)` 解鎖 A_(N+1)。
  層級存 `RunState.ascension_level`，舊存檔 default 0。tier 字串 `normal/elite/boss`。
  - 敵人 HP：`start_next_battle`/`_start_battle` 套 `enemy_hp_multiplier(lvl, is_boss, is_elite)`
  - 敵人傷害：戰鬥 state `enemy_damage_mult`（EffectResolver from_enemy 路徑讀取）
  - 精英：`MapGenerator._inject_elite`（A1 提頻）+ `GameData.elites_for_act` + 戰鬥 `is_elite` 旗標
  - 其餘：起始HP/maxHP（start_run）、boss回血（show_act_complete）、詛咒（start_run 加 CurseCatalog）、
    藥格（`RunState.effective_potion_slots`）、boss金（`boss_gold_multiplier`）、奇遇（`_ascension_event_amount`/
    harness `_apply_event_effects`）、商店（`_shop_apply_discount`×price_mult）、升級卡（`reward_upgrade_chance`）、
    招式（`_action_for_enemy` 改挑最高傷招）、雙boss（戰鬥 setup 加第二 boss）
  改 modifier 數值記得更新 `Ascension.describe()`；精英節點 icon `assets/ui/node_elite.png` 已補上。
- **Boss phase**：`EnemyData.phase_2_actions` 是可選的第二招式組。`BattleController._check_phase_transition()`
  在 `play_card` 結算傷害後檢查，HP * 2 < max_hp 時 `phased = true`、`action_index` 歸零、log 提示。
  `next_enemy_action` 會在 phased 後改抽 phase_2_actions。多個 boss 配有對應的 phase 2 招式。
  舊存檔的 EnemyData 沒這欄位也不會 crash（`from_dict` 用 `data.get("phase_2_actions", [])`）
- **Boss 接續（`EnemyData.successor`）**：隱龍窟雙妖正史——蛇妖男（`red_eye_demon`）死亡時
  滿血召出狐妖女（`fox_demon`）接續打，**不是同隻半血變身**（與 phase_2 互斥）。
  `BattleController._check_successors()` 在 play_card / start_turn 傷害結算後檢查（搶在 is_victory 前），
  死敵 slot 標 `successor_done` 確保只接續一次；接續者 `spawn_enemy(id, false)` 非召喚物、照常掉落。
  蛇屍保留為 corpse（死敵保留版位邏輯），狐妖女在其右側登場，兩隻都倒才算勝。
- **種子分享 / 每日挑戰**：主選單除了「開始遊戲」（隨機 seed），還有「每日挑戰」（用今天日期 hash）和「輸入種子」（彈窗 LineEdit，任意字串 hash 成 int）。
  `start_run` 流程：`seed(pending_seed if non-zero else randi())` → `_make_encounter_choices()` → `randomize()` 恢復隨機。
  Seed 存在 `RunState.map_seed`，progress screen 顯示在難度 A_N 旁邊方便截圖分享。
  Smoke test 驗證同 seed 兩次 generate 結構一致

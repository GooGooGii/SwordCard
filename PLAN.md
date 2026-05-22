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

### 事件系統（19 種 variant）
shrine、spring、talisman_cache、treasure_chest、ancestor_relic、wandering_sage、
moonlit_pool、broken_temple、yokai_pact（契約降 max_hp 換 power）、
forgotten_altar、ancient_battlefield、alchemy_furnace、ghost_forest（50/50 賭注）、
immortal_ruins、spirit_clan_ruins、baiyue_altar（tainted_power：必中 power + 固定反噬）、
tavern_acquaintance、sword_tomb、miao_healer

每種事件有獨立選項組（heal / power / gain_card / upgrade / remove / view_deck / pact / gamble / tainted_power）
選擇後顯示結果 overlay（含劇情文字）

### 遺物系統（56 件）
- 稀有度：basic、uncommon、rare、legendary、artifact（Boss 特定掉落）
- 效果種類：永久 buff（傷害/HP/draw）、觸發型（戰鬥開始/每回合/擊殺/勝利）
- Boss 擊敗必掉對應神器；無對應神器時隨機掉落；一般戰鬥 25% 機率掉落
- 戰鬥中「遺物 (N)」按鈕查看說明 popup

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
- DamagePopup 浮動數字（傷害/治療/護體）
- 角色切換肖像動畫漸變
- F1 開發者選單（+金幣 / 滿血 / 加卡 / 加遺物 / 跳 Boss）
- 暫停選單（Esc / 實體返回鍵 / 螢幕按鈕）
- Android Safe Area 適配、觸控友善

### 測試
smoke_test.gd 共 32 個測試，涵蓋：
資料完整性、戰鬥機制、多回合流程、存檔 round-trip、存檔遷移、
地圖可達性、傷害預測一致性、隊伍系統、圖鑑、難度、Boss 二階段、
事件多樣性、種子確定性、平衡 regression（基礎 + 中段 + 升級版）

---

## 待辦 / 下一步

### 高優先（影響玩法完整度）
- [x] **Boss 專屬神器** — 赤眼山魈、殭屍大帥、拜月教主已補上專屬的神物遺物，並設定於擊敗後必掉。
- [x] **平衡 regression baseline 更新** — 跑 CI 並更新了 smoke test 中的勝率基準。
- [x] **更多 PAL1 事件** — 已補足至 24 種經典奇遇事件（含十里坡、醉酒劍仙、隱龍窟、揚州緝盜、水月宮等）。

### 中優先（體驗提升）
- [x] **Act title 顯示在地圖** — 地圖上方顯示當前幕名稱（余杭山間…）
- [x] **銅錢差異化** — 各幕 Boss 掉落銅錢量隨幕數提升
- [ ] **牌組視圖** — 分組顯示重複卡；戰鬥中顯示抽/手/棄/消耗堆
- [ ] **卡片出牌動畫** — 從手牌區飛向敵人的簡單 tween
- [ ] **Card Art / 肖像** — 四角色、各幕敵人的正式圖檔（**強制去背/透明背景**，目前為佔位符）
- [ ] **奇遇事件插圖 (Event Art)** — 為各經典奇遇事件補上專屬的劇情背景插畫，以提昇劇情沉浸感（目前使用通用 `event_bg.png` 佔位）。


### 低優先（長期）
- [ ] **第六幕 epilogue / 後日談** — 通關後可選地圖？
- [ ] **更多角色** — 酒劍仙？唐鈺？
- [ ] **排行榜 / 統計** — Run 時長、最高幕、常用卡片
- [ ] **音效 / 音樂** — PAL1 BGM 授權研究
- [ ] **卡片升級獨立描述** — 目前用演算法自動改數字，理想是手寫升級文本
- [ ] **多人連線** — 超出原型範疇，待定

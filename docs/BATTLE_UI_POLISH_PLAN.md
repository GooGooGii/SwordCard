# 戰鬥畫面優化方案（對標 StS 手機版，2026-06-11）

> **執行狀態：Phase A–D 全部完成（2026-06-11，commits b9cee1c / 730c980 / 875599d）。**
> 驗證探針 `render_battle_ui.gd` 已入庫（1敵/3敵+飄浮+16遺物 情境）。
> 唯一未結項：`jumping_frog` 跳跳蛙肖像重生成（美術側，ART_TODO §14 A-2）。

> 依據：StS 手機版戰鬥截圖 vs 本作戰鬥截圖逐項比對。
> 核心結論：本作的背景與立繪**素材品質不輸**，輸在五個「戰場語法」——
> **接地（grounding）、資訊貼身（info proximity）、圖示化（iconification）、
> 視覺收攏（composition）、控制件角落化（corner chrome）**。
> 全部可程式層解決，**不需要新美術**（僅 1 張肖像待排查）。

## 0. 差距總表

| # | 維度 | StS 做法 | 本作現況 | 病徵 |
|---|---|---|---|---|
| 1 | 接地 | 所有單位站同一條地平線、腳下有橢圓陰影 | 敵人懸浮、高度不一（跳跳蛙飄半空）、無影子 | 角色像「貼紙」浮在背景上 |
| 2 | HP 條 | 緊貼角色腳下、寬=角色身寬 | 在名字下方、與 portrait 隔一段、寬=整欄 | 血條跟角色「分家」 |
| 3 | 意圖 | 頭頂大 icon＋大數字（1x6） | 16px icon＋10px 招式名文字（「巨鉗剪切 實受13」） | 一眼掃不到威脅量 |
| 4 | 狀態 | 角色腳下橫排 icon＋數字 | 直書文字三行（蠱毒 2／虛弱 1／破綻 1） | 吃豎向空間、讀字不讀圖 |
| 5 | 構圖 | 玩家佔高 ~40%、敵我間距小、重心置中 | 玩家貼左、敵群貼右、中央大片空（王座） | 對峙感弱、畫面散 |
| 6 | 頂欄 | 數字式 ❤55/80，一排輕量 | 超寬 HP 紅條（與玩家身上的血條重複） | 同資訊出現兩次 |
| 7 | 遺物 | 左上單排小圖 | 22+3 顆兩排**置中**浮在場景上 | 視覺噪音、壓住背景精華區 |
| 8 | 手牌 | 大弧度扇形、重疊、卡圖佔比高 | 近乎平排、白底卡在暗場景中過亮 | 手牌存在感過強、搶走戰場焦點 |
| 9 | 牌堆/按鈕 | 左右下角圓形 icon＋角標數字 | 「抽牌堆(17)／棄牌堆(0)／消耗堆(0)」灰色寬按鈕 | 工具列感，不像遊戲 chrome |

---

## Phase A — 接地與構圖（性價比最高，先做）

### A1. 腳底陰影
- `ui_factory.gd` 新增 `static func ground_shadow(width: float) -> Control`：
  程式畫橢圓（`draw_ellipse` 沒有內建 → 用 `draw_circle` + scale transform 或 64 段 polygon），
  黑色 alpha 0.30、寬 = portrait 視覺寬 ×0.55、高 = 寬 ×0.22。
- 掛點：`main.gd:_build_single_enemy_widget()` 的 `wrap`（portrait 之下 z 序）與玩家 portrait wrap 同位置。
- 死敵 fade 時陰影同步淡出（跟 portrait 同一個 modulate 父節點即可）。

### A2. 統一地平線
- `UIFactory.ground_portrait()` 已做「底部對齊」，但各敵的視覺 box（`ground_box` meta）因
  `portrait_scale` 與圖內留白不一，導致腳底高度不齊（截圖中跳跳蛙整隻飄起）。
- 處置：① 逐敵檢查 `portrait_scale`（`game_data.gd`）讓視覺腳底落差 ≤ 8px；
  ② 飄浮系（鬼火/劍靈/跳跳蛙跳躍格）給 `EnemyData.floats: bool = true`——
  允許懸浮 +16px，但**陰影留在地面**且縮小 70%（StS 飄浮敵同款語法）。

### A3. 敵我收攏 + 佔比
- `_enemy_portrait_size_for()`：3 敵 scale `0.62 → 0.72`、2 敵 `0.78 → 0.85`（A1 陰影＋A4 資訊帶
  收緊豎向空間後放得下）。
- enemy row 與 player 區的外側 margin 各收 5%：玩家中心 x ~18%→23%，敵群中心 ~80%→72%。
- 戰場底線（角色腳底）統一抬到畫面高度 ~64% 處，讓腳下資訊帶（HP/狀態）不與手牌爭空間。

### A4. 跳跳蛙肖像排查
- 截圖中 `jumping_frog` 顯示為**藍色龍形水紋**，與「跳跳蛙」名實不符。
  查 `game_data.gd` 的 portrait_path 是否借錯圖／AI 圖跑掉；確認後登 ART_TODO 重生成（唯一可能的美術項）。

## Phase B — 敵人資訊帶（讀秒內看懂威脅）

對 `_build_single_enemy_widget()` 的 col 結構重排：`意圖(大) → portrait(+陰影+block) → HP條(貼身) → 狀態chips`。

### B1. 意圖大字化
- icon：`icon_px 16/22 → 26/32`；只顯示主 icon（最多 2 顆，現在保留 3 槽）。
- **傷害數字獨立大label**：「實受 N」從 10px 文字升級為 **20px 粗體紅字**直接跟在 icon 右側
  （`預測傷害 ×段數` 用 StS 語法：`13` 或 `8×2`）；buff/debuff 意圖則顯示層數。
- 招式名（「巨鉗剪切」）從常駐顯示**移除**，移到點擊敵人 portrait 的既有 popup／hover tooltip。
  `CardFormat.intent_badge` 文字 fallback 保留給 icon 缺圖時。

### B2. HP 條貼身
- HP bar 從 col 流式位置改掛進 `wrap`（portrait 底部 overlay）：寬 = portrait 寬 ×0.9、高 12px、
  底邊對齊地平線 +4px；數字 `67/70` 12px 疊條上。
- name label 縮 1 級移到 HP 條上方緊貼（或頭頂意圖下方），不再單獨佔一行。
- `BlockBadge` 從 portrait 左下移到 **HP 條左端外側**（StS 位置），數字與 HP 同行可讀。

### B3. 狀態 chips（取代直書文字）
- `ui_factory.gd` 新增 `static func status_chip(kind: String, value: int) -> Control`：
  20px 圓底色塊＋符號＋右下角數字。配色：蠱毒=墨綠●、虛弱=靛藍▼、破綻=赭橘◆、
  暈眩=紫★、攻擊增益=金▲（純程式繪製，不需圖檔；日後想換圖在 chip 裡換 TextureRect 即可）。
- 敵/玩家共用：橫排 HBox 在 HP 條下方，超過 5 顆換行。
- 玩家側「攻擊 +23」同步 chips 化（金▲23）。
- `_refresh_enemy_widgets()`／`_refresh_battle()` 改餵 chips 而非 status_line 文字。

## Phase C — 頂欄與遺物帶（還畫面給戰場）

### C1. 頂欄精簡
- 戰鬥中頂欄的超寬 HP 紅條改為**數字式**：`❤ 84/84`（紅心符號＋數字，14px），
  與 Lv／銅錢／觀察同行等距。玩家身上的血條成為唯一血條。
- 釋出的寬度給 C2 遺物帶。

### C2. 遺物帶左對齊 + 摺疊
- 兩排置中 → **單排左對齊**緊貼頂欄下緣：icon 30px、間距 4、底加半透明墨帶（黑 alpha 0.25、高 38px）。
- 最多顯示 12 顆，多的收進「+N」鈕 → 點開既有的遺物清單 PopupPanel（left_dock 那顆「遺物 (22)」按鈕可順勢移除，功能合併到 +N）。
- 新獲得遺物時該 icon flash 一次（`UIFactory.flash_node` 現成）。

## Phase D — 手牌與控制件

### D1. 手牌扇形強化
- `hand_fan.gd`：`ANGLE_PER_CARD_DEG 4.0 → 5.5`、`MAX_TOTAL_ANGLE_DEG 28 → 34`、
  `ARC_RADIUS 1600 → 1250`（弧度更明顯、卡片重疊 ~25%）。HOVER 行為不動。
- 卡尺寸 `140×262 → 152×284`（A3 收攏空出的寬度；compact 同比例）。
- **暗場景對比**：卡按鈕 StyleBox 加 1px 深色外框（`Color("17110a", 0.9)`）＋ shadow_size 6
  ——白卡在暗背景的「過亮貼紙感」靠陰影層收掉，卡套美術不動。

### D2. 牌堆角落化
- 「抽牌堆(17)／棄牌堆(0)／消耗堆(0)」三顆灰按鈕 → 左下/右下**圓形 icon＋角標數字**
  （40px 圓底、卡背符號 🂠 程式字繪、右上角數字 badge）。點擊行為不變（開既有 pile view）。
- 消耗堆平時隱藏，>0 才出現在棄牌堆上方（StS 同款）。
- 能量珠 `3/3` 放大 10%，靈力不足時珠體去飽和。

---

## 驗證與順序

1. 每個 Phase 完成後：`godot --path . -s render_effects.gd` 模式截 1280×720 ＋ 手機 compact 兩張，
   與本文件對應的截圖肉眼比對（CLAUDE.md 既定流程）。
2. 多敵（3 敵）、boss（portrait_scale>1）、召喚加入、phase 2 換圖四種情境都要截。
3. smoke test 全綠（widget 結構改動會影響 `_refresh_*` 路徑，注意 `enemy_widgets` dict key 不要改名）。
4. 建議順序 **A → B → C → D**：A 是「貼紙感」的根治，B 是可玩性（威脅可讀），C/D 是質感收尾。

## 美術需求

- **無新增**（陰影/chips/圓鈕全程式繪製）。
- 唯一待排查：`jumping_frog` 跳跳蛙肖像名實不符（A4），確認後若需重生成登 ART_TODO §14。

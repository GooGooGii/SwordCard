# Slay the Spire 遺物完整參考表（v2.x 正式版，共 180 件）

> 用途：SwordCard 遺物系統的設計參考資料。收錄 STS 全部遺物的效果、價格、稀有度、取得條件與機制分類。
> 來源：slaythespire.wiki.gg / slay-the-spire.fandom.com（MediaWiki API），2026-07-08 逐稀有度核實，非憑記憶。
> 設計應用分析在文末「對 SwordCard 的設計應用」一節。

## 總覽

| 稀有度 | 件數 | 商店基準價（gold） | 主要取得管道 |
|---|---|---|---|
| Starter | 4 | 不販售 | 四角色開局自帶 |
| Common | 36 | 150（143–157） | 寶箱/菁英/Boss獎勵/商店/事件 |
| Uncommon | 36 | 250（238–263） | 同上 |
| Rare | 34 | 300（285–315） | 同上 |
| Boss | 30 | 不販售 | 幕1/幕2 Boss 戰後三選一 |
| Shop | 20 | 150（143–158） | 只在商店（最右格保底 1 件） |
| Event | 18 | 不販售 | 特定事件 |
| Special | 2 | 不販售 | 遺物池抽空替補（Circlet） |
| **合計** | **180** | | |

價格規則：**價格完全由稀有度決定，個別遺物不另定價**；±5% 浮動，Ascension 16+ 全店 +10%。The Courier 全店 -20%、Membership Card -50%，可疊乘。
獎勵抽取稀有度機率：Common 50% / Uncommon 33% / Rare 17%（寶箱 49%/42%/9%）。
角色限定遺物分布：每角 Common 1、Uncommon 2、Rare 1–3、Boss 2–3（含起始遺物升級版各 1）、Shop 1。

---
## Slay the Spire 特殊稀有度遺物完整參考表（Starter / Shop / Event / Special）

資料來源：slaythespire.wiki.gg（Relics List、Merchant、各遺物與事件子頁），2026-07-08 逐頁核實。
fandom wiki 被 Cloudflare 擋（HTTP 402），改用 wiki.gg（同社群維護、內容同步 v2.x 正式版）。

### 商店價格通則（Merchant 頁核實）

- 商店固定販售 3 件遺物，最右格必為 Shop 稀有度遺物
- 基礎價格（±5% 浮動）：**Shop 與 Common 143–158 金**、Uncommon 238–263 金、Rare 285–315 金；Ascension 16 起全部 ×1.1
- Membership Card 全店 5 折；與 The Courier 疊加為 0.5×0.8=原價 40%
- Starter / Event / Special 遺物一律不販售

---

### 一、Starter 起始遺物（4 件）

| 英文名稱 | 稀有度 | 角色限定 | 商店價格 | 效果全文（繁中） | 取得方式 | 機制標籤 |
|---|---|---|---|---|---|---|
| Burning Blood | Starter | Ironclad | 不販售 | 每場戰鬥結束時，回復 6 點 HP。 | Ironclad 開局自帶（Boss 遺物可換掉） | 治療、戰後結算 |
| Ring of the Snake | Starter | Silent | 不販售 | 每場戰鬥開始時，額外抽 2 張牌。 | Silent 開局自帶 | 抽牌、開戰觸發 |
| Cracked Core | Starter | Defect | 不販售 | 每場戰鬥開始時，充能 1 個閃電球。 | Defect 開局自帶 | 充能球、開戰觸發 |
| Pure Water | Starter | Watcher | 不販售 | 每場戰鬥開始時，將 1 張「奇蹟（Miracle）」加入手牌。 | Watcher 開局自帶 | 生成卡牌、開戰觸發 |

---

### 二、Shop 商店限定遺物（20 件；16 通用 + 4 角色限定）

價格皆為基礎 143–158 金（見上方通則），下表價格欄統一標「143–158」。

| 英文名稱 | 稀有度 | 角色限定 | 商店價格 | 效果全文（繁中） | 取得方式 | 機制標籤 |
|---|---|---|---|---|---|---|
| Cauldron | Shop | 通用 | 143–158 | 取得時，立即熬煮 5 瓶隨機藥水。 | 僅商店購買 | 藥水、一次性 |
| Chemical X | Shop | 通用 | 143–158 | 你的 X 費卡牌效果視為 X+2。 | 僅商店購買 | X費強化、被動 |
| Clockwork Souvenir | Shop | 通用 | 143–158 | 每場戰鬥開始時，獲得 1 層人工（Artifact）。 | 僅商店購買 | 防debuff、開戰觸發 |
| Dolly's Mirror | Shop | 通用 | 143–158 | 取得時，複製你牌組中的 1 張卡牌。 | 僅商店購買 | 複製卡牌、一次性 |
| Frozen Eye | Shop | 通用 | 143–158 | 檢視抽牌堆時，卡牌按實際順序顯示。 | 僅商店購買 | 資訊、被動 |
| Hand Drill | Shop | 通用 | 143–158 | 每當你打破敵人的格擋時，施加 2 層易傷。 | 僅商店購買 | debuff、破甲觸發 |
| Lee's Waffle | Shop | 通用 | 143–158 | 取得時，最大 HP +7 並回復全部 HP。 | 僅商店購買 | 最大HP、一次性 |
| Medical Kit | Shop | 通用 | 143–158 | 不可打出的狀態卡變為可打出；打出狀態卡時將其消耗。 | 僅商店購買 | 狀態卡處理、被動 |
| Membership Card | Shop | 通用 | 143–158 | 商店全部商品 5 折！ | 僅商店購買 | 經濟、被動 |
| Orange Pellets | Shop | 通用 | 143–158 | 每當你在同一回合內打出能力、攻擊、技能各 1 張時，移除你身上所有 debuff。 | 僅商店購買 | 淨化、組合觸發 |
| Orrery | Shop | 通用 | 143–158 | 取得時，選擇 5 張卡牌加入你的牌組（5 次三選一）。 | 僅商店購買 | 選卡、一次性 |
| Prismatic Shard | Shop | 通用 | 143–158 | 戰鬥獎勵可出現無色卡與其他角色顏色的卡牌。 | 僅商店購買 | 卡池擴充、被動 |
| Sling of Courage | Shop | 通用 | 143–158 | 每場精英戰開始時，獲得 2 點力量。 | 僅商店購買 | 力量、精英戰觸發 |
| Strange Spoon | Shop | 通用 | 143–158 | 打出會消耗的卡牌時，有 50% 機率改為棄置而非消耗。 | 僅商店購買 | 消耗改棄、被動 |
| The Abacus | Shop | 通用 | 143–158 | 每當你洗牌（抽牌堆重洗）時，獲得 6 點格擋。 | 僅商店購買 | 格擋、洗牌觸發 |
| Toolbox | Shop | 通用 | 143–158 | 每場戰鬥開始時，從 3 張隨機無色卡中選 1 張加入手牌。 | 僅商店購買 | 生成卡牌、開戰觸發 |
| Brimstone | Shop | Ironclad | 143–158 | 你的回合開始時，你獲得 2 點力量，所有敵人獲得 1 點力量。 | 僅商店購買 | 力量、雙面代價 |
| Twisted Funnel | Shop | Silent | 143–158 | 每場戰鬥開始時，對所有敵人施加 4 層中毒。 | 僅商店購買 | 中毒、開戰觸發 |
| Runic Capacitor | Shop | Defect | 143–158 | 每場戰鬥開始時，額外獲得 3 個充能球欄位。 | 僅商店購買 | 球欄位、開戰觸發 |
| Melange | Shop | Watcher | 143–158 | 每當你洗牌時，預見（Scry）3。 | 僅商店購買 | 預見、洗牌觸發 |

---

### 三、Event 事件限定遺物（18 件）

| 英文名稱 | 稀有度 | 角色限定 | 商店價格 | 效果全文（繁中） | 取得方式/來源事件 | 機制標籤 |
|---|---|---|---|---|---|---|
| Neow's Lament | Event | 通用 | 不販售 | 你最初 3 場戰鬥的敵人 HP 變為 1。 | 開局 Neow 第二祝福；上一輪同角色未達第一幕 Boss 時必為選項之一 | 開局加速、限次 |
| Golden Idol | Event | 通用 | 不販售 | 敵人掉落的金幣增加 25%。 | 第一幕「Golden Idol」事件選 [Take]，再擇 [Outrun]/[Smash]/[Hide] 承擔代價 | 經濟、被動 |
| Bloody Idol | Event | 通用 | 不販售 | 每當你獲得金幣時，回復 5 點 HP。 | 「Forgotten Altar」事件選 [Offer: Golden Idol]（須先持有 Golden Idol） | 治療、金幣觸發 |
| Enchiridion | Event | 通用 | 不販售 | 每場戰鬥開始時，將 1 張隨機能力卡加入手牌，該回合費用為 0。 | 第二幕「Cursed Tome」事件讀完取書（三書隨機其一），共損 16 HP | 生成卡牌、開戰觸發 |
| Necronomicon | Event | 通用 | 不販售 | 每回合第一張費用 ≥2 的攻擊卡打出兩次。取得時獲得特殊詛咒「Necronomicurse」（不可移除）。 | 第二幕「Cursed Tome」事件取書（三書隨機其一） | 連擊、附帶詛咒 |
| Nilry's Codex | Event | 通用 | 不販售 | 每回合結束時，可從 3 張隨機卡牌中選 1 張洗入抽牌堆。 | 第二幕「Cursed Tome」事件取書（三書隨機其一） | 生成卡牌、回合結束觸發 |
| Face of Cleric | Event | 通用 | 不販售 | 每場戰鬥結束時，最大 HP +1。 | 第一/二幕「Face Trader」事件選 [Trade]（好面具 40% 之一） | 最大HP、戰後結算 |
| Ssserpent Head | Event | 通用 | 不販售 | 每當你進入「?」房間時，獲得 50 金幣。 | 「Face Trader」事件選 [Trade]（好面具 40% 之一） | 經濟、地圖觸發 |
| Gremlin Visage | Event | 通用 | 不販售 | 每場戰鬥開始時，你帶有 1 層虛弱。 | 「Face Trader」事件選 [Trade]（壞面具 40% 之一） | 負面、開戰觸發 |
| N'loth's Hungry Face | Event | 通用 | 不販售 | 你打開的下一個非 Boss 寶箱是空的。 | 「Face Trader」事件選 [Trade]（壞面具 40% 之一） | 負面、一次性 |
| Cultist Headpiece | Event | 通用 | 不販售 | 「你覺得話變多了。」（純裝飾：戰鬥開始時角色喊「Caw!」，無實際數值效果） | 「Face Trader」事件選 [Trade]（中性面具 20%） | 純趣味、無效果 |
| Mark of the Bloom | Event | 通用 | 不販售 | 你不再能回復 HP。 | 第三幕「Mind Bloom」事件選 [I am Awake]（升級全部卡牌的代價） | 負面、禁治療 |
| Mutagenic Strength | Event | 通用 | 不販售 | 每場戰鬥開始時獲得 3 點力量，第一回合結束時失去 3 點力量。 | 「Augmenter」事件選 [Ingest Mutagens] | 力量、首回合爆發 |
| N'loth's Gift | Event | 通用 | 不販售 | 戰鬥獎勵出現稀有卡的機率變為 3 倍。 | 第二幕「N'loth」事件選 [Offer]，以自身 1 件遺物交換 | 稀有度提升、被動 |
| Odd Mushroom | Event | 通用 | 不販售 | 帶有易傷時，受到的攻擊傷害改為增加 25% 而非 50%。 | 第一幕「Hypnotizing Colored Mushrooms」事件選 [Stomp] 並擊敗 3 隻真菌獸 | 減傷、被動 |
| Red Mask | Event | 通用 | 不販售 | 每場戰鬥開始時，對所有敵人施加 1 層虛弱。 | 第二幕「Masked Bandits」選 [Fight] 獲勝；或第三幕「Tomb of Lord Red Mask」獻出全部金幣 | debuff、開戰觸發 |
| Spirit Poop | Event | 通用 | 不販售 | 「真令人不舒服。」（無遊戲內效果；結算分數 -1「Poopy」） | 「Bonfire Spirits」事件獻祭 1 張詛咒卡 | 純趣味、無效果 |
| Warped Tongs | Event | 通用 | 不販售 | 你的回合開始時，隨機升級手牌中 1 張卡牌（僅本場戰鬥有效）。 | 「Ominous Forge」事件選 [Rummage]（同時獲得詛咒「Pain」） | 臨時升級、回合開始觸發 |

---

### 四、Special 替補遺物（2 件）

| 英文名稱 | 稀有度 | 角色限定 | 商店價格 | 效果全文（繁中） | 取得方式 | 機制標籤 |
|---|---|---|---|---|---|---|
| Circlet | Special | 通用 | 不販售 | 「能收集多少就收集多少吧。」（無效果，可重複持有）提示語：「你把遺物拿光了，厲害！」 | 對應稀有度遺物池抽空後的替補遺物 | 替補、無效果 |
| Red Circlet | Special | 通用 | 不販售 | （無效果）原設計為 Boss 遺物池抽空後的替補 | 因邏輯 bug，正常遊戲中實際不可取得 | 替補、不可取得 |

---

#### 件數核對

- Starter：4（四角色各一）
- Shop：20（通用 16 + Ironclad/Silent/Defect/Watcher 各 1）
- Event：18
- Special：2（Circlet、Red Circlet）
- 合計 44 筆

---

## Slay the Spire — Common 遺物完整參考表（v2.x 正式版）

來源：slay-the-spire.fandom.com（`Relics` 頁 + `Merchant` 頁，2026-07-08 經 MediaWiki API 抓取核實）。

- **總數：36 件**（通用 32 件 + 角色限定 4 件：Ironclad/Silent/Defect/Watcher 各 1）。
- **商店價格**：wiki 未逐件標價；商店價由稀有度決定——Common 遺物一律 **143–157 gold**（基準 150，±5% 浮動；Ascension 16+ 全店 +10%）。下表價格欄統一填此區間。
- 取得來源：一般寶箱/菁英/Boss 獎勵/商店/事件，機率 Common:Uncommon:Rare ≈ 50%/33%/17%（寶箱 49%/42%/9%）。

| # | 英文名稱 | 稀有度 | 角色限定 | 商店價格 (gold) | 效果全文（繁中） | 取得限制/特殊條件 | 機制分類 |
|---|---|---|---|---|---|---|---|
| 1 | Akabeko | Common | 無 | 143–157 | 每場戰鬥你的第一次攻擊額外造成 8 點傷害。 | — | 戰鬥開場、攻擊強化 |
| 2 | Anchor | Common | 無 | 143–157 | 每場戰鬥開始時獲得 10 點格擋。 | — | 戰鬥開場、格擋 |
| 3 | Ancient Tea Set | Common | 無 | 143–157 | 每當你進入休息點，下一場戰鬥開始時獲得 2 點額外能量。 | 需先經過休息點才觸發 | 能量、地圖 |
| 4 | Art of War | Common | 無 | 143–157 | 如果你在你的回合中沒有打出任何攻擊牌，下回合獲得 1 點額外能量。 | — | 能量 |
| 5 | Bag of Marbles | Common | 無 | 143–157 | 每場戰鬥開始時，對所有敵人施加 1 層易傷。 | — | 戰鬥開場、debuff |
| 6 | Bag of Preparation | Common | 無 | 143–157 | 每場戰鬥開始時，額外抽 2 張牌。 | — | 戰鬥開場、抽牌 |
| 7 | Blood Vial | Common | 無 | 143–157 | 每場戰鬥開始時，回復 2 點 HP。 | — | 戰鬥開場、治療 |
| 8 | Bronze Scales | Common | 無 | 143–157 | 每當你受到傷害，反彈 3 點傷害。 | — | 反擊 |
| 9 | Centennial Puzzle | Common | 無 | 143–157 | 每場戰鬥中你第一次失去 HP 時，抽 3 張牌。 | — | 抽牌、受傷觸發 |
| 10 | Ceramic Fish | Common | 無 | 143–157 | 每當你將一張牌加入你的牌組，獲得 9 金幣。 | — | 金錢、卡牌操作 |
| 11 | Damaru | Common | Watcher | 143–157 | 在你的回合開始時，獲得 1 點真言（Mantra）。 | 僅 Watcher 的獎勵池出現 | 角色機制（真言）、回合觸發 |
| 12 | Data Disk | Common | Defect | 143–157 | 每場戰鬥開始時獲得 1 點集中（Focus）。 | 僅 Defect 的獎勵池出現 | 角色機制（集中）、戰鬥開場 |
| 13 | Dream Catcher | Common | 無 | 143–157 | 每當你休息時，可以將一張牌加入你的牌組（休息後出現選卡畫面）。 | — | 卡牌操作、地圖 |
| 14 | Happy Flower | Common | 無 | 143–157 | 每 3 回合獲得 1 點能量。 | — | 能量 |
| 15 | Juzu Bracelet | Common | 無 | 143–157 | 在「?」房間中不再遭遇普通敵人戰鬥。 | — | 地圖 |
| 16 | Lantern | Common | 無 | 143–157 | 每場戰鬥的第一回合獲得 1 點能量。 | — | 能量、戰鬥開場 |
| 17 | Maw Bank | Common | 無 | 143–157 | 每當你爬升一層樓，獲得 12 金幣。在商店消費任何金幣後永久失效。 | **不會在商店出現**（Weekly Patch 52 移除）；消費即失效 | 金錢、地圖 |
| 18 | Meal Ticket | Common | 無 | 143–157 | 每當你進入商店房間，回復 15 點 HP。 | — | 治療、地圖 |
| 19 | Nunchaku | Common | 無 | 143–157 | 每打出 10 張攻擊牌，獲得 1 點能量。 | — | 能量、攻擊觸發 |
| 20 | Oddly Smooth Stone | Common | 無 | 143–157 | 每場戰鬥開始時，獲得 1 點敏捷（Dexterity）。 | — | 格擋、戰鬥開場 |
| 21 | Omamori | Common | 無 | 143–157 | 抵銷你獲得的接下來 2 張詛咒牌。 | 2 次用完即失效（計數器） | 卡牌操作（防詛咒） |
| 22 | Orichalcum | Common | 無 | 143–157 | 如果你回合結束時沒有格擋，獲得 6 點格擋。 | — | 格擋 |
| 23 | Pen Nib | Common | 無 | 143–157 | 你打出的每第 10 張攻擊牌造成雙倍傷害。 | — | 攻擊強化 |
| 24 | Potion Belt | Common | 無 | 143–157 | 拾取時，獲得 2 個藥水欄位。 | 拾取即時生效（一次性） | 藥水 |
| 25 | Preserved Insect | Common | 無 | 143–157 | 菁英房間中的敵人 HP 減少 25%。 | — | 地圖、菁英戰 |
| 26 | Red Skull | Common | Ironclad | 143–157 | 當你的 HP 在 50% 或以下時，你獲得 3 點額外力量（Strength）。 | 僅 Ironclad 的獎勵池出現 | 攻擊強化、低血觸發 |
| 27 | Regal Pillow | Common | 無 | 143–157 | 休息時額外回復 15 點 HP。 | — | 治療、地圖 |
| 28 | Smiling Mask | Common | 無 | 143–157 | 商人的移除卡牌服務現在永遠只需 50 金幣。 | — | 金錢、卡牌操作 |
| 29 | Snecko Skull | Common | Silent | 143–157 | 每當你施加中毒（Poison），額外施加 1 層中毒。 | 僅 Silent 的獎勵池出現 | 角色機制（毒）、debuff |
| 30 | Strawberry | Common | 無 | 143–157 | 你的最大 HP 提升 7 點。 | 拾取即時生效（一次性） | 治療（上限） |
| 31 | The Boot | Common | 無 | 143–157 | 每當你將造成 4 點或更少的未格擋攻擊傷害時，提升為 5 點。 | — | 攻擊強化 |
| 32 | Tiny Chest | Common | 無 | 143–157 | 每第 4 個「?」房間變成寶箱房間。 | — | 地圖 |
| 33 | Toy Ornithopter | Common | 無 | 143–157 | 每當你使用一瓶藥水，回復 5 點 HP。 | — | 治療、藥水 |
| 34 | Vajra | Common | 無 | 143–157 | 每場戰鬥開始時，獲得 1 點力量（Strength）。 | — | 攻擊強化、戰鬥開場 |
| 35 | War Paint | Common | 無 | 143–157 | 拾取時，升級 2 張隨機技能牌。 | 拾取即時生效（一次性） | 升階 |
| 36 | Whetstone | Common | 無 | 143–157 | 拾取時，升級 2 張隨機攻擊牌。 | 拾取即時生效（一次性） | 升階 |

### 備註（設計參考）

- 角色限定 Common 各家恰 1 件，且都直接餵角色核心機制（Red Skull=力量/低血、Snecko Skull=毒、Data Disk=集中、Damaru=真言）——「Common 級角色遺物 = 小幅放大角色 archetype」是可借的 pattern。
- Common 池的設計語言：小額但穩定（+2 HP、+10 格擋、+1 力量）、一次性拾取效果（Strawberry/War Paint/Whetstone/Potion Belt）、與地圖節點互動（Regal Pillow/Meal Ticket/Tiny Chest/Juzu Bracelet/Maw Bank）。
- 價格全由稀有度決定（Common 150 基準），個別遺物不另定價——SwordCard 的 `relic_catalog.gd` 若要對齊可用同一原則。

---

## Slay the Spire — Uncommon 遺物完整參考表（36 件）

- 來源：slaythespire.wiki.gg（STS1 官方社群 wiki；fandom 鏡像對 WebFetch 回 402，改用 wiki.gg 核實）＋個別遺物子頁（Blue Candle / Bottled Flame / Bottled Tornado / Matryoshka）與 Merchant 價格頁。查核日：2026-07-08。
- **商店價格**：Uncommon 遺物統一為 **238–263 gold**（基準 250 ±5%；Ascension 16+ 漲為 261–289）。The Courier 全場 -20%、Membership Card -50%、兩者疊加 -60%。
- 效果全文為 wiki 原文之精確中譯，數字未改動。

| # | 英文名稱 | 稀有度 | 角色限定 | 商店價格 (gold) | 效果全文（繁中） | 取得限制 / 特殊條件 | 機制分類 |
|---|---|---|---|---|---|---|---|
| 1 | Blue Candle | Uncommon | 無 | 238–263 | 不可打出的詛咒牌現在可以打出。每當你打出一張詛咒牌，失去 1 HP 並將其消耗（Exhaust）。 | 無（wiki 明載無牌組前置條件） | 卡牌操作、詛咒 |
| 2 | Bottled Flame | Uncommon | 無 | 238–263 | 取得時選擇一張攻擊牌。每場戰鬥開始時，該牌會在你的起始手牌中。 | 牌組須含至少 1 張非初始攻擊牌才會出現；不會由 Calling Bell 給出 | 戰鬥開場、卡牌操作 |
| 3 | Bottled Lightning | Uncommon | 無 | 238–263 | 取得時選擇一張技能牌。每場戰鬥開始時，該牌會在你的起始手牌中。 | 牌組須含至少 1 張非初始技能牌才會出現（同 Bottled 系列規則） | 戰鬥開場、卡牌操作 |
| 4 | Bottled Tornado | Uncommon | 無 | 238–263 | 取得時選擇一張能力牌。每場戰鬥開始時，該牌會在你的起始手牌中。 | 牌組須含至少 1 張能力牌才會出現；不會由 Calling Bell 給出 | 戰鬥開場、卡牌操作 |
| 5 | Darkstone Periapt | Uncommon | 無 | 238–263 | 每當你獲得一張詛咒牌，最大 HP +6。 | 無 | 治療（最大HP）、詛咒 |
| 6 | Duality | Uncommon | Watcher | 238–263 | 每當你打出一張攻擊牌，獲得 1 點臨時敏捷（Dexterity）。 | 僅 Watcher 卡池 | 格擋、連打觸發 |
| 7 | Eternal Feather | Uncommon | 無 | 238–263 | 牌組中每有 5 張牌，進入休息點（Rest Site）時回復 3 HP。 | 無 | 治療、地圖 |
| 8 | Frozen Egg | Uncommon | 無 | 238–263 | 每當你將一張能力牌加入牌組時，將其升級。 | 無 | 升階 |
| 9 | Gold-Plated Cables | Uncommon | Defect | 238–263 | 你最右側的充能球額外觸發一次被動效果。 | 僅 Defect 卡池 | 充能球 |
| 10 | Gremlin Horn | Uncommon | 無 | 238–263 | 每當一名敵人死亡，獲得 1 點能量並抽 1 張牌。 | 無 | 能量、抽牌 |
| 11 | Horn Cleat | Uncommon | 無 | 238–263 | 在你的第 2 回合開始時，獲得 14 點格擋。 | 無 | 格擋、戰鬥開場 |
| 12 | Ink Bottle | Uncommon | 無 | 238–263 | 每當你打出 10 張牌，抽 1 張牌。 | 無 | 抽牌 |
| 13 | Kunai | Uncommon | 無 | 238–263 | 每當你在單一回合內打出 3 張攻擊牌，獲得 1 點敏捷（Dexterity）。 | 無 | 格擋、連打觸發 |
| 14 | Letter Opener | Uncommon | 無 | 238–263 | 每當你在單一回合內打出 3 張技能牌，對所有敵人造成 5 點傷害。 | 無 | 傷害、連打觸發 |
| 15 | Matryoshka | Uncommon | 無 | 238–263 | 接下來開啟的 2 個非 Boss 寶箱各多含 1 件遺物（共 2 件）。額外遺物 25% Uncommon / 75% Common。 | 只在樓層 41 以下出現（Endless 模式 40 層後不再生成） | 地圖、遺物 |
| 16 | Meat on the Bone | Uncommon | 無 | 238–263 | 戰鬥結束時若你的 HP 低於或等於 50%，回復 12 HP。 | 無 | 治療 |
| 17 | Mercury Hourglass | Uncommon | 無 | 238–263 | 在你的回合開始時，對所有敵人造成 3 點傷害。 | 無 | 傷害 |
| 18 | Molten Egg | Uncommon | 無 | 238–263 | 每當你將一張攻擊牌加入牌組時，將其升級。 | 無 | 升階 |
| 19 | Mummified Hand | Uncommon | 無 | 238–263 | 每當你打出一張能力牌，手牌中隨機一張牌本回合費用變為 0。 | 無 | 能量、卡牌操作 |
| 20 | Ninja Scroll | Uncommon | Silent | 238–263 | 每場戰鬥開始時，將 3 張「飛刀（Shiv）」加入手牌。 | 僅 Silent 卡池 | 戰鬥開場、卡牌操作 |
| 21 | Ornamental Fan | Uncommon | 無 | 238–263 | 每當你在單一回合內打出 3 張攻擊牌，獲得 4 點格擋。 | 無 | 格擋、連打觸發 |
| 22 | Pantograph | Uncommon | 無 | 238–263 | Boss 戰開始時，回復 25 HP。 | 無 | 治療、戰鬥開場 |
| 23 | Paper Krane | Uncommon | Silent | 238–263 | 帶有虛弱（Weak）的敵人造成的傷害減少 40%（而非 25%）。 | 僅 Silent 卡池 | debuff 強化 |
| 24 | Paper Phrog | Uncommon | Ironclad | 238–263 | 帶有易傷（Vulnerable）的敵人受到的傷害增加 75%（而非 50%）。 | 僅 Ironclad 卡池 | debuff 強化、傷害 |
| 25 | Pear | Uncommon | 無 | 238–263 | 取得時，最大 HP +10。 | 無 | 治療（最大HP） |
| 26 | Question Card | Uncommon | 無 | 238–263 | 之後的卡牌獎勵多 1 張牌可供選擇。 | 無 | 卡牌操作、地圖 |
| 27 | Self-Forming Clay | Uncommon | Ironclad | 238–263 | 每當你失去 HP，下回合獲得 3 點格擋。 | 僅 Ironclad 卡池 | 格擋 |
| 28 | Shuriken | Uncommon | 無 | 238–263 | 每當你在單一回合內打出 3 張攻擊牌，獲得 1 點力量（Strength）。 | 無 | 傷害成長、連打觸發 |
| 29 | Singing Bowl | Uncommon | 無 | 238–263 | 選取卡牌獎勵時，可以改為最大 HP +2（放棄拿牌）。 | 無 | 治療（最大HP）、卡牌操作 |
| 30 | Strike Dummy | Uncommon | 無 | 238–263 | 牌名含「Strike（打擊）」的卡牌額外造成 3 點傷害。 | 無 | 傷害 |
| 31 | Sundial | Uncommon | 無 | 238–263 | 每洗牌（重洗抽牌堆）3 次，獲得 2 點能量。 | 無 | 能量 |
| 32 | Symbiotic Virus | Uncommon | Defect | 238–263 | 每場戰鬥開始時，衍生（Channel）1 個黑暗球（Dark）。 | 僅 Defect 卡池 | 充能球、戰鬥開場 |
| 33 | Teardrop Locket | Uncommon | Watcher | 238–263 | 每場戰鬥以「平靜（Calm）」狀態開始。 | 僅 Watcher 卡池 | 戰鬥開場、姿態 |
| 34 | The Courier | Uncommon | 無 | 238–263 | 商人會補貨（卡牌、遺物、藥水售出後重新上架），且所有商品價格降低 20%。 | 無 | 金錢、商店 |
| 35 | Toxic Egg | Uncommon | 無 | 238–263 | 每當你將一張技能牌加入牌組時，將其升級。 | 無 | 升階 |
| 36 | White Beast Statue | Uncommon | 無 | 238–263 | 戰鬥獎勵中必定出現藥水。 | 無 | 藥水 |

### 補充備註

- **通用取得管道**（所有 Uncommon 遺物共通）：菁英戰掉落、寶箱、商店購買，以及 Calling Bell / Shovel / Black Star / Matryoshka 等遺物與多個事件（Wheel of Change、Dead Adventurer、The Colosseum 等）。上表「取得限制」欄僅列**額外**限制。
- **角色限定統計**：Ironclad 2（Paper Phrog、Self-Forming Clay）、Silent 2（Ninja Scroll、Paper Krane）、Defect 2（Gold-Plated Cables、Symbiotic Virus）、Watcher 2（Duality、Teardrop Locket）、通用 28，合計 36。
- Bottled 三兄弟的生成條件為「牌組含對應類型的可裝瓶卡牌」（攻擊/技能/能力各對應一件），這是 STS 中「條件式遺物池」的代表設計。

---

## Slay the Spire — Rare 遺物完整參考表（v2.x 正式版）

- 來源：slaythespire.wiki.gg（Relics List / Relics / Merchant 頁面，2026-07-08 核實）。fandom wiki 內容與之同源（wiki.gg 為官方遷移站）。
- 共 **34 件** Rare 遺物：25 件無角色限定 + Ironclad 3 + Silent 3 + Defect 1 + Watcher 2。
- 商店價格：Rare 遺物基準價 **300 gold，實際 285–315**（±5% 浮動）；Ascension 16 起 +10%（314–347）。Membership Card −50%、The Courier −20% 可疊乘。下表價格欄統一為 285–315，特例另註。

| # | 英文名稱 | 稀有度 | 角色限定 | 商店價格 (gold) | 效果全文（繁中） | 取得限制 / 特殊條件 | 機制分類 |
|---|---|---|---|---|---|---|---|
| 1 | Bird-Faced Urn | Rare | 無 | 285–315 | 每當你打出一張能力牌（Power），回復 2 點生命。 | — | 治療 |
| 2 | Calipers | Rare | 無 | 285–315 | 回合開始時，你失去 15 點格擋，而非失去全部格擋。 | — | 格擋 |
| 3 | Captain's Wheel | Rare | 無 | 285–315 | 在你的第 3 回合開始時，獲得 18 點格擋。 | — | 格擋 |
| 4 | Cloak Clasp | Rare | Watcher | 285–315 | 你的回合結束時，手牌中每有 1 張牌獲得 1 點格擋。 | 僅 Watcher | 格擋、手牌 |
| 5 | Dead Branch | Rare | 無 | 285–315 | 每當你消耗（Exhaust）一張牌，將一張隨機卡牌加入手牌。 | — | 卡牌操作 |
| 6 | Du-Vu Doll | Rare | 無 | 285–315 | 你的牌組中每有一張詛咒牌，每場戰鬥開始時獲得 1 點力量。 | — | 戰鬥開場、力量 |
| 7 | Emotion Chip | Rare | Defect | 285–315 | 若你在上一回合失去過生命，回合開始時觸發所有充能球（Orb）的被動效果。 | 僅 Defect | 充能球 |
| 8 | Fossilized Helix | Rare | 無 | 285–315 | 每場戰鬥中，防止你第一次失去生命。 | — | 防禦、戰鬥開場 |
| 9 | Gambling Chip | Rare | 無 | 285–315 | 每場戰鬥開始時，棄置任意數量的牌，然後抽等量的牌。 | — | 戰鬥開場、抽牌 |
| 10 | Ginger | Rare | 無 | 285–315 | 你不會再陷入虛弱（Weakened）狀態。 | — | 狀態免疫 |
| 11 | Girya | Rare | 無 | 285–315 | 你現在可以在休息點（Rest Site）鍛鍊獲得力量（最多 3 次，每次 +1）。 | 僅在樓層 49 之前出現；營火三遺物（Shovel/Girya/Peace Pipe）同一 run 最多獲得 2 件 | 地圖、力量 |
| 12 | Golden Eye | Rare | Watcher | 285–315 | 每當你占卜（Scry）時，額外占卜 2 張牌。 | 僅 Watcher | 占卜、卡牌操作 |
| 13 | Ice Cream | Rare | 無 | 285–315 | 能量（Energy）不再於回合間清空，可保留至下回合。 | — | 能量 |
| 14 | Incense Burner | Rare | 無 | 285–315 | 每 6 回合，獲得 1 層無實體（Intangible）。 | — | 防禦 |
| 15 | Lizard Tail | Rare | 無 | 285–315 | 當你將要死亡時，改為回復至 50% 最大生命（每個 run 僅一次）。 | 一次性效果 | 治療、保命 |
| 16 | Mango | Rare | 無 | 285–315 | 拾取時，最大生命 +14。 | — | 最大生命 |
| 17 | Old Coin | Rare | 無 | 不可購買 | 拾取時，獲得 300 金幣。 | 不會出現在商店販售；僅在樓層 49 之前出現 | 金錢 |
| 18 | Peace Pipe | Rare | 無 | 285–315 | 你現在可以在休息點移除牌組中的卡牌。 | 僅在樓層 49 之前出現；營火三遺物同一 run 最多獲得 2 件 | 地圖、卡牌操作 |
| 19 | Pocketwatch | Rare | 無 | 285–315 | 若你本回合打出的牌不超過 3 張，下回合開始時額外抽 3 張牌。 | — | 抽牌 |
| 20 | Prayer Wheel | Rare | 無 | 285–315 | 普通敵人額外掉落一份卡牌獎勵。 | 僅在樓層 49 之前出現 | 獎勵、卡牌操作 |
| 21 | Shovel | Rare | 無 | 285–315 | 你現在可以在休息點挖掘（Dig）獲得遺物。 | 僅在樓層 49 之前出現；營火三遺物同一 run 最多獲得 2 件 | 地圖、遺物 |
| 22 | Stone Calendar | Rare | 無 | 285–315 | 第 7 回合結束時，對所有敵人造成 52 點傷害。 | — | 傷害 |
| 23 | The Specimen | Rare | Silent | 285–315 | 每當一名敵人死亡時，將其身上的中毒（Poison）層數轉移給一名隨機敵人。 | 僅 Silent | 中毒 |
| 24 | Thread and Needle | Rare | 無 | 285–315 | 每場戰鬥開始時，獲得 4 點護甲（Plated Armor）。 | — | 戰鬥開場、格擋 |
| 25 | Tingsha | Rare | Silent | 285–315 | 每當你在自己回合中棄置一張牌，對一名隨機敵人造成 3 點傷害。 | 僅 Silent | 棄牌、傷害 |
| 26 | Torii | Rare | 無 | 285–315 | 每當你將受到 5 點或以下的未格擋攻擊傷害時，將其降為 1 點。 | — | 防禦 |
| 27 | Tough Bandages | Rare | Silent | 285–315 | 每當你在自己回合中棄置一張牌，獲得 3 點格擋。 | 僅 Silent | 棄牌、格擋 |
| 28 | Tungsten Rod | Rare | 無 | 285–315 | 每當你將失去生命時，少失去 1 點。 | — | 防禦 |
| 29 | Turnip | Rare | 無 | 285–315 | 你不會再陷入脆弱（Frail）狀態。 | — | 狀態免疫 |
| 30 | Unceasing Top | Rare | 無 | 285–315 | 在你的回合中，每當你手牌為空時，抽 1 張牌。 | — | 抽牌 |
| 31 | Wing Boots | Rare | 無 | 285–315 | 選擇下一個房間時，可以無視路徑連線任意移動（共 3 次）。 | 僅在樓層 41 之前出現 | 地圖 |
| 32 | Champion Belt | Rare | Ironclad | 285–315 | 每當你施加易傷（Vulnerable）時，同時施加 1 層虛弱（Weak）。 | 僅 Ironclad | debuff |
| 33 | Charon's Ashes | Rare | Ironclad | 285–315 | 每當你消耗（Exhaust）一張牌，對所有敵人造成 3 點傷害。 | 僅 Ironclad | 傷害、卡牌操作 |
| 34 | Magic Flower | Rare | Ironclad | 285–315 | 戰鬥中的治療效果提高 50%。 | 僅 Ironclad | 治療 |

### 附註

- 一般遺物獎勵抽取時 Common:Uncommon:Rare 機率約 50%/33%/17%。
- 「樓層 49 之前」對應第三幕結束前；此類遺物在第四幕（Act 4）不再出現於獎勵池。
- Lizard Tail 觸發後即失效（單次）；Fossilized Helix 為每場戰鬥一次。

---

## Slay the Spire — Boss 遺物完整參考表（v2.x 正式版）

來源：slaythespire.wiki.gg（Relics List、Orrery 子頁核實；fandom.com 因 HTTP 402 無法直接抓取，wiki.gg 為同社群維護之鏡像 wiki）。核實日期：2026-07-08。

共 **30 件**：通用 19 + Ironclad 3 + Silent 3 + Defect 3 + Watcher 2。

備註：
- **取得方式**：全部 Boss 遺物僅在「擊敗幕 1 / 幕 2 Boss 後開寶箱三選一」取得（幕 3 Boss 不掉遺物）。Neow 開局祝福「以起始遺物交換隨機 Boss 遺物」也可拿到。**商店不販售 Boss 遺物**，故商店價格全標「不販售」。
- 四件「起始遺物升級版」（Black Blood / Ring of the Serpent / Frozen Core / Holy Water）拿到時**取代**該角色的起始遺物。
- Orrery 在 v2.x 為 Shop 稀有度（早期版本曾是 Boss），故不在本表。

| 英文名稱 | 稀有度 | 角色限定 | 商店價格 | 效果全文（含代價） | 取得方式 | 機制分類 |
|---|---|---|---|---|---|---|
| Astrolabe | Boss | 無 | 不販售 | 拾取時：轉化（Transform）3 張牌，然後將它們升級。 | Boss 戰後三選一 | 牌組改造、隨機性 |
| Black Star | Boss | 無 | 不販售 | 擊敗精英（Elite）後額外掉落 1 件遺物。 | Boss 戰後三選一 | 獎勵放大、路線誘導 |
| Busted Crown | Boss | 無 | 不販售 | 每回合開始時獲得 1 能量。**代價：之後的卡牌獎勵少 2 張可選（三選一變只剩 1 張）。** | Boss 戰後三選一 | 能量、牌組成長受限 |
| Calling Bell | Boss | 無 | 不販售 | 拾取時：獲得 1 張獨特詛咒牌（Curse of the Bell，不可移除），並獲得 3 件遺物。 | Boss 戰後三選一 | 遺物爆發、詛咒代價 |
| Coffee Dripper | Boss | 無 | 不販售 | 每回合開始時獲得 1 能量。**代價：不能再在營火休息（Rest）回血。** | Boss 戰後三選一 | 能量、續航代價 |
| Cursed Key | Boss | 無 | 不販售 | 每回合開始時獲得 1 能量。**代價：每次開非 Boss 寶箱時獲得 1 張詛咒牌。** | Boss 戰後三選一 | 能量、詛咒代價 |
| Ectoplasm | Boss | 無 | 不販售 | 每回合開始時獲得 1 能量。**代價：不能再獲得金幣。** | Boss 戰後三選一 | 能量、經濟封鎖 |
| Empty Cage | Boss | 無 | 不販售 | 拾取時：從牌組移除 2 張牌。 | Boss 戰後三選一 | 牌組精簡 |
| Fusion Hammer | Boss | 無 | 不販售 | 每回合開始時獲得 1 能量。**代價：不能再在營火鍛造（Smith，升級卡牌）。** | Boss 戰後三選一 | 能量、成長代價 |
| Pandora's Box | Boss | 無 | 不販售 | 拾取時：轉化所有「打擊（Strike）」與「防禦（Defend)」牌（隨機變成其他牌）。 | Boss 戰後三選一 | 牌組改造、高隨機 |
| Philosopher's Stone | Boss | 無 | 不販售 | 每回合開始時獲得 1 能量。**代價：所有敵人開戰時獲得 1 力量（Strength）。** | Boss 戰後三選一 | 能量、敵人強化代價 |
| Runic Dome | Boss | 無 | 不販售 | 每回合開始時獲得 1 能量。**代價：不能再看到敵人意圖（Intent）。** | Boss 戰後三選一 | 能量、資訊剝奪 |
| Runic Pyramid | Boss | 無 | 不販售 | 回合結束時不再棄掉手牌（手牌保留到下回合）。 | Boss 戰後三選一 | 手牌管理 |
| Sacred Bark | Boss | 無 | 不販售 | 藥水效果加倍。 | Boss 戰後三選一 | 藥水強化 |
| Slaver's Collar | Boss | 無 | 不販售 | 在 Boss 戰與精英戰中，每回合開始時獲得 1 能量（一般戰鬥無效果）。 | Boss 戰後三選一 | 條件式能量 |
| Snecko Eye | Boss | 無 | 不販售 | 每回合開始時多抽 2 張牌。**代價：每場戰鬥開始時陷入混亂（Confused：抽到的牌費用隨機化為 0–3）。** | Boss 戰後三選一 | 抽牌、費用隨機化 |
| Sozu | Boss | 無 | 不販售 | 每回合開始時獲得 1 能量。**代價：不能再獲得藥水。** | Boss 戰後三選一 | 能量、資源封鎖 |
| Tiny House | Boss | 無 | 不販售 | 拾取時：獲得 1 瓶藥水、50 金幣、最大 HP +5、獲得 1 張卡牌、隨機升級 1 張牌（無持續效果——「五小福」一次性包裹）。 | Boss 戰後三選一 | 一次性綜合獎勵 |
| Velvet Choker | Boss | 無 | 不販售 | 每回合開始時獲得 1 能量。**代價：每回合最多只能打出 6 張牌。** | Boss 戰後三選一 | 能量、出牌數限制 |
| Black Blood | Boss | Ironclad | 不販售 | 取代起始遺物 Burning Blood。戰鬥結束時回復 12 HP（原版為 6 HP）。 | Boss 戰後三選一（起始遺物升級） | 續航、起始遺物升級 |
| Mark of Pain | Boss | Ironclad | 不販售 | 每回合開始時獲得 1 能量。**代價：每場戰鬥開始時將 2 張「傷口（Wound）」洗入抽牌堆。** | Boss 戰後三選一 | 能量、廢牌污染 |
| Runic Cube | Boss | Ironclad | 不販售 | 每當你失去 HP 時，抽 1 張牌（自傷也觸發）。 | Boss 戰後三選一 | 抽牌、自傷協同 |
| Hovering Kite | Boss | Silent | 不販售 | 每回合第一次棄牌（discard）時，獲得 1 能量。 | Boss 戰後三選一 | 條件式能量、棄牌協同 |
| Ring of the Serpent | Boss | Silent | 不販售 | 取代起始遺物 Ring of the Snake。每回合開始時多抽 1 張牌（原版為每場戰鬥第一回合多抽 2 張）。 | Boss 戰後三選一（起始遺物升級） | 抽牌、起始遺物升級 |
| Wrist Blade | Boss | Silent | 不販售 | 費用為 0 的攻擊牌造成的傷害 +4。 | Boss 戰後三選一 | 傷害加成、0 費協同 |
| Frozen Core | Boss | Defect | 不販售 | 取代起始遺物 Cracked Core。若回合結束時有空的充能球（Orb）欄位，衍生（Channel）1 個冰霜球（原版為開戰時衍生 1 個閃電球）。 | Boss 戰後三選一（起始遺物升級） | 充能球、起始遺物升級 |
| Inserter | Boss | Defect | 不販售 | 每 2 回合獲得 1 個充能球欄位。 | Boss 戰後三選一 | 充能球擴充 |
| Nuclear Battery | Boss | Defect | 不販售 | 每場戰鬥開始時衍生 1 個電漿球（Plasma，+1 能量）。 | Boss 戰後三選一 | 能量、充能球 |
| Holy Water | Boss | Watcher | 不販售 | 取代起始遺物 Pure Water。每場戰鬥開始時將 3 張「奇蹟（Miracle）」加入手中（原版為 1 張）。 | Boss 戰後三選一（起始遺物升級） | 能量、起始遺物升級 |
| Violet Lotus | Boss | Watcher | 不販售 | 每當你離開平靜（Calm）狀態時，額外獲得 1 能量（原本離開平靜得 2，變成 3）。 | Boss 戰後三選一 | 能量、姿態協同 |

### 設計模式觀察（供 SwordCard Boss 遺物參考）

- **主流模板「+1 能量＋一項代價」**：30 件中 11 件是「每回合 +1 能量」搭配不同維度的代價——回血（Coffee Dripper）、升級（Fusion Hammer）、金幣（Ectoplasm）、藥水（Sozu）、資訊（Runic Dome）、出牌數（Velvet Choker）、卡牌獎勵（Busted Crown）、詛咒（Cursed Key）、敵人強化（Philosopher's Stone）、廢牌（Mark of Pain）。代價落在 run 層資源而非戰鬥數值，玩家可用路線規劃「繞開」代價，是取捨深度的來源。
- **一次性拾取效果**（Astrolabe / Empty Cage / Pandora's Box / Calling Bell / Tiny House）：無持續效果，用「當下改造牌組」換選擇張力。
- **無代價純增益**（Runic Pyramid / Sacred Bark / Black Star / Runic Cube / Wrist Blade 等）：代價是隱性的——放棄同格另外兩件（多半含 +1 能量）的機會成本。
- **起始遺物升級版**每角色恰 1 件（Watcher 的 Holy Water），穩定保底選項。

---

# 對 SwordCard 的設計應用

> 對照基準：SwordCard 現況 79 件遺物（63 通用 + 10 角色專武 + 6 Boss 神器；`scripts/relic_catalog.gd`），
> 稀有度 common 13 / uncommon 32 / rare 28 / legendary 6，商店價 70/95/130/180（`ai_run_engine.gd:1057-1065`）。
> 每一條先過三根設計支柱（CLAUDE.md），不踩支柱的不做。

## 一、結構對照：SwordCard 已對齊與尚缺的

| 面向 | STS | SwordCard 現況 | 差距判讀 |
|---|---|---|---|
| 稀有度定價 | 完全由稀有度決定（150/250/300） | 同原則（70/95/130/180） | ✅ 已對齊，且 STS 稀有度價差是 1.67x/2x，SwordCard 是 1.36x/1.86x/2.57x——rare 相對更貴，有助壓幕 3 通膨 |
| Boss 遺物 | 30 件、三選一、幕 3 Boss 不掉 | 6 神器綁 6 Boss、三選一 | ✅ 機制在；差距在「代價設計」深度（見二） |
| 帶代價遺物 | Boss 11 件能量系 + Brimstone + Event 負面面具群 | 僅 5 件（2 取捨 + 3 附詛咒） | ⚠️ 最大缺口，直接踩支柱 3 |
| run 層互動遺物 | 大量（休息點/商店/寶箱/?房/卡牌獎勵） | `permanent` 僅 4 種 | ⚠️ 第二大缺口，踩支柱 1（旅程感）+ 3 |
| 角色限定遺物 | 每角 6–7 件、每檔次都有 | 專武 10 件（每角 2–3） | 可補：Common 級「小幅放大 archetype」檔次目前沒有 |
| 稀有度分布 | 低稀有度最多（36/36/34） | 金字塔倒掛（13/32/28） | ⚠️ common 太少：前期拿到的遺物驚喜感靠 common 池撐 |
| 一次性拾取遺物 | Strawberry/War Paint/Cauldron/Orrery 等 ~10 件 | 無 | 可補：實作成本低（拾取即結算，不進 trigger 系統） |
| 趣味遺物 | Circlet / Spirit Poop / Cultist Headpiece | 無 | 低優先，但便宜且有記憶點 |

## 二、五個可直接借的設計模式（按支柱排序）

1. **「+1 能量 + run 層代價」Boss 模板**（支柱 3 核心）。STS 30 件 Boss 遺物有 11 件走這個模板，代價全落在 **run 層資源**（回血/升級/金幣/藥品/資訊/獎勵），不是戰鬥數值——玩家可以用路線規劃「繞開」代價，取捨才有深度。SwordCard 的 6 神器目前用 `curse_on_acquire`（塞詛咒卡）只覆蓋一種代價維度；擴充 Boss 池時優先做「能量+代價」系：禁休息回血、商店漲價、卡牌獎勵少一張、看不到敵人意圖——每種都是現成的 run 層 hook。
2. **遺物把地圖節點變成 build 的一部分**（支柱 1）。STS 用 Regal Pillow / Ancient Tea Set / Meal Ticket / Ssserpent Head / Tiny Chest / Juzu Bracelet 讓「走哪條路」跟「拿了什麼遺物」互相咬合。SwordCard 要做「餘杭→蘇州→苗疆的旅程感」，這類遺物比改地圖生成便宜得多——先加 5–8 件「進入某類節點觸發」的遺物，路線選擇立刻變成 build 決策。
3. **條件式遺物池**（Bottled 系列：牌組須含對應卡型才出現）。SwordCard 四角色機制差異大（連擊/debuff/反擊/毒），可做「毒牌 ≥5 張才出現的毒引擎遺物」之類——保證遺物出現時必然有戲，避免阿奴的毒遺物掉給李逍遙的尷尬。
4. **經濟遺物對沖幕 3 通膨**（支柱 3 現況裂縫，`BALANCE_REPORT.md` §六）。STS 的做法是雙向的：給錢的（Golden Idol/Old Coin/Maw Bank）和鎖錢的（Ectoplasm）並存，且 Maw Bank 有「消費即失效」的內建剎車。SwordCard 若加經濟遺物，優先做**帶剎車或帶代價**的（例：每層 +12 金但進商店消費即失效），不要做純加錢的——通膨已經存在。
5. **Common 級角色遺物 = 小幅放大 archetype**（支柱 2）。STS 每角恰 1 件 Common 角色遺物，全都直接餵核心機制（Red Skull=力量、Snecko Skull=毒+1）。SwordCard 可給四角各 1 件 common 專屬（李逍遙連擊計數、趙靈兒 debuff 層數、林月如反擊值、阿奴毒疊）——便宜、早期就能拿到、強化「四種解法」的體感。

## 三、明確不借的

- **Snecko Eye 式費用隨機化**：SwordCard 手機優先、拖拉出牌，費用隨機化的資訊負荷在小螢幕上體驗差。
- **Prismatic Shard 式跨角色卡池**：組隊模式已有「多角色卡」的表達，跨池會稀釋支柱 2 的四角色分工。
- **樓層數值門檻**（41 層/49 層規則）：SwordCard 只有 8 幕、每幕 9–11 層，用「幕數」做門檻即可，不需要全域樓層計數。

## 四、命名紀律

以上全部是**機制**層的借用；落地時卡名/遺物名必須過 `docs/PAL1_CANON.md`（支柱 1），品味題照 `docs/harness/DISPATCH.md` §3 產 3 案給使用者選。STS 名稱只是機制代號，不要音譯或直譯進遊戲。

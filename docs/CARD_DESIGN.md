# 卡牌機制設計參考（Card Design Reference）

> SwordCard 戰鬥靈感來自 Slay the Spire（STS）。本文整理 STS 全卡牌機制當設計詞彙庫，並對照 SwordCard 現況、列出可擴充空間。新增卡牌機制前先查。
> 資料經查證（來源見文末）。

---

## 一、STS 卡牌機制全覽

### A. 卡片類型（5 種）

| 類型 | 說明 |
|---|---|
| **Attack 攻擊** | 造成傷害；部分 relic/效果只對 attack 觸發 |
| **Skill 技能** | 防禦 / 輔助 / 操作牌庫 |
| **Power 能力** | 打出後該場戰鬥永久生效，不留手牌 |
| **Status 狀態** | 敵人或機制塞進牌庫的廢牌，戰鬥後消失（非永久） |
| **Curse 詛咒** | 永久廢牌，多半 Unplayable，需特殊手段移除 |

### B. 費用機制
- 固定費（0–3 能量）
- **X 費**：耗盡全部能量，效果隨消耗能量數放大
- **Unplayable**：不可主動打出
- **費用減免**：本回合 / 永久 -N

### C. 卡片修飾關鍵字（印在卡面）

| 關鍵字 | 效果 |
|---|---|
| **Exhaust 消耗** | 打出後移出牌庫直到戰鬥結束（一次性） |
| **Ethereal 虛無** | 回合結束若還在手牌 → 自動 Exhaust |
| **Innate 固有** | 開場首抽必定持有 |
| **Retain 保留** | 回合結束不棄掉，留到下回合 |

### D. 核心動作（設計動詞庫）

- 傷害：單體 / **連擊 N 次** / **全體 AoE** / 隨機目標
- 獲得格擋（Block）
- 抽牌 / 棄牌 / 消耗牌
- 獲得 / 失去 能量
- 失去 HP（自傷）/ 治療 / 加最大 HP
- **卡片生成**：產生卡到 手牌 / 抽牌堆 / 棄牌堆（如 Shiv 飛鏢）
- 牌庫操作：把卡置頂、Scry（看並選棄牌庫頂 N 張）
- **升級手牌**（暫時或永久）

### E. 增益 Buff（正面 Power）

| Buff | 效果 |
|---|---|
| **Strength 力量** | 每層攻擊傷害 +1 |
| **Dexterity 敏捷** | 每層卡片獲得的格擋 +1 |
| **Artifact 神器** | 擋下 1 次 debuff |
| **Thorns 荊棘** | 被攻擊時反彈傷害 |
| **Metallicize 鍍金** | 每回合結束獲得 N 格擋 |
| **Plated Armor 鋼板** | 每回合得格擋；被擊中 -1 層 |
| **Regen 再生** | 每回合回復 HP |
| **Barricade 壁壘** | 格擋回合結束不清空 |
| **Intangible 虛體** | 本回合所有受到的傷害降為 1 |
| **Buffer 緩衝** | 擋下 1 次 HP 損失 |
| **Vigor 蓄力** | 下一張攻擊額外加傷（用後消失） |
| **Demon Form / Brutality** | 每回合自動 +力量 / 失 HP 抽牌 |
| **Feel No Pain / Dark Embrace** | 消耗牌時 得格擋 / 抽牌 |

### F. 減益 Debuff

| Debuff | 效果 |
|---|---|
| **Vulnerable 易傷** | 受到攻擊傷害 +50% |
| **Weak 虛弱** | 造成攻擊傷害 -25% |
| **Frail 脆弱** | 獲得的格擋 -25% |
| **Poison 中毒** | 每回合開始掉 N HP，之後 N-1 遞減 |
| **力量 / 敏捷 down** | 負層數削弱 |
| **Entangle 纏繞** | 本回合不能打攻擊牌 |
| **No Draw / Confusion / Hex** | 不能抽牌 / 費用隨機 / 打非攻擊牌時加廢牌 |

### G. 角色招牌系統

| 角色 | 招牌機制 |
|---|---|
| **鐵甲 Ironclad** | 力量疊加、消耗牌 synergy、燃血（失 HP 換效果） |
| **靜默 Silent** | 中毒疊加、**Shiv 飛鏢（0 費臨時攻擊牌）**、棄牌 synergy |
| **缺陷 Defect** | **Orbs 法球**（閃電/冰霜/黑暗/電漿）+ Channel/Evoke + Focus |
| **觀者 Watcher** | **Stance 架勢**（平靜/憤怒/神聖）+ Mantra + Scry + Retain |

---

## 二、SwordCard 現況對照

### 已實作 effect kinds（`scripts/effect_resolver.gd`）

`damage / block / heal / heal_party / poison / weak / vulnerable / draw / energy / self_damage / power(=力量 Strength) / consume_energy_damage(≈X費) / poison_burst / revive / damage_all / poison_all / weak_all / vulnerable_all(AoE) / summon / cure_poison / cure_debuff / steal`

卡片類型：`attack / skill / power / curse`（curse 為 Event Branching Phase 4 新增）

### STS 有、SwordCard 還沒有（可擴充空間）

| 缺口 | STS 對應 | 適合 SwordCard? | 主題契合 |
|---|---|---|---|
| 卡片修飾字 Exhaust / Ethereal / Innate / Retain | 一次性大招、消耗流 | ✅ 高 | 御劍術絕招、一次性法寶 |
| 連擊 N 次 Multi-hit | 多段攻擊 | ✅ 高 | 萬劍訣、御劍術、林月如連刀 |
| 卡片生成（加卡到手牌/牌堆） | Shiv 飛鏢 | ✅ 高 | 阿奴蠱蟲、暗器 |
| 格擋保留 Barricade / Metallicize | 護體不清空 / 每回合得格擋 | ✅ 中 | 護體流、龜甲符類 |
| **Frail 脆弱** | 獲得格擋 -25% | ✅ 中 | debuff 補完（目前缺這個削防） |
| **Dexterity 敏捷** | +格擋（目前只有 power=力量） | ⚠️ 可選 | 趙靈兒/防禦角 |
| Thorns 荊棘 | 反傷 | ✅ 中 | 林月如反擊 passive 已有雛形 |
| Intangible / Buffer | 減傷保命 | ⚠️ 強，需平衡 | 仙術護體絕招 |
| 牌庫操作 Scry / 置頂 | 抽牌品質控制 | ⚠️ 中 | 李逍遙天師符法 |
| 架勢 Stance / 法球 Orb | Watcher/Defect 專屬 | ❌ 低 | 偏離 PAL1，暫不考慮 |

### 設計原則建議

- **優先補「卡片修飾字（Exhaust/Ethereal/Retain）」+「連擊」+「卡片生成」** — 這三類能立刻擴大卡牌設計空間，且與 PAL1 招式（御劍術連擊、蠱蟲生成、一次性絕招）高度契合。
- Frail 補完 debuff 三本柱（已有 weak/vulnerable，缺 frail）。
- 避免引入架勢/法球這類重型角色專屬系統，與 PAL1 仙俠風格不合。
- 任何新機制都要：① EffectResolver 加 kind ② CardFormat 顯示 ③ smoke test 覆蓋 ④ 不破壞 balance regression baseline。

---

## 三、武器分流派架構（Weapon-Based Archetypes）

> 解決「現有卡有主題但無 build 決策」的問題。利用 **PAL1 每位角色可裝備多種武器** 的設定，把每角色拆成 **2 條武器流派**，各綁一條 scaling axis。玩家在 run 中依抽到的武器專武 / payoff 卡往一邊歪 → 產生 build 決策。

### 設計理念

一條流派 = **啟動器(enabler) + 報酬(payoff) + 縮放軸(scaling axis)** 三件套，並以一件**武器專武遺物**當錨點：
- 撿到某把武器專武 → 該流派的 payoff 被啟動 → 玩家開始往那條軸堆牌
- 兩條流派的軸**刻意不同**（如杖=中毒、刀=力量），堆混 = 不專精懲罰

### PAL1 武器對照（考據見 `docs/PAL1_CANON.md`）

| 角色 | 武器 A | 武器 B |
|---|---|---|
| 李逍遙 | 劍（御劍術，本命） | 刀（鬼牙刀，最強刀） |
| 趙靈兒 | 杖（巫女 / 天蛇杖，女媧後人） | 劍（越女劍） |
| 林月如 | 劍（靈劍山莊劍術） | 刀（鳳鳴刀 / 玄冥寶刀） |
| 阿奴 | 杖（巫女蠱術） | 刀（巫月神刀，終極武器） |

### 8 條流派詳表

#### 李逍遙
| 流派 | 縮放軸 | 啟動器（現有卡） | 報酬 payoff | 錨點專武 |
|---|---|---|---|---|
| **劍流・萬劍** | 連擊次數 | 御劍術、萬劍訣、劍陣、九龍訣 | 每段擊中觸發（烈火令「每出攻擊牌額外傷害」已有雛形） | 純鈞劍 / 龍泉劍（現有） |
| **刀流・鬼牙** | 力量（單發爆發） | 酒神咒、裂魄斬、醉夢望月(power) | 「傷害 = 基礎 + 力量×倍率」單發重擊 | **鬼牙刀**（需新增） |

#### 趙靈兒
| 流派 | 縮放軸 | 啟動器（現有卡） | 報酬 payoff | 錨點專武 |
|---|---|---|---|---|
| **杖流・神術** | 治療量 / debuff 層數 | 觀音咒、五氣朝元、玄冰咒、炎咒 | 治療時同時得格擋/力量；對虛弱・破綻敵加傷 | 女媧石 / 鎖妖玉（現有） |
| **劍流・越女** | 力量（物理斬） | 雷光連擊、天雷破 | 法術→物理混打，連斬吃力量 | **越女劍**（需新增） |

#### 林月如
| 流派 | 縮放軸 | 啟動器（現有卡） | 報酬 payoff | 錨點專武 |
|---|---|---|---|---|
| **劍流・連斬** | 本回合出牌數 | 輕劍急刺(0費)、乾坤一擲(0費)、旋劍花舞 | 「本回合第 N 張牌」觸發加傷 / 抽牌 | **靈劍**（需新增） |
| **刀流・反擊** | 格擋 / 反傷 | 回身反擊、金蟬卸力、鐵衣功 | 獲得格擋 / 被擊時反傷（月如 first_block_counter passive 已有雛形） | **鳳鳴刀**（需新增） |

#### 阿奴
| 流派 | 縮放軸 | 啟動器（現有卡） | 報酬 payoff | 錨點專武 |
|---|---|---|---|---|
| **杖流・蠱毒** | 中毒層數 | 御蜂術、萬蟻蝕象、爆炸蠱 | poison_burst 引爆（**已有機制**）；「敵中毒越多引爆越痛」 | 天蛇靈笛 / 蝕骨蠱（現有）/ 蠱王杖（可新增） |
| **刀流・巫月** | 力量 + 連擊 | （目前**無刀法卡**，需新增 3–4 張） | 刀法連擊，每段 +力量 | **巫月神刀**（需新增） |

### 需補的共通機制（對照第二章缺口）

| 機制 | 服務的流派 | 實作點 |
|---|---|---|
| **連擊 multi-hit（攻擊 N 段）** | 李劍流 / 阿刀流 / 趙劍流 | EffectResolver 加 `damage` 的 `hits` 參數 |
| **本回合出牌計數觸發** | 林劍流 | BattleController 記 `cards_played_this_turn`，新 effect kind 讀它 |
| **Thorns 反傷 state** | 林刀流 | state 加 `player_thorns`，被擊時結算 |
| **力量 ×倍率 payoff** | 李刀流 / 趙劍流 | 傷害公式已吃 power，缺「damage = base + power×k」的卡 |
| **archetype 武器遺物** | 全流派錨點 | relic_catalog 加 鬼牙刀 / 越女劍 / 靈劍 / 鳳鳴刀 / 巫月神刀（+ 對應 payoff trigger） |

### 落地優先序建議

1. **阿奴杖/刀流 pilot**：杖流 payoff 補 2 張（poison_burst 已有，最快）；刀流新增 3 張刀法卡 + 巫月神刀遺物 + **連擊機制**。一次驗證「武器分流派 + 新機制」整套流程。
2. 連擊機制做好後，**李逍遙劍流**幾乎免費獲得（御劍術系列直接套連擊）。
3. 林月如刀流（反擊）可複用 first_block_counter passive 擴成 Thorns。
4. 每條流派落地後跑 balance regression，必要時把該角色 baseline 更新並在 commit 註明「故意調整」。

### 風險與防呆

- **連擊 ×多段 vs AoE 重複觸發**：連擊每段都過 weak/vulnerable 公式，smoke test 要驗「3 段 vs 單發 3×」傷害一致性（類似既有 predict_enemy_damage 一致性測試）。
- **力量爆發 + 連擊雙吃**：避免單卡同時吃力量又多段導致指數成長；payoff 卡二擇一綁定。
- **不專精懲罰要溫和**：混 build 仍可玩，只是強度低於專精，不要硬鎖武器。

---

## 四、不間斷出牌引擎（Engine / Combo）

> **設計目標**：每位角色都要有一條「特色卡組合 + 遺物組合」能達成**不間斷出牌**（接近無限連）。
> 刻意**難組**（需湊齊稀有零件 + 薄牌），但**組得到**。是 run 的高階目標，給老手追求。

### 引擎三要素

不間斷出牌 = 三者同時成立：

1. **能量經濟**：淨零或淨正。靠 0 費牌、費用減免、或「打牌回能量」
2. **抽牌補手**：每打一張就補回來，手牌不枯竭。靠「打出[類型]牌時抽 1」的 power
3. **循環 / 薄牌**：靠卡回手、token 生成、或把起始廢牌移除讓引擎零件一直被抽到

三者缺一 → 連幾張就斷。湊齊 → 一回合打到牌庫見底。

### 四角色引擎配方（綁各自武器流派）

| 角色 | 引擎名 | 流派 | 核心迴圈 | 關鍵零件（卡 + 遺物） |
|---|---|---|---|---|
| **李逍遙** | 御劍不滅 | 劍流·連擊 | 廉價御劍攻擊 → 抽攻擊 → 回能量 | 0/1 費御劍卡 + power「打出攻擊牌抽 1」+ 遺物「每 3 張攻擊回 1 能量」 |
| **趙靈兒** | 靈息不息 | 杖流·神術 | 0 費技能循環 → 抽技能 → 回血續戰 | 風靈符(0費) + power「打出技能牌抽 1」+ 遺物「技能費用 -1 / 每 N 技回能」 |
| **林月如** | 連斬無間 | 劍流·連斬 | 0 費快斬 → 打 0 費抽牌 → 出牌數回能 | 輕劍急刺/乾坤一擲(0費) + **引魂蝶（現有：出 0 費牌多抽）** + power「本回合每第 3 張牌回 1 能量」 |
| **阿奴** | 萬蠱無盡 | 杖流·蠱蟲 | 生成 0 費蠱蟲 → 打蠱蟲抽牌 → 回能再生成 | 蠱蟲生成卡 + power「打出蠱蟲抽 1」+ 遺物「每 N 張牌回 1 能量」 |

> 林月如最接近現成（已有多張 0 費卡 + 引魂蝶遺物）；阿奴最具主題性（蠱蟲生生不息）。

### 需補的引擎零件（跨角色）

| 零件 | 作用 | 實作點 |
|---|---|---|
| **「打出[類型]牌時抽 1」power** | 抽牌補手（引擎心臟） | 每角色一張 power 卡，filter 綁該流派牌型 |
| **「打 N 張牌 / N 張某類 → 回 1 能量」** | 能量經濟（引擎燃料） | 遺物 trigger `card_played` 計數；或 power |
| **0 費卡擴充** | 降低每張能量門檻 | 各角色補 1–2 張 0 費特色卡 |
| **卡片生成（蠱蟲 token）** | 阿奴循環來源 | 新 effect kind `generate_card`（加 0 費蠱蟲到手牌） |
| **費用減免（技能→0）** | 趙靈兒引擎 | power「本回合技能 -1 費」或 Corruption 類 |
| **卡回手 / 置頂** | 循環（替代薄牌） | 新 effect kind `return_to_hand` / `put_on_draw_top` |

### 難度設計（難組但組得到）

- 引擎需**同時湊齊 2–3 個稀有零件**（draw-power + 回能遺物 + 足夠 0 費卡），不可能 turn 1 成形
- **必須薄牌**：起始牌組的高費廢牌要先在商店/事件移除，引擎零件才會穩定被抽到
- draw-power 與回能遺物**設為 rare**，靠運氣 + 取捨才湊得齊
- 每角色引擎走**不同軸**（劍=攻擊數、神術=技能數、連斬=出牌數、蠱蟲=token 數），體驗各異

### 防呆 / 平衡

- **禁止 turn-1 無限**：回能門檻設「每 3 張」而非「每 1 張」，避免零成本啟動
- **抽到底自然終止**：牌庫抽乾就停（不做無限牌生成的真無限，避免卡死 / 數值爆炸）
- **引擎成立 = run 已投資**：薄牌 + 稀有零件本身就是難度閘，不需再額外 nerf
- smoke test：寫一個「理想引擎牌組」案例，驗證一回合可打出 ≥15 張牌且不崩潰、傷害數值在預期上限內

---

## 資料來源

- [Keywords — Slay the Spire Wiki (Fandom)](https://slay-the-spire.fandom.com/wiki/Keywords)
- [Buffs — Slay the Spire Wiki](https://slaythespire.wiki.gg/wiki/Buffs)
- [Exhaust — Slay the Spire Wiki](https://slay-the-spire.fandom.com/wiki/Exhaust)
- [Energy — Slay the Spire Wiki](https://slay-the-spire.fandom.com/wiki/Energy)
- [Cards List — Slay the Spire Wiki](https://slaythespire.wiki.gg/wiki/Cards_List)

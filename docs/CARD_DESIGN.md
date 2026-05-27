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

## 資料來源

- [Keywords — Slay the Spire Wiki (Fandom)](https://slay-the-spire.fandom.com/wiki/Keywords)
- [Buffs — Slay the Spire Wiki](https://slaythespire.wiki.gg/wiki/Buffs)
- [Exhaust — Slay the Spire Wiki](https://slay-the-spire.fandom.com/wiki/Exhaust)
- [Energy — Slay the Spire Wiki](https://slay-the-spire.fandom.com/wiki/Energy)
- [Cards List — Slay the Spire Wiki](https://slaythespire.wiki.gg/wiki/Cards_List)

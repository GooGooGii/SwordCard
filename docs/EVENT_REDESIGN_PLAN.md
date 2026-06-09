# 奇遇事件重設計計劃（Event Redesign Plan）

> 目標：解決「奇遇玩起來無聊」的問題。診斷見本文件 §1，改造分階段見 §3。
> 核心發現：**runtime 已支援好玩的 `tree` schema（`main.gd:4492 _show_event_tree_node`），
> 但原本 33 個事件裡有 10 個仍跑扁平 schema = 每個事件同一組
> `heal/gain_card/power/observe/leave` 六顆按鈕、一鍵、結果固定、零風險、零後果。**

## 實作狀態（2026-06-09）✅ 已完成

| Phase | 內容 | 狀態 |
|---|---|---|
| 0 | 10 個扁平事件全數轉 `tree`（33/33 皆有樹）；`EventRunner` 擴充 deck_archetype / hp_below / hp_above / min_act / max_act / has_potion_slot / event_flag / not_event_flag 檢定；`hide_badge` 神秘選項；7 個新 smoke test | ✅ |
| 1 | 取捨化：10 個改寫事件每個都含「標價的好處」＋至少一個 `gamble`；部分 `leave`/失敗帶長尾旗標後果 | ✅ |
| 2 | 讀 build：改寫事件含 deck_archetype（毒/劍流）、hp 門檻、角色限定分歧 | ✅ |
| 3 | `RunState.event_flags`（純加欄位，不升存檔版本）＋ `set_flag` effect kind；多事件埋旗標（fox_spared/fox_slain、miao_kin、anu_family_reunion、sword_spirit_bond、nuwa_jade、lin_tomb_heir…）；**回訪 payoff 已接通一條**：隱龍窟放走狐女 → 酒館舊識她回來報恩 | ✅（infra＋示範閉環；更多人物回訪線屬持續內容擴編） |
| 4 | 稀有奇遇層級：`EventData.rarity_of` ＋ `MapGenerator.event_pick_weight` 加權降權；新增 run-defining 稀有事件「蜀山秘府」（`upgrade_all` 整副升階等大機緣） | ✅ |

> 驗證：`scripts/smoke_test.gd` 全綠（含 7 個新測試）；`render_event.gd` 實機截圖確認蜀山秘府與隱龍窟分支樹正確渲染、角色限定選項正確隱藏。
> 待補美術：稀有事件「蜀山秘府」事件插畫（見 `ART_TODO.md` §〇）。其餘改寫事件沿用原插畫。

---
> 以下為原始設計藍圖，保留供日後擴編人物回訪線時參考。

---

## 1. 診斷：為什麼無聊

| # | 問題 | 現況 | 後果 |
|---|---|---|---|
| 1 | **選項同質化** | 25/33 事件只換背景圖＋flavor 文字，機制是同一組 6 顆通用按鈕 | 玩家三次後學會「觀察永遠安全、離開永遠沒事」，停止讀字、自動點最優解 |
| 2 | **沒有取捨** | 扁平事件多為「免費的好處」（回血不扣東西、加攻不冒險） | 沒有決策，只有領取 |
| 3 | **結果可預測 + 一次性** | 點一下 → 固定 outcome 文字 → 結束；事件互不相干 | 無不確定性、無失敗、無記憶 |
| 4 | **不讀 build** | 事件幾乎只看角色換 flavor，不管牌組／遺物／血量／幕數 | 局面再不同，事件感覺都一樣 |
| 5 | **重物輕人** | 最有趣的全是有人物的事件（唐鈺、彩依、酒劍仙、比武招親）；無聊的全是「你＋一塊石壁/一眼清泉」 | 手握仙劍卡司，卻拿來寫風景 |

### 對照：知名文字仙俠 / roguelike 共同點
- **金庸群俠傳 / 俠客風雲傳**：事件綁屬性檢定（醫術/悟性/正邪值決定選項與結果）
- **鬼谷八荒 / 太吾繪卷**：人際與長尾後果（善緣惡緣回頭找你）
- **Slay the Spire（直系模型）**：風險／報酬 + 隱藏資訊 + 永久後果；稀有事件重塑整場 run
- **Reigns / Cultist Simulator**：每個選擇都在資源間拉鋸，沒有純賺的選項

→ 共同點：**有取捨、有不確定、有後果、會讀狀態、圍繞人。目前扁平事件四項全缺。**

---

## 2. 設計原則（之後新增 / 改寫事件都遵守）

1. **每個「好處」都標價**：回血→棄一張牌；加攻→下場帶 1 層虛弱；拿稀有牌→得詛咒。
2. **保留不確定性**：用 `gamble`；且**按鈕上不寫死確切數字**，讓「觀察」不再是穩贏安全鍵。
3. **多步微敘事**：每個事件至少 2–3 步、有分歧，不要一鍵到底。
4. **讀 build**：選項可受角色／牌組原型／遺物／血量／幕數 gating，且 gate 命中時有專屬獎勵。
5. **人 > 物**：環境填充減量，改寫成有角色、有對話、有立場的相遇。
6. **後果與回訪**：撿的詛咒、欠的人情、結的梁子，在後面兌現。

---

## 3. 分階段實作

### Phase 0 — 基礎設施（解鎖後面所有 Phase）
- [ ] **全面改走 tree**：`show_event_node()` 對「無 tree」的事件目前 fallback 扁平。逐一把扁平事件補上 `tree`（root + nodes），讓 `EventRunner.has_tree()` 全部回 true。扁平 schema 與 `resolve_event_*` 路徑保留為相容後援，新事件一律只寫 tree。
- [ ] **擴充 `requires` 檢定種類**（`event_runner.gd:visible_choices` + `main.gd:_event_choice_available`）：
  - 既有：`character` / `observe_token` / `min_gold` / `has_relic` / `min_deck_size` / `max_power`
  - 新增：`deck_archetype`（毒/劍/格擋/能量，由牌組標籤統計判定）、`hp_below`（瀕死才開放孤注選項）、`hp_above`、`min_act` / `max_act`（幕數）、`has_potion_slot`
- [ ] **隱藏結果**：tree choice 增加 `hide_numbers: true` 旗標，渲染時只顯示動詞與語氣（「孤注一擲」），不顯示 `+2 power`。
- [ ] **smoke test**：`_test_event_tree_coverage`（所有 variant 都有 tree、root.choices ≥ 2、leaf 都有 outcome 或 next）、`_test_event_requires_kinds`（新檢定種類解析不 crash）。

### Phase 1 — 取捨化（把免費獎勵變決策）
- [ ] 逐事件審視：每個 reward 選項補上代價或賭注（棄牌 / 下場 debuff / max_hp / 詛咒 / gold）。
- [ ] 至少 1/3 事件含 `gamble` 選項。
- [ ] `leave` 不再永遠零後果：部分事件離開有機會損失（流言、錯過、被尾隨→下場開場 debuff）。
- [ ] 重跑 balance regression（隨機 AI 不選事件，不受影響；但確認 parse / smoke 全綠）。

### Phase 2 — 讀 build（局面差異化）
- [ ] 每個事件至少 1 條 build-gated 分歧：
  - 毒流牌組 → 解鎖「下蠱 / 借毒」選項
  - 劍陣牌組 → 解鎖「以劍意共鳴」選項
  - 持特定專武/遺物 → 解鎖傳承分歧（如持龍泉劍 → 劍冢給專屬傳承）
  - 瀕死（`hp_below`）→ 解鎖高風險高報酬的孤注選項
- [ ] 角色限定分歧從目前 ~4 個事件擴到大多數事件（每角色都有專屬高光時刻）。

### Phase 3 — 人物與長尾後果（記憶點）
- [ ] **`RunState` 加 `event_flags: Dictionary`**（不升 SAVE_VERSION，`from_dict` 用 `data.get("event_flags", {})` 後援；`to_dict` 一行）。記錄「欠唐鈺人情 / 撿了某詛咒 / 與某妖立契」。
- [ ] **回訪事件**：新事件的 `requires` 可吃 `event_flag: "owe_tangyu"`；在後面的幕兌現（NPC 再現、仇家來襲、人情回報）。
- [ ] **人物事件擴編**（PAL1 卡司）：唐鈺、彩依、劉晉元、酒劍仙、拜月教徒、毒娘子線——優先於新增環境事件。
- [ ] 環境填充事件（清泉/石壁/符匣類）逐步改寫或併入人物線。

### Phase 4 — 稀有奇遇層級（run-defining）
- [ ] 事件加 `rarity: "rare"` + 低出現權重（`MapGenerator` event pool 加權）。
- [ ] 稀有奇遇能重塑整場 run：換 boss 遺物、整副牌升階、轉職式的招式池替換、解一個大詛咒換大代價。
- [ ] 給玩家「這趟遇到了不得了的東西」的記憶點（仿 StS Neow / 換 boss 遺物）。

---

## 4. 影響面 checklist

| 系統 | 處理方式 |
|---|---|
| SAVE_VERSION | Phase 3 的 `event_flags` 純加欄位，`from_dict` 後援即可，**不升版本** |
| balance regression | 隨機 AI 不主動選事件 → 不影響 baseline；只需確認 parse + smoke 全綠 |
| `EventRunner` | 擴充 `requires` 檢定種類；tree 走訪邏輯已存在，主要是補資料 |
| `main.gd` 事件渲染 | `hide_numbers` 渲染分支；新 `requires` 的可用性判定 |
| 美術 | 人物事件可借用既有肖像（見「美術資源狀況」），稀有奇遇可後補專屬圖 |
| docs | 本檔為設計守則；新事件依 §2 原則撰寫 |

---

## 5. 建議起手順序

1. **先做 Phase 0 的「全面改走 tree」+ 挑 1–2 個最扁平事件改寫成範本**（含取捨＋賭注＋一個 build/角色檢定分歧），驗證手感。
2. 範本定案後，按 Phase 1 → 2 → 3 → 4 逐批套用。
3. 每批改完跑 `godot --headless --path . -s scripts/smoke_test.gd` 確認綠燈。

> 優先級理由：Phase 0+1 投入最小、去無聊感最多（同質化與免費獎勵是主因）；
> Phase 3 的人物長尾投入最大但最能造記憶點，放後段穩紮穩打。

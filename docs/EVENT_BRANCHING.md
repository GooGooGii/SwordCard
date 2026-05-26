# 奇遇分支故事化計畫（Event Branching）

把現有 28（+3 後續新增）個 event variant 從「扁平選單」升級為**分支故事樹**：每個事件 3–5 個主選項、可進入子節點、葉節點分類為 reward / punish / battle / gamble / mixed。

> **目前實作狀態：Phase 0 — 完全未實作**。所有 Phase 1–11 的 schema / runner / curse / observe / 新 effect kinds / 戰鬥回流 / 31 個事件樹內容都還沒做。
> 現行 code 走的是**舊扁平 schema**（2 層硬切：root choices + 一層 sub_choices），詳見下方「現況對照」。
> 設計本身已凍結審稿過，實作時直接照這份文件做。

---

## 現況對照（Phase 0）

對 `docs/EVENT_BRANCHING.md` (設計) vs `scripts/event_data.gd` + `scripts/main.gd` (實作) 的逐項稽核：

| 設計項目 | 實作狀態 | 程式位置 / 缺漏 |
|---|---|---|
| 樹狀 `tree { root, nodes }` schema | ❌ 沒做 | `event_data.gd:9-734` 仍是扁平 `choices[] + sub_choices{} + outcomes{}` |
| 多層深度（3+ 層） | ❌ 只支援 2 層 | `main.gd:3060-3160` `show_event_node(sub_stage)` — 空字串 = 第一層、有值 = 第二層，無遞迴 |
| `requires.character` 過濾 | ⚠️ 部分硬寫 | 只有 3 個事件 (immortal_ruins / baiyue_altar / spirit_clan_ruins) 透過 `character_outcomes` 寫死；沒 schema 化條件 |
| `requires.min_gold` / `has_relic` / `observe_token` 過濾 | ❌ 沒做 | — |
| 葉節點 kind 徽章（reward/punish/battle/gamble/mixed） | ❌ 沒做 | UI 沒這套分類顯示 |
| Curse 牌類別（6 張） | ❌ 沒做 | `CardData.card_type` 沒 `"curse"`；無不可打/不可移除/不可升級邏輯 |
| observe token 系統 | ❌ 沒做 | `RunState` 沒 `observe_tokens` 欄位；observe 仍是免費按鈕（or 不存在） |
| 戰鬥回流（pending_event_return） | ❌ 沒做 | 事件觸發戰鬥沒設計、defeat 直接 game over |
| 新 effect kinds (gain_card_pool / lose_card / gain_curse / next_battle_buff / act_modifier / permanent_power 等) | ❌ 沒做 | `effect_resolver.gd` 還是只認舊 kinds |
| outcome 結算路徑 | ⚠️ 寫死 12 種 key | `main.gd:3484-3542` `resolve_event_heal/gain_card/power` 等硬寫的 handlers，非 schema 驅動 |
| 31 個事件 tree 內容 | ❌ 0 / 31 | 6 個已凍結設計 (spring/yokai_pact/flower_spirit/yangzhou_officer/jiang_waner_grief/baiyue_altar) 都還是舊 schema |
| 25 個待設計事件 tree | ❌ 0 / 25 | 連設計都還沒寫 |

**現況白話總結**：
- 玩家現在玩到的奇遇 = **舊版扁平兩層選單**，根本沒走 tree
- 「分支故事樹」這份文件描述的是**未來目標**，不是現狀
- 估計距離全部完成 ~3630 行 / 11 commits

---

## 五項已凍結的設計參數

1. **節點密度**：每事件 3–5 個 root 選項 + 2–3 個 sub-node（playthrough +20–30 秒/事件）
2. **戰鬥分支頻率**：28 個 event 中約 **10–12 個**有戰鬥分支
3. **Curse 牌系統**：要做。實作為 unplayable 占手牌的詛咒類卡（見「Curse 牌規格」）
4. **角色獨家路徑**：**每個事件都至少有一條某角色獨享分支**（透過 `requires.character` 過濾）
5. **observe 全 run 限定**：observe 從免費按鈕變成全 run 有限資源（見「observe Token 系統」）

---

## 統一 Schema

```gdscript
# scripts/event_data.gd 內 VARIANTS[variant] 改為：
{
    "title": "...",
    "flavor": "...",                          # 通用 flavor（fallback）
    "character_flavors": {...},               # 既有，保留
    "tree": {                                 # ← 新欄位；存在則走樹，否則 fallback 舊邏輯
        "root": {
            "prompt": "（情境描述）",
            "choices": [
                {
                    "id": "approach_kindly",
                    "label": "溫和靠近",
                    "kind_hint": "reward",    # reward / punish / battle / gamble / mixed / neutral
                                              # 用於 UI 徽章；非 outcome 本身的分類
                    "requires": {             # 可選；多條件 AND
                        "character": ["zhao_linger"],
                        "min_gold": 50,
                        "has_relic": "nuwa_shi",
                        "min_power": 3,
                        "observe_token": true,  # 此選項需消耗 observe token 才顯示
                    },
                    "next": "node_kind",      # 跳到下個節點（與 outcome 二擇一）
                    "outcome": {              # 葉節點：直接結算
                        "kind": "reward",     # 結果分類（UI 顯示用）
                        "effects": [          # 對 EffectResolver.resolve_effects_list 餵的 list
                            {"kind": "gold", "amount": 15},
                            {"kind": "damage", "amount": 4},
                        ],
                        "log": "你逼出了情報，但對方反擊讓你掛彩。",
                        "battle": {           # 若 kind == "battle"
                            "enemy_id": "怨妖_lite",
                            "enemy_hp_mult": 0.8,
                            "victory_effects": [{"kind":"gain_card_pool","pool":"rare"}],
                            "defeat_effects":  [{"kind":"damage","amount":15}],
                            # 戰敗不結束 run；用 defeat_effects 懲罰後回到地圖
                        },
                        "gamble": {           # 若 kind == "gamble"
                            "win_chance": 0.5,
                            "win_effects":  [{"kind":"power","amount":3}],
                            "lose_effects": [{"kind":"damage","amount":8}],
                        },
                    },
                },
                ...
            ],
        },
        "nodes": {                            # 非 root 節點
            "node_kind": {"prompt": "...", "choices": [...]},
            ...
        },
    },
}
```

### 葉節點 kind 與徽章

| kind | UI 徽章 | 說明 |
|---|---|---|
| `reward` | ✦ 機緣（金）| 純獲益 |
| `punish` | ⚠ 風險（紅）| 純損失（包含 lose_card / curse / max_hp -）|
| `battle` | ⚔ 戰鬥（暗紅）| 開戰，勝利/失敗各有 outcome |
| `gamble` | 🎲 賭運（紫）| 擲骰，win/lose 各有 effects |
| `mixed` | ⚖ 取捨（綠紅交錯）| 同時有得有失 |
| `neutral` | — | 純離去/無事發生 |

### 新增 effect kinds（給 EffectResolver）

| kind | 參數 | 行為 |
|---|---|---|
| `gain_card_pool` | `pool: common\|uncommon\|rare\|character\|evil` | 從對應池抽 1 張加入 deck |
| `lose_card` | `mode: random\|player_choose`, `filter?` | 強制移除一張 |
| `lose_relic` | `mode: random\|player_choose` | 強制丟一個遺物 |
| `gain_relic_pool` | `pool: common\|uncommon\|rare` | 隨機獲得遺物 |
| `gain_curse` | `curse_id` | 加一張 curse 牌到 deck |
| `gain_potion_random` | — | 隨機獲得一瓶藥（沿用 PotionCatalog）|
| `next_battle_buff` | `effects: [...]` | 給下場戰鬥開場注入 effect（block / energy / weak token）|
| `act_modifier` | `id, magnitude` | 對本 act 剩餘節點施加 modifier（例：被通緝→商店 +20%、避戰一次）|
| `permanent_power` | `amount` | 永久 power_bonus +amount（跨戰鬥）|
| `revive_ally` | `amount` | 已存在（jiang_waner / lingmiao 用）|

既有的 `heal / damage / gold / max_hp / power / poison / weak / vulnerable / upgrade_random / heal_party / remove` 全部沿用。

---

## Curse 牌規格

新牌類別 `card_type = "curse"`，定位是「占手牌格但不能/不好打」的詛咒。

### 行為

- **不可主動打**：手牌上顯示但點擊 / 拖拉都會拒絕（顯示「不能打出」）
- **不可移除**：商店「除牌」服務、wandering_sage 等 remove effect **預設不能移除 curse**
  - 例外：特定遺物（如「淨化符」）或 zhao_linger 專屬事件分支可移除
- **不可升級**
- **回合開始不抽出來** 改為**結算「滯留」效果**：留在手牌每回合給予小負面
- **戰鬥結束後留在 deck**（永久跟著 run，除非主動移除）

### MVP curse 集合（6 張）

| id | name | 來源事件 | 滯留效果（回合 start 結算） |
|---|---|---|---|
| `yao_zhai` | 妖債 | yokai_pact ①b | 回合開始時 -2 HP |
| `xie_yin` | 邪印 | baiyue_altar ①a/b | 回合開始時 +1 weak |
| `tong_ji` | 通緝 | yangzhou_officer | 戰鬥外：商店物價 +20%（act_modifier 而非滯留） |
| `hua_zhai` | 花債 | flower_spirit ② lose | 回合開始時 +1 vulnerable |
| `jiu_zui` | 醉魂 | drunk_swordsman | 回合開始時 50% 機率 -1 energy |
| `gu_du` | 殘蠱 | miao_healer / ghost_forest | 戰鬥開始時 +2 poison |

### 解除途徑

- 持有遺物「淨化符」(`jing_hua_fu`)：戰鬥結束可移除 1 張 curse（新遺物）
- 趙靈兒專屬事件 `spirit_clan_ruins` 新支線：可選擇移除所有 curse
- 商店「黑市」新增「驅邪服務」：100 銅錢移除 1 張 curse（價格隨難度層級升高）

### Smoke test 覆蓋

- curse 不能被 play_card 出去（return false）
- curse 不被 remove effect 移除（除非 force_curse=true 旗標）
- curse 滯留效果每回合 start 觸發
- curse 隨 deck 進 save round-trip

---

## observe Token 系統

observe 從免費變成**全 run 限定資源**。

### 規格

- `RunState.observe_tokens: int = 3`（起始 3 token）
- 補充途徑：
  - 每幕 boss 戰勝利 +1
  - 持有遺物「慧眼」(`hui_yan`)：起始 +2，最大上限 +2
  - 特定事件分支獎勵 +1（如 wandering_sage 觀察老者）
- 消耗：每次點 observe 扣 1
- UI：左上角狀態列加「👁 N」icon，事件畫面 observe 按鈕顯示剩餘數量
- 0 token 時 observe 按鈕灰掉（仍可看到，但無法選）

### 為何要做

- observe 之前是「無腦白拿揭露隱藏分支」，沒有策略張力
- 改成 token 後：玩家必須決定「現在看，還是留給更難判斷的事件」
- 隱藏分支變得更有價值（不再保證每次都能看見）

### 存檔遷移

`RunState.from_dict` 對 `observe_tokens` 用 `data.get("observe_tokens", 3)` fallback。不升 SAVE_VERSION。

---

## 戰鬥分支：戰鬥回流機制

事件中觸發的戰鬥不能直接結束 run，必須回到事件結算。

### 流程

1. 事件葉節點 `kind = "battle"` 時：
   - 設 `RunState.pending_event_return = {variant: "...", choice_id: "...", node_id: "..."}`
   - 設 `RunState.pending_battle_outcome_effects = {victory: [...], defeat: [...]}`
   - 呼叫 `start_next_battle(enemy)` 但旗標 `from_event = true`
2. `BattleController` 戰敗時：
   - 若 `pending_event_return` 存在：不顯示 game over，跳回事件節點，結算 `defeat_effects`
   - 否則維持現行（show_result(false)）
3. 戰勝時：結算 `victory_effects`，跳回地圖（已走過此事件節點，正常前進）

### Smoke test

- `_test_event_battle_victory_return`：事件 → 戰鬥 → 勝 → victory_effects 套用 → 地圖前進
- `_test_event_battle_defeat_return`：事件 → 戰鬥 → 敗 → defeat_effects 套用 → 不 game over → 地圖前進
- `_test_event_battle_defeat_full_party_wipe`：defeat_effects 套完仍全員 0 HP → 才 game over

---

## Phase 切分

| Phase | 內容 | 估行數 | 可平行 | 狀態 |
|---|---|---|---|---|
| **P1: Schema + Runner** | 新建 `event_runner.gd`，支援 `tree` 欄位 walk；保留舊 schema fallback；requires 過濾；UI 徽章 | ~280 | — | ⬜ 未開始 |
| **P2: Event UI 改版** | `show_event_node()` 替換 `show_event()`；支援多層回跳、葉節點結果卡片、節點導航 | ~220 | 等 P1 | ⬜ 未開始 |
| **P3: 戰鬥回流** | `pending_event_return` + `pending_battle_outcome_effects`；`start_next_battle(from_event=true)` 分支 | ~100 | 等 P1 | ⬜ 未開始 |
| **P4: Curse 牌** | `CardData.card_type = "curse"`；play_card / remove / upgrade 拒絕邏輯；6 張 curse + 滯留 hooks；淨化符遺物；黑市驅邪服務 | ~250 | 與 P1–3 平行 | ⬜ 未開始 |
| **P5: observe Token** | `RunState.observe_tokens`；UI 左上 icon；事件按鈕灰掉；boss 勝利補充；慧眼遺物 | ~120 | 與 P1–3 平行 | ⬜ 未開始 |
| **P6: 新 effect kinds** | EffectResolver 加 `gain_card_pool / lose_card / gain_relic_pool / gain_curse / next_battle_buff / act_modifier / permanent_power` | ~150 | 等 P4 | ⬜ 未開始 |
| **P7: 內容 A（10 事件）** | spring / talisman_cache / shrine / treasure_chest / ancestor_relic / wandering_sage / moonlit_pool / broken_temple / immortal_ruins / spirit_clan_ruins | ~600 | 等 P1–6 | ⬜ 未開始（spring 已凍設計） |
| **P8: 內容 B（10 事件）** | baiyue_altar / sword_tomb / miao_healer / shilipo / drunk_swordsman / yinlong_cave / yangzhou_officer / lingmiao / xianling_shrine / tavern_acquaintance | ~700 | 等 P7 | ⬜ 未開始（baiyue_altar、yangzhou_officer 已凍設計） |
| **P9: 內容 C（11 事件含戰鬥）** | yokai_pact / flower_spirit / flower_thief / ancient_battlefield / alchemy_furnace / ghost_forest / forgotten_altar / jianling_whisper / aqi_reunion / tangyu_sparring / jiang_waner_grief | ~750 | 等 P7 | ⬜ 未開始（yokai_pact、flower_spirit、jiang_waner_grief 已凍設計） |
| **P10: 戰鬥用敵人** | 4–6 個 event-only 敵人（怨妖 / 花妖本體 / 採花賊頭目 / 揚州捕頭 / 蒙面盜匪 / 拜月怨魂） | ~180 | 等 P3 | ⬜ 未開始 |
| **P11: Smoke tests** | `_test_event_tree_traversal` × 31 / `_test_event_battle_return` / `_test_event_character_gating` / `_test_event_legacy_fallback` / `_test_curse_*` / `_test_observe_token` | ~280 | 等 P7–10 | ⬜ 未開始 |

**總計：~3630 行 / 11 commits。目前進度：0 / 11。**

### Phase 進度標記慣例

- ⬜ 未開始
- 🟨 進行中（partial）
- ✅ 完成（含 smoke test 通過）

每完成一個 Phase 就更新此表 + 在 commit message 標明 `feat(event): phase N — ...`，方便日後追溯。

### 落地原則

- 每個 phase 提交後 smoke test 通過
- P1 起 schema 共存：未轉換的事件繼續走舊 flat schema
- P7–P9 內容批次可拆細，每 3–4 個事件一個 commit
- P4 (curse) 與 P5 (observe) 可在任何時點上線，不依賴內容

---

## 已凍結的 6 個事件分支樹

> ⚠️ **以下 6 個事件的「分支樹結構」目前都尚未實作**。code 內仍是舊扁平版（root 選項 → 一層 sub_choices → outcome）。實作 Phase 7–9 時直接抄這份設計。

以下是已 review 通過的設計，實作時直接抄。

### 1. `spring` 幽泉清聲

```
root: 「山壁後一眼清泉，水氣溫潤。你蹲下身——」
├─ ① 掬水而飲 [reward]
│    effects: heal +12, next_battle_buff: energy +1（一次性 token）
├─ ② 入水沐浴 → node_bathe
│    node_bathe: 「水深及腰，你閉眼浸入——感到水底有什麼在動。」
│    ├─ ②a 繼續放鬆 [gamble win=0.6]
│    │    win:  power +1, max_hp +2
│    │    lose: next_battle_buff: weak +2, gold -8
│    └─ ②b 立刻起身警戒 [reward]
│         heal +6, next_battle_buff: block +5
├─ ③ 觀察泉底 [requires observe_token] → node_observe
│    node_observe: 「水底沉著一塊磨平的玉，刻著上古符紋。」
│    ├─ ③a 取玉 [reward・稀有]
│    │    gain_relic_pool=common, gold +5
│    └─ ③b 留下不取 [reward]
│         heal +8, power +1
└─ ④ 李逍遙專屬：以師叔教的「以身合水」打坐 [requires: li_xiaoyao] [reward]
     permanent_power +1, heal +10
     log: 逍遙想起師叔的話，泉水的靈氣順著經脈走了一圈。
└─ ⑤ 離去 [neutral]
```

### 2. `yokai_pact` 妖契

```
root: 「黑霧中浮起瓜子臉。『給我一點，我給你十倍。』」
├─ ① 問代價 → node_negotiate
│    node_negotiate: 「『簡單，一滴血、一縷魂、或一段記憶。挑一個。』」
│    ├─ ①a 一滴血 [mixed]
│    │    damage 3, power +2, gain_card_pool=uncommon
│    ├─ ①b 一縷魂 [punish + reward]
│    │    max_hp -10, power +5, gain_card_pool=rare, gain_curse=yao_zhai
│    └─ ①c 一段記憶 [punish + reward]
│         lose_card mode=random（cost ≥ 2）, gain_relic_pool=uncommon
├─ ② observe [requires observe_token] → node_chain
│    node_chain: 「她背後有一條極細的黑鏈——她並非自由的。」
│    ├─ ②a 斬斷鎖鏈 [battle]
│    │    enemy: 拘魂幽差（act 同級 HP×0.8，會召喚 1 隻 black_imp）
│    │    victory: gain_relic_pool=rare, heal +10
│    │    defeat:  damage 15, max_hp -3
│    └─ ②b 假意立契反手破符 [gamble win=0.45]
│         win:  gain_card_pool=rare（不付代價）
│         lose: damage 10, weak +3, permanent_power -1
├─ ③ 阿奴專屬：以苗疆蠱術反制 [requires: anu] [gamble win=0.65]
│    win:  gain_card_pool=evil「奪魂蠱」, gold +10
│    lose: damage 8, gain_curse=gu_du
└─ ④ 離去 [neutral]
     act_modifier: 本 act 接下來戰鬥敵人 +2 攻擊（妖女的暗中報復）
```

### 3. `flower_spirit` 花妖魅影

```
root: 「幽甜花香撲鼻，霧中走出溫柔笑意的女子。」
├─ ① 屏息對抗迷香 → node_resist
│    node_resist: 「你咬破舌尖強撐清醒，看見她指尖長出花瓣與骨爪交織的妖體。」
│    ├─ ①a 拔劍直擊 [battle]
│    │    enemy: 花妖本體（HP 中，weak_all 2 / heal self 6）
│    │    victory: gain_card_pool=rare, gold +20, heal +5
│    │    defeat:  damage 15, next_battle_buff: weak 2
│    └─ ①b 點穴封香爐 [gamble win=0.55]
│         win:  gain_relic_pool=uncommon, heal +8
│         lose: damage 8, max_hp -2
├─ ② 假裝中招偷術 [gamble win=0.5]
│    win:  gain_card_pool=rare, power +1
│    lose: max_hp -5, gain_curse=hua_zhai
├─ ③ observe [requires observe_token] → node_pity
│    node_pity: 「她眼神空虛，像是身不由己。」
│    ├─ ③a 渡她清淨靈氣 [reward] [requires: power_bonus < 6]
│    │    heal +12, gain_relic_pool=common
│    └─ ③b 一劍超渡 [battle・弱化]
│         enemy: 花妖本體・哀（HP×0.7，不還手）
│         victory: power +3, max_hp +3
├─ ④ 林月如專屬：以靈劍山莊正派劍法封她 [requires: lin_yueru] [battle・智取]
│    enemy: 花妖（HP×0.6）
│    victory: gain_card_pool=character「靈劍封魔」, heal +5
│    defeat:  damage 8
└─ ⑤ 拔腿就跑 [mixed]
     heal +5, gold -10
```

### 4. `yangzhou_officer` 揚州府緝盜

```
root: 「蒙面黑影擦身而過，沉甸甸的包袱掉你腳邊。官差大喊：『站住！』」
├─ ① 收起逃跑 → node_flee
│    node_flee: 「巷弄狹窄，呼喝聲越來越近。」
│    ├─ ①a 衝進人群 [gamble win=0.55]
│    │    win:  gold +25, gain_card_pool=uncommon
│    │    lose: damage 6, gold -15, gain_curse=tong_ji
│    └─ ①b 爬上屋頂避追 [battle]
│         enemy: 揚州捕頭（擒拿術，weak+vulnerable，HP 中）
│         victory: gold +30, gain_card_pool=rare, gain_curse=tong_ji
│         defeat:  gold -20, lose_card mode=random
├─ ② 拾起交給官差 [reward]
│    gold +12, upgrade_random
│    act_modifier: 本 act 商店打折 15%
├─ ③ 一腳踢開撇清 [mixed]
│    remove mode=player_choose, gold +0
├─ ④ observe [requires observe_token] → node_chase
│    node_chase: 「包袱沾血，黑影逃向暗巷。你決定追過去。」
│    ├─ ④a 攔下審問 [battle]
│    │    enemy: 蒙面盜匪（HP 低、power 高）
│    │    victory: gain_relic_pool=rare, gold +15
│    │    defeat:  damage 10, gold -10
│    └─ ④b 放他一馬 [gamble win=0.4]
│         win:  gain_card_pool=rare（江湖再見的回禮）
│         lose: act_modifier: 本 act 結束前 ambush 戰鬥 1 場
├─ ⑤ 阿奴專屬：以蠱術追蹤包袱主人 [requires: anu] [reward]
│    gain_potion_random, gold +15, permanent_power +1
│    log: 阿奴留下一隻 tracking 蠱，循著血味找到了一個更大的秘密。
└─ ⑥ 離去 [neutral]
```

### 5. `jiang_waner_grief` 婉兒之死

```
root: 「破茅屋中年輕女子的遺體，手握刻『婉』玉佩，地上血書。」
├─ ① 讀完血書 → node_read
│    node_read: 「血書記載她被拜月教當作儀式祭品。最後一句寫到一半。」
│    ├─ ①a 立誓復仇 [reward]
│    │    permanent_power +4
│    │    act_modifier: 對拜月教系敵人傷害 +30%（本 run 永久）
│    ├─ ①b 為她超渡 [reward] [requires: zhao_linger]
│    │    remove mode=player_choose, max_hp +5
│    │    gain_card：「歸真咒」（zhao_linger 專屬靈族卡）
│    └─ ①c 苗疆送別禮 [reward] [requires: anu]
│         heal_party +15, gain_potion_random
│         act_modifier: 永久 max_potion_slots +1
├─ ② 取下玉佩 [mixed]
│    gain_relic「婉兒玉佩」（passive: 開戰 +3 block；戰敗額外 -5 gold）
├─ ③ observe [requires observe_token] → node_clue
│    node_clue: 「字跡中斷處墨跡指向北方——拜月教祭壇位置。」
│    ├─ ③a 記下方位 [reward]
│    │    act_modifier: 下個 unknown 節點揭露為 elite 且 reward +50%
│    └─ ③b 燒掉血書讓她安息 [reward]
│         remove mode=player_choose, permanent_power +2
├─ ④ 李逍遙專屬：想起餘杭那夜，撕下衣襟為她蓋上 [requires: li_xiaoyao] [reward]
│    permanent_power +2, heal +10
│    log: 逍遙不知道她是誰，但他知道，這樣的事不該再發生。
└─ ⑤ 不打擾離去 [punish]
     permanent_power -1
     log: 你回頭看了她一眼，腳步沉重。
```

### 6. `baiyue_altar` 拜月教壇

```
root: 「廢棄祭壇，血環缺一塊，黃符反書。月光下符文詭異泛光。」
├─ ① 踏入血環 → node_inside
│    node_inside: 「腳底脈動，符文發燙。你必須做出選擇。」
│    ├─ ①a 抄錄符文 [gamble win=0.5]
│    │    win:  gain_card_pool=evil
│    │    lose: damage 6, gain_curse=xie_yin
│    ├─ ①b 強行汲取邪力 [punish + reward]
│    │    max_hp -5, permanent_power +5, gain_curse=xie_yin
│    ├─ ①c 破除儀軌 [reward]
│    │    remove mode=player_choose, heal +5
│    │    if has 正派遺物: + gain_relic_pool=uncommon
│    └─ ①d observe [requires observe_token] → node_complete
│         node_complete: 「血環缺口形狀正好是一個人形。」
│         ├─ ①d-1 用自己的血補上 [battle・boss-lite]
│         │    enemy: 拜月怨魂（HP 高、會召喚、phase 2）
│         │    victory: gain_relic_pool=rare, permanent_power +3
│         │    defeat:  max_hp -8, gain_curse=xie_yin ×2
│         └─ ①d-2 用陶罐裡的舊祭血補上 [reward]
│              gain_card_pool=rare（不留 curse）
│              act_modifier: boss 戰前 -3 hp
├─ ② 從外圍施符破除 [reward] [requires: zhao_linger]
│    remove mode=player_choose ×2（且可移 curse！）
│    heal +8, max_hp +3
│    gain_card「淨化咒」（zhao_linger 專屬）
└─ ③ 離去 [neutral]
     act_modifier: 本 run 之後遇拜月信徒節點主動避戰一次
```

---

## 批次 A 凍結分支樹（6 事件，無戰鬥分支）

實作對應 P7-A 階段。每個事件至少 1 條角色獨家路徑（設計參數 4）。
這 6 個事件本質上都是「機緣 vs 風險」的取捨型小遇，無戰鬥、無 curse — 故意設計成相對低風險的早期 act 填料。

### 7. `talisman_cache` 符匣殘光

```
root: 「破舊符匣半埋土中，靈光未散。鎖鏈鏽蝕，但禁制尚在。」
├─ ① 強拆禁制取物 [gamble win=0.55]
│    win:  gain_card_pool=uncommon, heal +4
│    lose: damage 8, gain_curse=xie_yin（被殘符反噬，正派符匣意外含拜月手筆）
├─ ② 順著符紋的指引緩拆 [reward]
│    next_battle_buff: [{kind:"block", amount:5}]
│    heal +6
├─ ③ observe [requires observe_token] → node_inspect
│    node_inspect: 「符紋背面有極淡字跡：『貪者反噬』。」
│    ├─ ③a 只取藥包不動符 [reward]
│    │    gain_potion_random, gold +8
│    └─ ③b 抹除『貪者反噬』四字後再開 [reward]
│         permanent_power +1, gain_card_pool=uncommon
├─ ④ 趙靈兒專屬：以靈族文字辨識來歷 [requires: zhao_linger] [reward]
│    permanent_power +1, max_hp +3
│    log: 靈兒讀出符匣是上代修者的遺贈，溫熱沿指尖流入。
└─ ⑤ 不動，離去 [neutral]
```

### 8. `shrine` 山路異光

```
root: 「石壁間浮現微光，前人留下的靈痕，無戰意只有純粹的存在感。」
├─ ① 趨前靜立感應 [reward]
│    heal +8, permanent_power +1
├─ ② 試圖汲取靈痕 [gamble win=0.5]
│    win:  power +2, max_hp +2
│    lose: damage 5, next_battle_buff: [{kind:"weak", amount:1}]
├─ ③ 在靈痕前打坐悟法 → node_meditate
│    node_meditate: 「閉目片刻，靈光在識海中組成一段心法殘篇。」
│    ├─ ③a 跟隨心法升華某招 [reward]
│    │    upgrade_random, heal +4
│    └─ ③b 把心法純粹記下不練 [reward]
│         gain_card_pool=common, gold +5
├─ ④ observe [requires observe_token] → node_origin
│    node_origin: 「光痕的氣息與某種你熟悉的東西呼應——這位前輩，或與你有源頭關係。」
│    ├─ ④a 跪拜致意 [reward]
│    │    permanent_power +2, max_hp +3
│    └─ ④b 不領這份情，繞行而過 [reward]
│         next_battle_buff: [{kind:"block", amount:8}]
├─ ⑤ 林月如專屬：以靈劍山莊禮數行劍致敬 [requires: lin_yueru] [reward]
│    gain_card_pool=character（山莊內傳承劍意）, heal +4
│    log: 月如的劍意與壁上殘光共鳴，前輩似乎滿意地點了點頭。
└─ ⑥ 離去 [neutral]
```

### 9. `treasure_chest` 寶箱機關

```
root: 「倒塌的木箱半埋落葉，鎖鏈鏽蝕但機關未解。」
├─ ① 直接撬開 [gamble win=0.5]
│    win:  gold +25, gain_card_pool=uncommon
│    lose: damage 8, gold +5（中了毒針但搶到一點碎銀）
├─ ② 用劍鞘小心觸發機關 [reward]
│    gold +15, gain_potion_random
├─ ③ observe [requires observe_token] → node_trap
│    node_trap: 「金屬絲在箱蓋下繃緊——這是毒針機關，但設計者留了給識者的旁路。」
│    ├─ ③a 走旁路安全開鎖 [reward]
│    │    gold +20, gain_card_pool=uncommon, heal +5
│    └─ ③b 故意觸發毒針後翻箱 [punish + reward]
│         damage 6, gain_relic_pool=common, gold +10
├─ ④ 阿奴專屬：以骨針反向解蠱毒機關 [requires: anu] [reward]
│    gold +25, gain_potion_random, permanent_power +1
│    log: 阿奴認出毒針配方是苗疆親戚的手筆，骨針一挑，毒針反封自身。
└─ ⑤ 離去 [neutral]
```

### 10. `ancestor_relic` 先靈遺骨

```
root: 「古老祭壇上一具尚未化盡的骨殖，靈氣濃郁。蜷縮坐化之姿，旁有三朵乾枯小白花。」
├─ ① 虔誠供奉 + 行禮 [reward]
│    heal +10, permanent_power +1
├─ ② 取走骨殖殘片煉化 [punish + reward]
│    max_hp -3, permanent_power +3
│    log: 你感到先靈在你體內留下了一道無形的眼神，從此每次出手，他都看著。
├─ ③ observe [requires observe_token] → node_legacy
│    node_legacy: 「骨殖周圍刻有極小的字：『接得住者，即吾傳人』。」
│    ├─ ③a 跪受傳承 [reward]
│    │    gain_card_pool=rare, permanent_power +2
│    └─ ③b 婉拒，只取走那三朵乾花作念想 [reward]
│         gain_relic_pool=common, heal +8, max_hp +2
├─ ④ 林月如專屬：以靈劍山莊弟子禮認師 [requires: lin_yueru] [reward]
│    gain_card_pool=character（前輩劍意一招）, permanent_power +1
│    log: 月如跪下時聽見了一個從未見過的聲音輕喚她的名字，那是父親也未曾提起的師伯。
└─ ⑤ 不打擾，繞行 [neutral]
     log: 你向骨殖低頭一禮，繼續上路。
```

### 11. `wandering_sage` 雲遊隱士

```
root: 「竹笠下白髮垂胸的老者煮著粗茶。他抬眼掃過你，不發一語。」
├─ ① 拱手求教 → node_teach
│    node_teach: 「老者放下茶杯，慢慢說：『我能教你三樣，你只能挑一樣。』」
│    ├─ ①a 求療傷之術 [reward]
│    │    heal +18, max_hp +2
│    ├─ ①b 求精煉招式之竅 [reward]
│    │    upgrade_random, permanent_power +1
│    └─ ①c 求斬除心中雜念 [reward]
│         remove mode=player_choose, heal +5
├─ ② 沉默對坐 [reward]
│    permanent_power +2
│    log: 老者最後只說了一句：「你的劍會找到答案。」
├─ ③ observe [requires observe_token] → node_recognize
│    node_recognize: 「你細看老者煮茶的動作——精準到像練過幾十年的招式。他是高人。」
│    ├─ ③a 拜為一日之師 [reward]
│    │    gain_card_pool=rare, permanent_power +1
│    │    next_battle_buff: [{kind:"energy", amount:1}]
│    └─ ③b 不打擾，留一壺好酒作謝 [reward]
│         gold -10, observe_tokens +1, heal +6
│         log: 老者收下酒，向你抬了抬竹笠。你回頭時，他已不在那裡。
├─ ④ 李逍遙專屬：問師叔下落 [requires: li_xiaoyao] [reward]
│    gain_card_pool=character（一段御劍術新解）, heal +10
│    log: 老者眯眼笑了：「酒劍仙啊……他欠我三壺酒，你見著了替我討。」
└─ ⑤ 離去 [neutral]
```

### 12. `moonlit_pool` 月光浸水潭

```
root: 「夜色凝在潭面，倒映出比山更深的星辰。傳說潭水能洗去俗血，也能引出舊傷。」
├─ ① 沐月療養 [reward]
│    heal +15, max_hp +2
├─ ② 仰天飲一口潭水 [gamble win=0.5]
│    win:  permanent_power +2, gain_card_pool=uncommon
│    lose: max_hp -3, damage 4
│    log: 潭水有兩面——對著光是淨化，對著陰是引誘。你不知道自己接到了哪一面。
├─ ③ observe [requires observe_token] → node_double_moon
│    node_double_moon: 「水中映出的不是天上那輪，是更古老更圓滿的雙月——某個失落仙派的修行之地。」
│    ├─ ③a 以雙月為印起念 [reward]
│    │    gain_relic_pool=uncommon, heal +5
│    └─ ③b 不擾古事，靜坐至月偏 [reward]
│         observe_tokens +1, permanent_power +1, heal +8
├─ ④ 趙靈兒專屬：以靈族水德沐浴歸宗 [requires: zhao_linger] [reward]
│    heal +20, max_hp +5, gain_card_pool=character
│    log: 靈兒踏入潭中，月光把水映成銀白，那一刻她聽見了母親的聲音。
└─ ⑤ 離去 [neutral]
     log: 你向潭面拱了拱手，留下這份古意給下一個有緣人。
```

---

## 待設計的 25 個事件分支樹

按 phase 順序，後續分批 review。每批 6 個，每個約 30 行。

### 批次 A（基礎事件，無戰鬥分支為主）
- [x] talisman_cache 符匣殘光（設計凍結，見下方）
- [x] shrine 山路異光（設計凍結）
- [x] treasure_chest 寶箱機關（設計凍結）
- [x] ancestor_relic 先靈遺骨（設計凍結）
- [x] wandering_sage 雲遊隱士（設計凍結）
- [x] moonlit_pool 月光浸水潭（設計凍結）

### 批次 B（進階事件，1–2 個戰鬥分支）
- [ ] broken_temple 廢棄山神廟
- [ ] forgotten_altar 棄祭壇
- [ ] ancient_battlefield 古戰場遺跡
- [ ] alchemy_furnace 煉丹爐火
- [ ] ghost_forest 鬼林迷霧
- [ ] immortal_ruins 仙人遺址

### 批次 C（PAL1 名場面）
- [ ] spirit_clan_ruins 靈族遺跡
- [ ] sword_tomb 劍冢英靈
- [ ] miao_healer 苗疆藥師
- [ ] shilipo_sword_god 十里坡劍神
- [ ] drunk_swordsman 醉臥劍仙
- [ ] yinlong_cave 隱龍窟幽怨

### 批次 D（剩餘 PAL1 + 角色情感）
- [ ] lingmiao 靈廟顯靈
- [ ] xianling_shrine 仙靈島水月宮
- [ ] flower_thief 採花賊當道
- [ ] tavern_acquaintance 酒館舊識
- [ ] jianling_whisper 劍靈低語
- [ ] aqi_reunion 阿七的笛聲
- [ ] tangyu_sparring 石壁前的少年

---

## 風險與防呆

1. **舊存檔向後相容**：`tree` 欄位不存在 → fallback 舊 schema。SAVE_VERSION 不升。
2. **戰鬥分支 game over 漏洞**：用 `_test_event_battle_defeat_full_party_wipe` 確認全滅判定仍生效。
3. **curse 永遠拿不掉**：黑市驅邪 + 淨化符 + zhao_linger 路徑三條保底，必有移除途徑。
4. **observe token 起始 3 太少 / 太多**：playtest 後微調。28 事件平均 1 token 揭露 1 個關鍵分支。
5. **角色獨家路徑覆蓋率**：每個事件至少一條。撰寫時 grep `requires.character` 確認 28/28。
6. **內容批次完成度**：P7–P9 每批落地後立刻補 smoke test，避免一次寫太多堆積債務。

---

## 不在此 scope 的擴展

- 多 act 跨事件 callback（如「揚州緝盜放他一馬，act 3 那個人回來幫你」）
- 事件中遇到隊友新成員（party 擴員機制）
- 玩家自選 curse 在哪張卡上（curse 變成可裝備的詛咒系統）
- 多人連線分支選擇

# 多敵人系統（Multi-Enemy Mode）— 設計藍圖與 Implementation Reference

> 2026-07-08 自 CLAUDE.md 抽出，原文完整保留。功能**已完全實作**。
> 改多敵設計時更新這份文件；CLAUDE.md 只留摘要與路由，不要把本文貼回去。

多敵引擎、AOE 卡、召喚機制、召喚物、UI、smoke test 都已落地。
地圖普通戰鬥節點依 `ACT_ENCOUNTERS` 加權表生成 1–3 敵（幕 1 多為 1 敵；幕 5 最多 3 敵）。
所有引擎功能（AOE、召喚、多敵 UI、`is_summoned` 旗標）均已落地，smoke test 覆蓋 13 個多敵/召喚/遭遇組測試。

靈感來自 Slay the Spire；Boss 可以**召喚小怪**為核心新機制。

## 鎖定的設計決策

| 維度 | 決定 |
|---|---|
| 戰場規模 | **1–3 敵人**同時上場。普通節點 1–2 敵、後期 act 可 3 敵；**boss 戰開場 1 敵**（boss 可召出小怪）|
| 卡片目標 | 三種：`single`（拖到敵人 / 點 active）、`aoe`（一鍵全打）、`self`（純自身）|
| AOE 卡實作 | **新 effect kind `damage_all` / `poison_all` / `weak_all` / `vulnerable_all`**，不是 card-level flag。跟既有 effect kind 系統一致 |
| Active target | 點敵人 portrait 設定 active；hover 預覽 intent；drag 直接命中該敵 |
| Alias 策略 | `state["enemy_*"]` 永遠是「active enemy 的 alias」，自動同步。**EffectResolver 內部邏輯幾乎不用改** — 同 Party Mode 策略 |
| Action 順序 | 每敵獨立 `action_index`、`phased`；敵人回合按陣列順序逐個結算 |
| 各敵獨立 phase 2 | Boss 才有，但邏輯通用（每敵可有 phase_2_actions）|
| Loot | 戰鬥結束總和：每敵各算 1 次 gold，但召喚物不掉 loot（避免無限刷）|
| 召喚物 EXP | baseline 30% EXP（弱化版 ≈ 弱化獎勵）|
| Bestiary | 召喚物計入圖鑑（獨立 entry，跟其原型分開）|
| 阿奴開場 poison passive | 套到**全部敵人**（PAL1「下蠱」直覺一致）|
| 林月如反擊 passive | 反擊 → 打到「上一個攻擊她的敵人」（需 `state["last_attacker_index"]`）|
| 召喚上限 | 戰場同時最多 **3 敵**（含召喚物）。已滿時 boss 的召喚 action 失效（無聲 fallback 或改播 flavor log）|
| 召喚物來源 | 每個 boss 在 EnemyData 定義 `summon_pool: Array[String]`，召喚時從中隨機抽 1 |
| 召喚時機 | 透過新 effect kind `summon` 放在 boss `actions` 或 `phase_2_actions` 內，與其他招式輪替 |
| 勝利條件 | 全部敵人（含召喚物）都死才算勝。Boss 死後留下的小怪要清乾淨 |

## 資料模型

`BattleController` 從單敵改成陣列形式：

```gdscript
# 之前
var enemy: EnemyData
var action_index: int = 0
var phased: bool = false

# 之後
var enemies: Array[EnemyData] = []           # 1–3 敵，clone()'d
var enemy_action_indices: Array[int] = []    # 每敵獨立輪替
var enemy_phased: Array[bool] = []           # 每敵獨立 phase 2

# 向後相容 getter
var enemy: EnemyData:
    get:
        var idx: int = state.get("active_enemy_index", 0)
        return enemies[idx] if idx < enemies.size() else null
```

## state 結構

```gdscript
state = {
    "enemies": [
        {"name": ..., "hp": ..., "max_hp": ..., "block": 0,
         "poison": 0, "weak": 0, "vulnerable": 0,
         "intent": {...}, "loot_table": [...]},
        ...,
    ],
    "active_enemy_index": 0,
    # alias（自動同步到 enemies[active_enemy_index]）
    "enemy_name": ..., "enemy_hp": ..., "enemy_max_hp": ...,
    "enemy_block": ..., "enemy_poison": ...,
    "enemy_weak": ..., "enemy_vulnerable": ...,
    "enemy_loot_table": ...,
    "last_attacker_index": 0,  # 林月如反擊指向
    # players / energy / ... 同 Party Mode 不變
}
```

Sync 呼叫時機：
- `set_active_enemy` 之後 → `_sync_active_enemy_to_state()`
- `play_card` / `resolve_enemy_phase` 結算完 → `_sync_state_to_active_enemy()`
- 敵人死亡 / 召喚物加入 → enemies 陣列變動後 `_recompact_active_index()`

## 新 EnemyData 欄位

```gdscript
@export var summon_pool: Array[String] = []  # 召喚可挑的敵人 id；空 = 不召喚
```

## 新 effect kinds

```gdscript
"damage_all":      對全部活著的敵人各造成 amount（套用 power/weak/vulnerable）
"poison_all":      所有敵人各加 amount 蠱毒
"weak_all":        所有敵人各加 amount 虛弱
"vulnerable_all":  所有敵人各加 amount 破綻
"consume_energy_damage_all": 耗盡靈力、每點對全敵 amount 傷害
"summon":          {"kind": "summon", "count": 1[, "enemy_id": "..."]}
                   未指定 enemy_id → 從當前 boss.summon_pool 隨機抽
                   戰場已滿（>=3）→ 拒絕，log "戰場已滿" flavor
```

## 召喚機制 BattleController API

```gdscript
const MAX_ENEMIES_PER_BATTLE: int = 3

func spawn_enemy(enemy_id: String, mark_summoned: bool = true) -> bool:
    if enemies.size() >= MAX_ENEMIES_PER_BATTLE:
        return false
    var template: EnemyData = GameData.enemy_by_id(enemy_id)
    if template == null:
        return false
    var clone: EnemyData = template.clone()
    enemies.append(clone)
    enemy_action_indices.append(0)
    enemy_phased.append(false)
    state["enemies"].append({
        "name": clone.display_name,
        "max_hp": clone.max_hp,
        "hp": clone.max_hp,
        "block": 0, "poison": 0, "weak": 0, "vulnerable": 0,
        "intent": {}, "loot_table": GameData.loot_table_for(clone.id),
    })
    add_log("%s 召喚出 %s！" % [_enemy_display_name(), clone.display_name])
    return true
```

`GameData.enemy_by_id(id)` 是註冊表 helper。
第二參數 `mark_summoned` 預設 true（召喚物：無 loot、`is_summoned` 旗標）；boss 接續 successor 用 `spawn_enemy(id, false)` 召出非召喚物、照常掉落。

## 弱版 EnemyData（召喚物用）

| ID | display_name | HP | 招式（示意） | 用於 |
|---|---|---|---|---|
| `water_tentacle` | 水妖觸手 | 22 | 鞭打 6 / 防 8 / 纏繞 weak 2 | 拜月教主 phase 2 |
| `red_eye_imp` | 赤眼幼魈 | 18 | 撓擊 5 / 怒吼 weak 1 | 赤眼山魈 phase 2 |
| `tower_wisp` | 鎖妖塔殘魂 | 16 | 魂吸 4+poison 1 | 山靈巫后 phase 2 |
| `centipede_brood` | 蜈蚣幼蟲 | 14 | 啃噬 4+poison 2 | 蜈蚣大王 phase 2 |
| `zombie_thrall` | 殭屍奴 | 20 | 抓撲 6 / 守 5 | 殭屍大帥 phase 2 |

5 個召喚物，每個 boss 至少 1 種可召喚物。Bosses 的 `summon_pool` 對應補上。

## UI 變動範圍

- **enemy_row**：水平 row，最多 3 個 portrait（單敵時居中、保留現在 1v1 視覺）
- **active 高亮**：金色邊框；其他敵半透明，hover 時 modulate 提亮
- **每敵獨立**：HP bar / block badge / status line / intent badge / feedback label
- **drag-to-play**：拖到任一 portrait hit box → 命中該敵
- **AOE 卡 drag**：拖出手牌區即可（不需要指定目標）；視覺上 3 敵同時 flash
- **召喚動畫**：新敵 portrait scale 0.7→1.0 + alpha 0→1，0.4s fade-in
- **多敵 enemy_row layout**：3 敵時自動縮 portrait size（從 200x200 → 160x160）；compact mode 再縮 20%
- **CardFormat.predict_enemy_damage**：實作維持 2 參數 `(action, state)`，透過 `enemy_*` alias 預測 active 敵；藍圖原訂的第三參數 `enemy_index`（per-enemy 預測）**未實作**

## EffectResolver 改動

`_resolve_effect` 對 `damage / poison / weak / vulnerable` 仍透過 `state["enemy_*"]` alias 結算（指向 active）。
`*_all` kinds 直接遍歷 `state["enemies"]` 陣列，每敵套同樣公式。

```gdscript
"damage_all":
    var amount = int(effect.get("amount", 0))
    for i in range(state["enemies"].size()):
        var enemy_slot = state["enemies"][i]
        if int(enemy_slot["hp"]) <= 0:
            continue
        _resolve_damage_on_enemy_slot(enemy_slot, amount)
```

`_resolve_damage_on_enemy_slot` 是從現有 damage 邏輯抽出的 helper。

## Save migration

**不升 `SAVE_VERSION`**。戰鬥中的 state 不存在 savegame.json 裡（只存 run 進度），所以多敵改動對存檔格式無影響。

## MapGenerator + encounter 表

```gdscript
const ACT_ENCOUNTERS: Dictionary = {
    1: [
        {"enemies": ["bandit"],       "weight": 4},
        {"enemies": ["beast"],        "weight": 4},
        {"enemies": ["bandit_pup", "bandit_pup"], "weight": 2},  # 雙弱敵
    ],
    2: [...],
    # ...
}
```

`MapGenerator.choose_enemies_for_act(act, pool)` → 加權隨機選一組（替代既有 `enemies_for_act` 的單敵選法）。

## 影響面 checklist

| 系統 | 怎麼處理 |
|---|---|
| `_simulate_random_battle` | 接受 `Array[EnemyData]`，內部單敵就退化成現行為 |
| balance_matrix.gd | 同上；加多敵 scenarios |
| `BALANCE_BASELINES*` | 單敵情境不變；新增 multi-enemy 組 baselines |
| `_test_balance_leveled_progression` | 不變（boss 永遠 1 敵，但要考慮召喚物影響） |
| `loot_table_for` | 召喚物無 loot（spawn_enemy 把 loot_table 設空陣列）|
| `_battle_gold_reward` | 加總所有死敵的 loot；召喚物不計 |
| 阿奴 battle_start poison passive | 套到全部敵人；spawn_enemy 不觸發（避免無限刷毒）|
| 林月如 first_block_counter passive | 用 `last_attacker_index` 指定目標 |
| Boss `phase_2_display_name` 變身 | 不變（每敵獨立 phased flag）|
| Bestiary | 召喚物各自獨立 entry |
| Debug menu | 「Spawn Test Minion」快捷 |

## 實作狀態

| Phase | 內容 | 狀態 |
|---|---|---|
| 1+2. 資料層 + AOE | BattleController state 陣列化（`enemies` / `enemy_action_indices` / `enemy_phased`）、alias 同步（`_sync_active_enemy_to_state` / `_sync_state_to_active_enemy`）、EffectResolver 加 `*_all` kinds | ✅ 完成 |
| 3+3.5. 多體回合 + 召喚 | per-enemy `action_index` / `phased` / intent；`summon` effect kind + `spawn_enemy()` + `_process_pending_summons()` + `EnemyData.summon_pool` + `GameData.enemy_by_id()` | ✅ 完成 |
| 4. 戰鬥 UI | `enemy_row_container`、active 高亮、`set_active_enemy`、drag 命中個別敵、召喚物加入後 `_rebuild_enemy_row_in_place` | ✅ 完成 |
| 5+8. 內容 | 5 弱版召喚物 EnemyData（centipede_brood / tower_wisp / red_eye_imp / zombie_thrall / water_tentacle）+ 5 boss `summon_pool` + AOE 卡（萬劍訣 / 氣劍指 / 御蜂術 用 `damage_all`） | ✅ 完成 |
| 6+7. 測試 | 12 個 smoke test（setup / damage 路由 / AOE / partial kill / set_active / 多體回合 / per-enemy phase / summon basic+cap+unknown+from_pool） | ✅ 完成 |
| 地圖遭遇組 | `ACT_ENCOUNTERS` 加權表 + `choose_enemies_for_act()` + 接進 `_make_map_node` / `start_next_battle` + smoke test | ✅ 完成 |

## Smoke test 覆蓋（已實作）

- `_test_multi_enemy_setup` — 3 敵 setup → state["enemies"].size() == 3、alias 同步到 enemies[0]
- `_test_multi_enemy_damage_routing` — 單體 damage 只打 active；切換 active 後再打、原敵 HP 不變
- `_test_multi_enemy_aoe_damage` — damage_all → 全敵 HP 同步扣
- `_test_multi_enemy_aoe_status` — poison_all / weak_all / vulnerable_all → 全敵各加狀態
- `_test_multi_enemy_partial_kill` — 中間敵死後 → enemies 陣列重組 / active_index 修正
- `_test_multi_enemy_set_active` — set_active_enemy 切換 + alias 重新指向
- `_test_multi_enemy_turn_each_attacks` — 敵人回合按陣列順序逐個結算
- `_test_multi_enemy_per_enemy_phase` — 每敵獨立 phase_2 觸發
- `_test_summon_basic` — spawn_enemy → enemies +1、state 同步、log 出現
- `_test_summon_cap` — 已 3 敵時 spawn → 拒絕，回傳 false
- `_test_summon_unknown_id` — spawn 不存在 id → 拒絕
- `_test_summon_from_boss_pool` — boss summon_pool 隨機抽召喚物；新增敵 `is_summoned == true`
- `_test_map_encounter_groups` — act 1–5 地圖 battle 節點都有 enemies 陣列；act 4 百次中出現 2 敵以上

## 風險與防呆

1. **Alias 漂移**：active 切換後 alias 沒同步 → 狀態錯亂。
   **對策**：smoke test 寫「打卡 → 切 active → 打卡 → 切回 → 確認原敵 state 保留」。
2. **AOE 卡完全 break baseline**：改卡瞬間舊 baseline 全失效。
   **對策**：baseline 保留；改卡後立即重跑、新 baseline 與舊並存。
3. **多目標卡動畫複雜**：3 敵同時受擊很亂。
   **對策**：AOE 卡飛中央、3 敵同步 flash + shake；單體卡飛指定敵不變。
4. **召喚物無限刷**：boss 每回合都召 → 戰場永遠滿。
   **對策**：MAX_ENEMIES_PER_BATTLE = 3；boss 召喚 action 在 action_index 輪替中佔比 ≤ 1/4。
5. **召喚物拖戰**：玩家把 boss 打到剩 1 HP，boss 一直召喚拖時間。
   **對策**：召喚物可被 AOE 一鍋端；boss 死後不再有新召喚（即使其他敵還活著）。
6. **UI mobile 擠壓**：3 敵在小螢幕擠在一起。
   **對策**：3 敵時自動縮 portrait；compact mode 再縮 20%。
7. **存檔向後相容**：戰鬥中 state 不存檔，無影響。

## 已知未實作 / 之後再說

- 召喚物可被「魅惑/控制」反過來幫玩家打 boss
- 多敵戰場的 boss action targeted 指定（boss 打 active vs 打全隊）— MVP 先用既有 player_* alias 套用
- 多敵 boss（2 boss 同場）— scope 太大，目前一律 1 boss
- 召喚物獨立的 phase 2 — 弱化版不需要
- 玩家「召喚」卡（如召喚劍靈助戰）— 需要新 effect kind `summon_ally`，留給未來

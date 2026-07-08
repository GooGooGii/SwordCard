# Party Mode（組隊）— 設計藍圖與 Implementation Reference

> 2026-07-08 自 CLAUDE.md 抽出，原文完整保留。功能**已完整實作**。
> 改組隊設計時更新這份文件；CLAUDE.md 只留摘要與路由，不要把本文貼回去。

組隊功能已實作。**主備制**（active 1 人 + 後排 0–2 人），最多 3 人組隊。下面內容是 implementation reference；改設計時請更新。

## 鎖定的設計決策

| 維度 | 決定 |
|---|---|
| 戰鬥模型 | **主備制（Pokemon 風）**：1 人 active 上場、最多 2 人後排，只有 active 被打 / 出牌 |
| 隊伍大小 | **1–3 人自由**。1 人 = 現在的單機體驗，組隊是 opt-in |
| Deck | **每角色獨立** draw / discard / hand（per-character `DeckManager`）|
| 死亡角色 | **保留在備位**（HP=0 不可上場、不會被踢出隊伍）；未來可被「復活卡 / event」救回 |
| 專武 | **每人各拿自己的** starter weapon（`add_relic(weapons_for_character(char.id)[0])` for each）|
| 重複角色 | **不允許**，同 character ID 唯一 |
| 隊長 | `characters[0]` 永遠是隊長；character select 時可改順序，run 開始後鎖死 |
| 存檔 | SAVE_VERSION **1 → 2**，要寫 migration |

## 預設數值（實作時可調）

- **Energy**：`3 + (party_size - 1) / 2` → 1 人 3、2 人 3、3 人 4
  （2026-06 P2-10 修正：原 `3+(n-1)` 實測組隊 vs 中段 boss 勝率 100% 白給；
  敵 HP 補正單獨拉不動——×2.4 血量 3 人隊仍 97%，tempo 才是瓶頸）
- **敵 HP 組隊補正**：每多 1 名隊員 ×(1+0.85)（`BattleController.PARTY_ENEMY_HP_STEP`）
  （2026-06-30「免費勝利」修正：0.35→0.85；單拉敵 HP 對 duo 的毒 synergy carry 無效、只壓得動 trio——
  trio 100→63，duo 仍 97。詳見 `docs/BALANCE_REPORT.md` §九）
- **後排回血**：每回合 turn-end，活著的後排（HP > 0）+ 1 HP（封頂 max_hp）
  （2026-06-30：2→1，削組隊免費續航）
- **切換成本**：每回合可免費切 1 次；同回合再切要花 1 energy；**切入者 +2 護體**（P3-11 主動切人誘因）
- **Active 戰死**：強制免費 switch 到第一個活著的後排；全滅才 `is_defeat`

## 資料模型

`RunState` 從單角色改成陣列形式：

```gdscript
# 之前
var character: CharacterData
var hp / max_hp / power_bonus: int
var deck: Array[CardData]

# 之後
var characters: Array[CharacterData] = []           # 1–3 人，characters[0] 是隊長
var character_hps: Array[int] = []
var character_max_hps: Array[int] = []              # 已套 ascension starting_hp_multiplier
var character_power_bonus: Array[int] = []          # power 是 per-char buff
var character_decks: Array[Array[CardData]] = []    # 每人獨立 deck
var active_character_index: int = 0
# relics / gold / encounter_index / pending_rest_heal / ascension_level / map_seed 維持全隊共用
```

## BattleController 改動策略

**最低破壞性原則**：保留 `state["player_*"]` 作為「指向當前 active player 的 alias」，每次 switch 時 `_sync_state_to_active()` 寫回陣列、再 `_sync_active_to_state()` 把新 active 拷貝到 alias。**EffectResolver 內部邏輯幾乎不用改**。

```gdscript
state = {
    "energy": ...,
    "enemy_*": ...,
    "players": [
        {"name": ..., "hp": ..., "max_hp": ..., "block": 0, "poison": 0, "weak": 0, "vulnerable": 0, "power": ...},
        ...,
    ],
    "active_player_index": 0,
    "switched_this_turn": false,
    "player_hp": ..., "player_block": ...,  # alias，自動同步
}
var decks: Array[DeckManager] = []
func active_deck() -> DeckManager: return decks[state["active_player_index"]]
```

Sync 呼叫時機：
- `start_turn` / `play_card` / `resolve_enemy_phase` 結束 → `_sync_state_to_active()`
- `switch_active` 之後 → `_sync_active_to_state()`
- `start_turn` 開頭 → 後排回血 + reset `switched_this_turn`

`is_defeat` 改成「全員 HP <= 0」；active 戰死時 `_check_battle_end` 先試 `_force_switch_to_first_alive`。

## Save migration v1 → v2

```gdscript
match version:
    0: pass  # legacy v0 視為 v1
    1:
        data["character_ids"] = [data.get("character_id", "")]
        data["character_hps"] = [int(data.get("hp", 0))]
        data["character_max_hps"] = [int(data.get("max_hp", 0))]
        data["character_power_bonus"] = [int(data.get("power_bonus", 0))]
        data["character_decks"] = [data.get("deck", [])]
        data["active_character_index"] = 0
        # 舊 keys 留著不刪，from_dict 不會讀它們
```

`SaveManager.SAVE_VERSION += 1`，`RunState.from_dict` 只看新版 keys。

## UI 變動範圍

- **character_select**：多選 + 排序（先選的自動成為隊長，可上下移）。最多 3 人勾選才能「出戰」
- **battle 畫面**：active portrait 維持原大小；左側豎排 1–2 個後排小頭像（90×90）+ 小 HP 條；點後排頭像 = `switch_active(該 index)`，死亡 / 同人灰掉
- **left_dock**：加「切換 1/1 免費」狀態文字
- **show_progress_screen 狀態列**：改顯示「李 30/40 · 趙 25/35 · 林 0/40」三人 HP
- **手牌**：只顯示 active 的（其他角色 deck 在他們各自的 draw pile）

## 影響面 checklist

| 系統 | 怎麼處理 |
|---|---|
| `Ascension.starting_hp_multiplier` | 對每個 `character_max_hps[i]` 各乘一次 |
| `Ascension.enemy_hp_multiplier` | 不變（敵人血量不依隊伍 size scale）|
| Relic `acquire_triggers` 的 `max_hp_bonus` | MVP：給隊長；之後可改全隊 |
| `_battle_gold_reward` | 不變（全隊共享 gold）|
| `_dbg_full_heal` | 滿血所有角色 |
| `_dbg_add_card` | 加到 active 角色的 deck |
| `show_result` | victory = 走完最後一層即可（不要求全員活）；defeat = 全員 HP <= 0 |
| balance regression test | 加 1 人 / 2 人 / 3 人三組 baseline |
| Bestiary / map / event / shop | 不變 |

## 實作狀態

**已完整實作（所有 Phase 完成）。**

| Phase | 內容 | 狀態 |
|---|---|---|
| 1. 資料層 | RunState 陣列化、property aliases、SaveManager v1→v2 migrate | ✅ 完成 |
| 2. BattleController | `state.players` + `decks` + `_sync_*` + `switch_active` + 後排回血 + 全滅判定 + active 死自動切 | ✅ 完成 |
| 3. character select | 多選 + 排序 + 隊長 ★ + 出戰按鈕 | ✅ 完成 |
| 4. battle UI | 後排頭像 widget（`bench_strip`，點擊切換）+ active 肖像/HP/狀態 hot-swap + 切換次數提示 | ✅ 完成 |
| 5. ascension/relic/UI 整合 | 主選單存檔摘要、map status popup、debug full heal（全隊）、retry 全隊回滿 | ✅ 完成 |
| 6. 測試補強 | smoke test：round-trip / save migrate / switch / state sync / 自動切人 / 專武 | ✅ 完成 |

## Smoke test 覆蓋

- `_test_party_round_trip` — 3 人隊 RunState ↔ dict round-trip
- `_test_save_migration` — v1 單角色存檔 → v2 1 人隊伍（character_decks 不丟卡）
- `_test_party_switch_and_defeat` — energy=5、第一次切免費、第二次扣 1、全滅 = `is_defeat`
- `_test_party_state_sync` — 切換 → 狀態跟著角色 slot 走（切回原人 block/poison 保留）
- `_test_party_auto_switch_on_death` — active 死 → `_force_switch_to_first_alive`；全滅才 defeat
- `_test_party_starter_weapons` — 每人都拿到自己的專武（如有定義）

## 已知未實作 / 之後再說

- 復活機制（卡片 / event 救回倒下的後排）— 死人停留在隊伍中等待救援的基礎結構已就緒
- 多人隊 balance regression baseline — 隨機 AI 不會主動切換，跑出來不太能反映實戰
- 切換時的視覺過場動畫（目前是 portrait hot-swap）

## 風險與防呆

1. **EffectResolver 同步 bug**：`_sync_*` 漏欄位 → 狀態錯亂。
   **對策**：smoke test 寫「切換 → 打卡 → 切回 → 確認原 player 狀態被保留」測試。
2. **存檔遷移漏欄位**：v1 → v2 漏 `character_decks` → 老存檔載入後 deck 空。
   **對策**：migration test assert `restored.character_decks[0].size() > 0`。
3. **平衡崩盤**：3 人隊預期戰力 1.5×–2× 單人。
   **對策**：先不改 enemy HP，跑 balance regression 看實際勝率變化、再決定要不要 scale。
4. **死亡角色卡塞滿手牌**：因為每人獨立 deck，**死人的 deck/hand 不會被別人抽到**，無此問題。

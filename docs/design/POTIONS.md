# 藥品系統（Potions）— 設計藍圖與 Implementation Reference

> 2026-07-08 自 CLAUDE.md 抽出，原文完整保留。功能**已完整實作（所有 Phase 完成）**。
> 改藥品設計時更新這份文件；CLAUDE.md 只留摘要與路由，不要把本文貼回去。

## 鎖定的設計決策

| 維度 | 決定 |
|---|---|
| 攜帶上限 | **3 格**（固定；未來遺物可擴到 4） |
| 使用時機 | **戰鬥中任意時刻**（自己回合或敵人回合皆可；不消耗靈力） |
| 戰鬥外使用 | **不允許**（藥效設計假設在戰場才有意義） |
| 丟棄 | 戰鬥外長按藥格可丟棄（清出格子） |
| 稀有度 | common / uncommon / rare，決定效果強度與售價 |
| 同格疊放 | **不允許**（每格只能放 1 瓶） |
| Save | `RunState.potions: Array[Dictionary]`，存 id + 暫無其他欄位 |

## 藥品清單（共 37 種；single source = `scripts/potion_catalog.gd`，smoke test 鎖死數量 == 37）

下表須與 `PotionCatalog.all()` 同步；新增 / 改藥時兩邊一起改。

| 藥品名 | 效果 | 稀有度 |
|---|---|---|
| 回春丹 | 回復 15 HP | common |
| 靈力丹 | 本回合靈力 +2 | common |
| 護體符 | 獲得 10 護體 | common |
| 解毒散 | 清除所有蠱毒 | common |
| 麝香丸 | 清除所有負面狀態 | common |
| 雄膽酒 | 攻擊力 +2，但受 1 層虛弱 | common |
| 血海丹 | 回復 8 HP ＋ 5 護體 | common |
| 天師符 | 對敵造成 10 傷害 ＋ 1 破綻 ＋ 1 虛弱（攻擊型） | common |
| 霹靂子 | 對單一敵人造成 12 傷害（攻擊型） | common |
| 解毒草 | 清除所有蠱毒 ＋ 回復 3 HP | common |
| 靈蛇膽 | 施加敵人 3 層破綻 | uncommon |
| 虎骨酒 | 本場戰鬥攻擊力 +3（power） | uncommon |
| 金瘡藥 | 回復 30 HP | uncommon |
| 仙茶散 | 抽 2 張牌 | uncommon |
| 靈芝丹 | 本回合靈力 +1 ＋ 抽 1 張牌 | uncommon |
| 伏魔香 | 所有敵人 2 層虛弱（AOE） | uncommon |
| 山花蜜酒 | 全隊回復 10 HP | uncommon |
| 毒活丸 | 所有敵人 3 層蠱毒（AOE） | uncommon |
| 火靈珠 | 對單一敵人造成 20 火傷（攻擊型） | uncommon |
| 雷靈珠 | 對所有敵人各造成 11 雷傷（攻擊型 AOE） | uncommon |
| 天靈丹 | 回復 50 HP | rare |
| 仙人遺血 | 回復 40 HP ＋ 本場攻擊力 +2 | rare |
| 月魂草 | 抽 3 張牌 ＋ 本回合靈力 +1 | rare |
| 百花仙釀 | 回復 25 HP ＋ 清除所有蠱毒 | rare |
| 九節菖蒲 | 救回第一個倒下後排（回 15 HP）；無人倒下則自回 15 HP | rare |
| 龍涎石 | 獲得 25 護體 | rare |
| 神仙茶 | 本回合靈力 +3 | rare |
| 紫金丹 | 全隊回復 20 HP ＋ 清除所有負面狀態 | rare |
| 女媧玉露 | 回復 30 HP ＋ 本場攻擊力 +3 | rare |
| 金蠶王 | 當前角色等級 +1，立即習得該等級招式 | rare |
| 焚天珠 | 對所有敵人各造成 18 傷害 ＋ 2 蠱毒（攻擊型 AOE） | rare |
| 定身符 | 對敵造成 6 傷害 ＋ 暈眩 1 回合（攻擊型・控制） | uncommon |
| 封靈符 | 封印敵人法術 2 回合（禁言・控制） | uncommon |
| 迷魂蠱 | 使敵人瘋魔 1 回合（失控隨機攻擊・控制） | rare |
| 分身丹 | 下一張攻擊或技能牌效果發動兩次（build-enabler） | rare |
| 仙人遺蛻 | 本場戰鬥瀕死時自動回復 25 生命並存活（僅一次） | rare |
| 混元丹 | 本回合手牌費用全部視為 0（爆發 combo turn） | rare |

對應 effect kind：`damage` / `damage_all` / `heal` / `heal_party` / `energy` / `block` /
`power` / `draw` / `cure_poison` / `cure_debuff` / `vulnerable` / `weak` / `weak_all` /
`poison_all` / `revive` / `level_up` / `stun` / `silence` / `berserk` / `next_card_double` / `revive_charge` / `free_turn`。戰鬥外可用性由 `PotionCatalog.usable_outside_battle()` 判定
（含 `heal` / `heal_party` / `max_hp` / `level_up` 等戰鬥外仍有價值的 kind）。

## 資料模型

`scripts/potion_catalog.gd`：

```gdscript
class_name PotionCatalog
extends RefCounted

static func all() -> Array[Dictionary]:
    return [
        {"id": "huichun_dan",  "display_name": "回春丹",  "rarity": "common",
         "description": "回復 15 點生命。",
         "effects": [{"kind": "heal", "amount": 15}]},
        {"id": "lingli_dan",   "display_name": "靈力丹",  "rarity": "common",
         "description": "本回合靈力 +2。",
         "effects": [{"kind": "energy", "amount": 2}]},
        # ... 其餘依表格補齊
    ]

static func by_id(id: String) -> Dictionary:
    for p in all():
        if p["id"] == id:
            return p
    return {}

static func price_of(potion: Dictionary, is_black_shop: bool) -> int:
    var base: int = 40
    match potion.get("rarity", "common"):
        "uncommon": base = 65
        "rare":     base = 95
    if is_black_shop:
        base = int(ceil(base * 1.2))
    return base
```

`RunState` 欄位（不升 SAVE_VERSION，`from_dict` 用 `data.get("potions", [])` 回退空陣列）：

```gdscript
var potions: Array[Dictionary] = []   # max 3 元素，每個是 PotionCatalog.all() 的一筆
```

`to_dict()` / `from_dict()` 各一行：
```gdscript
# to_dict
result["potions"] = potions.duplicate()
# from_dict
potions = []
for p in (data.get("potions", []) as Array):
    potions.append(p as Dictionary)
```

## 戰鬥中 UI

`_build_battle_scene()` 在 left_dock 最上方（能量珠上面）的「藥格列」：

```
[藥格 0] [藥格 1] [藥格 2]
```

- 各格 **48×48**（compact: 38×38），有瓶子圖示或名稱縮寫
- 空格顯示灰色虛線框
- 點擊已有藥 → 立即使用，呼叫 `_use_potion(slot_index)`
- `_use_potion(i)` 流程：
  1. 取出 `run_state.potions[i]`
  2. 呼叫 `battle.resolver.resolve_effects_list(effects, battle.state)`
  3. `run_state.potions.remove_at(i)`
  4. `_refresh_battle()`（刷新 HP、Block、Energy 顯示）
  5. `DamagePopup.spawn(...)` 顯示效果數字

戰鬥外（地圖/事件/商店）：左上角或固定位置顯示 3 個小藥格；長按可丟棄，無點擊使用。

## 商店整合

`show_shop_node()` 在 services_row 旁邊的「藥品列」，最多展示 **2 瓶**隨機藥品：

- 由 `ShopInventory.build_potions()` 生成（從 `PotionCatalog.all()` shuffle 取 2）
- 藥格顯示名稱＋價格＋「購買」按鈕
- 背包滿（已有 3 瓶）時按鈕 disable，tooltip 提示「藥格已滿」
- `run_state.current_shop_potions` 存放本次商店的藥品快照（同 `current_shop_inventory` 的模式）
- `shop_discount` relic 效果同樣套用到藥品售價

## EffectResolver 擴充

Public helper（讓藥品和未來其他系統也能呼叫）：

```gdscript
func resolve_effects_list(effects: Array, state: Dictionary) -> Array[String]:
    var log_lines: Array[String] = []
    for effect: Dictionary in effects:
        log_lines.append_array(_resolve_effect(effect, state))
    return log_lines
```

`_resolve_effect` 支援的藥品特有 kind：
- `"cure_poison"`：清除 `state["player_poison"] = 0`
- 其餘（heal / energy / block / power / draw / vulnerable / weak）已有支援，直接複用

## Save migration

不升 `SAVE_VERSION`。`from_dict` 對 `potions` 用 `data.get("potions", [])` 回退即可。
若未來重構 potions 結構（例如加 charges 欄位）才升版本。

## 實作狀態

| Phase | 內容 | 狀態 |
|---|---|---|
| 1. 資料層 | `potion_catalog.gd`（37 種藥）＋ `RunState.potions` + to/from_dict | ✅ 完成 |
| 2. EffectResolver | `resolve_effects_list()` helper + `cure_poison` kind | ✅ 完成 |
| 3. 戰鬥 UI | left_dock 藥格列 + `_use_potion()` + 確認 overlay + 戰鬥外 `_potion_overlay` | ✅ 完成 |
| 4. 商店整合 | `ShopInventory.build_potions()` + 商店藥品列 + 購買確認 + 丟棄功能 | ✅ 完成 |
| 5. 來源補充 | 戰鬥後掉落（一般 20%、boss 60%）＋ event_data 多處 `gain_potion` | ✅ 完成 |
| 6. 測試補強 | 5 個 smoke test 覆蓋 catalog / round-trip / heal / cure_poison / 舊存檔相容 | ✅ 完成 |

## Smoke test 覆蓋

- `_test_potion_catalog` — 37 種藥都有 id / display_name / effects，PotionCatalog.by_id 能找到
- `_test_potion_save_roundtrip` — RunState 放 2 瓶藥 → to_dict → from_dict → 藥品保留
- `_test_potion_use_heal` — 戰鬥 state 接 resolve_effects_list(heal 15) → player_hp 正確增加
- `_test_potion_cure_poison` — 有 3 層蠱毒 → 使用解毒散 → player_poison = 0
- `_test_potion_old_save_compat` — 無 potions 欄位的舊存檔 → from_dict 不 crash，potions = []

## 影響面 checklist

| 系統 | 處理方式 |
|---|---|
| 平衡 regression | 不影響（測試用固定 AI，不主動用藥） |
| Debug menu | 「Give Random Potion」快捷按鈕 |
| Bestiary / map | 不變 |
| 遺物 `max_potion_slots` | Phase 1 不加；預留 `RunState.max_potion_slots` 屬性供未來遺物用 |
| 戰鬥外丟棄 UI | Phase 3 一起做；地圖畫面右側固定小格 |

## 已知未實作 / 之後再說

- 戰鬥中使用動畫（DamagePopup 已夠用，目前無需補）
- 丟棄確認 dialog（直接點按鈕丟棄，不另加 confirm）
- 多人隊藥品使用對象（MVP：效果只作用在 active 角色；heal 系列之後可改成「選擇目標」）

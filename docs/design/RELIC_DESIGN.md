# 遺物系統優化設計（2026-07）

> 依據：`docs/reference/STS_RELICS.md`（STS 全 180 件遺物參考表＋差距分析）。
> 原則：每件新遺物先過三根設計支柱（CLAUDE.md）；PAL1 素材優先，不足才自創（風格一致）。
> 實作紀律：先做零引擎改動的 catalog 批次（Batch A），再做需要 main.gd 接線的 run 層批次（Batch B），Boss 代價系留後續（Batch C）。

## 現況診斷（2026-07-08 盤點）

- 遺物 79 件：63 通用 + 10 專武 + 6 Boss 神器（`scripts/relic_catalog.gd`；檔頭註解 71 已過時）
- 稀有度倒掛：common 13 / uncommon 32 / rare 28 / legendary 6——common 池太薄，前期掉落驚喜感不足
- 帶代價遺物僅 5 件（STS 光 Boss 池就 11 件「+1 能量＋run 層代價」）→ 支柱 3 缺口
- run 層互動 `permanent` kind 僅 4 種（shop_discount / rest_heal_bonus / event_power_bonus / card_reward_count_bonus）→ 支柱 1「旅程感」缺口
- 四角色**沒有 common 級專屬遺物**（專武全是 uncommon/rare）→ 支柱 2 早期 archetype 體感缺口
- **掉落與商店均勻抽選、無稀有度權重**（`main.gd:3912` `_try_random_relic_drop`、`main.gd:6766` `_pick_shop_relic_ids`）：rare 與 common 出現率相同，稀有度目前只影響價格。STS 是 50%/33%/17%

## Batch A — 純 catalog 批次（8 件，零引擎改動）✅ 本次實作

全部使用既有 effect kind 與 filter pattern，不動 resolver / battle_controller。

### A1. 四角色 common 專武（STS pattern：Common 級角色遺物＝小幅放大 archetype；支柱 2）

| id | 名稱 | 角色 | 效果 | archetype 對位 | 正史依據 |
|---|---|---|---|---|---|
| `mu_jian` | 木劍 | 李逍遙 | 戰鬥第一回合多抽 1 張牌 | 連擊速攻的開場手數 | PAL1 李逍遙初始武器 |
| `yuenv_jian` | 越女劍 | 趙靈兒 | 戰鬥開始敵人虛弱 1 層 | debuff 開局鋪墊 | PAL1 靈兒可裝備武器 |
| `linjia_jiansui` | 林家劍穗 | 林月如 | 戰鬥開始獲得 2 點荊棘 | 續航反擊 | 自創（林家堡意象，風格一致） |
| `baigu_nang` | 百蠱囊 | 阿奴 | 戰鬥開始敵人 +2 層蠱毒 | 毒流引擎起手 | 自創（苗疆蠱術意象） |

命名備案（品味題，主案先行、使用者可改）：木劍→（鏽鐵劍／柴刀）；越女劍→（靈蛇玉鐲／水靈珠）；林家劍穗→（繡花鏢／劍穗紅纓）；百蠱囊→（蠱盒／五毒袋）。

### A2. common 通用擴充（3 件；充實 common 池）

| id | 名稱 | 效果 | STS 對位 |
|---|---|---|---|
| `kaishan_fu` | 開山符 | 每場戰鬥第 1 次出攻擊牌，額外造成 4 點傷害 | Akabeko |
| `poyao_sha` | 破妖砂 | 戰鬥開始敵人破綻 1 層 | Bag of Marbles |
| `tongqian_jian` | 銅錢劍 | 每場戰鬥前 2 次出技能牌，各獲得 3 護體 | —（民俗法器） |

### A3. 取捨遺物（1 件；支柱 3——「+靈力＋run 層代價」模板首件）

| id | 名稱 | 稀有度 | 效果 | STS 對位 | 正史依據 |
|---|---|---|---|---|---|
| `yu_puti_zhu` | 玉菩提珠 | rare | 每回合開始 +1 靈力；**代價：卡牌獎勵少 2 張可選** | Busted Crown | 鎮獄明王身上可偷的九顆玉菩提珠 |

實作註記：代價用既有 `card_reward_count_bonus` 帶**負值**（-2）實現，零新 kind；卡牌獎勵張數已 clamp ≥1（`main.gd` `_make_card_rewards` count `maxi(1, count)`）。與多寶閣（+1）疊加為 -1。
平衡結論（2026-07-09）：初版「每回合 +1 靈力」強度高（全遊戲僅拜月教旨神器有此效果），AI 平衡 run（seed 20260709）未抽到它無法實測，但分析上 rare 130 金偏低。**已套備案削弱**：改為「**戰鬥前 3 回合**每回合 +1 靈力」（用 `filter: {max_per_battle: 3}`，turn_start 每回合觸發一次＝前 3 回合），掐掉長 boss 戰無限滾能量的雪球、保留 rare 定位與速攻開場助益。

## Batch B — run 層互動批次（3 件；新 permanent kind + main.gd 接線）✅ 本次實作

STS pattern：遺物把地圖節點變成 build 的一部分（Meal Ticket / Maw Bank / Ancient Tea Set）。支柱 1＋3。

| id | 名稱 | 稀有度 | 效果 | 新 kind | 接線點 | 存檔欄位 |
|---|---|---|---|---|---|---|
| `kezhan_yaopai` | 客棧腰牌 | uncommon | 每次進入商店，回復 8 生命 | `shop_enter_heal` | 商店畫面開啟處（`show_shop`） | 無 |
| `qiankun_dai` | 乾坤袋 | uncommon | 每前進一層獲得 8 銅錢；**在商店消費後永久失效** | `floor_gold` | 層數推進處＋商店購買處 | `qiankun_dai_dead: bool` |
| `xingshen_cha` | 醒神茶 | uncommon | 每次休息後，下一場戰鬥開始時 +1 靈力 | `rest_energy_next_battle` | 休息結算處（set flag）＋開戰處（consume） | `next_battle_energy_bonus: int` |

- 正史/風格：客棧腰牌＝李逍遙餘杭客棧出身（正史意象）；乾坤袋＝仙俠通用法寶（自帶剎車，呼應幕 3 通膨不做純加錢）；醒神茶＝茶飯意象（STS Ancient Tea Set 對位）。
- 存檔：純加欄位走 `data.get(key, default)` 回退，不升 SAVE_VERSION；`RunState.to_dict()/from_dict()` 兩邊都要加。
- smoke test：各補 1 條（flag 存讀 round-trip + 效果觸發）。

## Batch C — Boss 代價神器系＋稀有度權重＋條件式遺物池（2026-07-09 實作）

### C1. Boss 池「+1 靈力＋run 層代價」神器（3 件 legendary，STS 能量系 Boss 遺物模板）

新概念「**Boss 池神器**」：`slot="artifact"`、`boss_id=""`（不綁特定 Boss）。Boss 三選一組成改為：
該 Boss 專屬神器（未持有時）→ **未持有的 Boss 池神器隨機補位** → 仍不足才用 generals 補滿 3。
main.gd `_make_boss_relic_choices`、ai_run_engine 對應處、smoke `_test_boss_relic_choices` 三處同步。

| id | 名稱 | 效果 | 代價 kind | 正史依據 / 代價風味 |
|---|---|---|---|---|
| `wangyou_san` | 忘憂散 | 每回合開始 +1 靈力；**休息時無法回血**（仍可打磨） | `rest_heal_disable`（新，休息結算處短路，雙引擎） | 李逍遙被灌忘憂散失憶——忘憂忘痛，不知休養 |
| `zhuqi_jiuhulu` | 朱漆酒葫蘆 | 每回合開始 +1 靈力；**戰鬥中治療效果 -2**（最低 0） | `heal_bonus` 負值（既有 kind；resolver 需 clamp 治療 ≥0） | 酒劍仙的朱漆酒葫蘆——以酒代藥 |
| `shengling_zhu` | 聖靈珠 | 每回合開始 +1 靈力；**商店每件商品 +30 銅錢** | `shop_discount` 負值（既有 kind；折後最低 10 的 clamp 不影響加價） | 靈珠系統（聖靈珠）——寶光引貪，商人抬價 |

- 三件皆「每回合 +1 靈力」不限回合（legendary 檔，與拜月教旨一致；rare 檔的玉菩提珠才限 3 回合）。
- 代價全落 run 層、可用路線/習慣繞開（少休息 / 不靠戰鬥治療 / 少逛商店），對齊 STS 取捨深度。
- 與通寶錢（shop_discount +8）自然疊加抵銷，dict 疊加語意不變。

#### C1 追加（2026-07-19）：孟婆湯——Boss 池的一次性重構賭博（STS Pandora's Box 模板）

第 4 件 Boss 池神器 `meng_po_tang`（legendary、`boss_id=""`），模板與能量系三件套不同：
**取得當下**全隊牌組中所有基礎牌（`rarity=="basic"`，詛咒牌排除）各自轉化為該角色獎勵池的隨機招式，張數不變。
正史依據：鎖妖塔道具孟婆湯——一飲忘前塵，忘卻基礎劍招、隨機悟出新招。

- 實作走既有 `acquire` trigger（`RunState._apply_acquire_triggers` 新 kind `transform_basic_cards`），
  讀檔還原直接 append 不經 `add_relic`，不會重複觸發；同 id 重複取得被「不重複拿」短路，亦不會二次轉化。
- 組隊時全隊各自轉化（各從自己的 reward_pool 抽），維持每副 deck 的角色合法性。
- 風險輪廓對齊 STS：越早拿賭越大（基礎牌越多）、後期拿影響遞減——與能量系「固定收益＋固定代價」形成 Boss 三選一的型態差異。

### C2. 掉落/商店稀有度權重（對齊 STS 50/33/17）

現況：`_try_random_relic_drop` / `_pick_shop_relic_ids`（main.gd 與 ai_run_engine 鏡像）從 generals 均勻抽，
稀有度只影響價格。改為權重抽選：**common 45 / uncommon 30 / rare 20 / legendary 5**
（legendary generals 目前為 0 件，權重先掛著；Boss 池神器不入 generals 不受影響）。
實作：抽稀有度層 → 該層無未持有遺物則 fallback 下一層（避免池空抽不出）。
基線：2026-07-09 AI 平衡 run（seed 20260709，4 幕全通無險）為前測基線；上線後再跑一趟同 seed 對照。

### C3. 條件式遺物池（Bottled 系列 pattern，先套用於 3 件既有流派遺物）

`RelicData` 加 `pool_requires: Dictionary`（空 = 無條件；序列化兩邊都加，舊檔回退空 dict）。
掉落/商店抽選時過濾：deck 中符合條件的卡數 ≥ 門檻才會出現（已持有者不受影響；事件/Boss 池不過濾）。

| relic | 條件 | 理由 |
|---|---|---|
| `shehun_guling` 攝魂蠱鈴（毒半轉傷） | 牌組帶毒效果的卡 ≥ 4 | 無毒源時是死遺物 |
| `xiaoyao_ling` 逍遙令（0 費打 4） | 牌組 0 費卡 ≥ 3 | 同上 |
| `yehuo_lu` 業火爐（消耗打 3） | 牌組帶消耗的卡 ≥ 2 | 同上 |

條件判定用 deck 掃描（cost==0 / effects 含 poison / 卡帶 exhaust 旗標），格式
`{"deck_min": {"match": "cost_zero"|"poison"|"exhaust", "count": N}}`，match 邏輯集中一個 helper 供雙引擎共用。

## 美術

新遺物圖示走 `assets/art/relics/<id>.png`（去背水墨，載不到自動 fallback 程序化圖示，**不阻擋上線**）。11 件需求已登記於 `ART_TODO.md`（交給美術管線 session）。

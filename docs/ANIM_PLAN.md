# 招式動畫盤點與計畫（2026-06）

> **美術鐵則**：動畫**不自行用 SVG / ColorRect / 程式幾何繪製美術圖**（醜）。
> 特效圖一律用 `assets/art/effects/` 既有 PNG，缺的圖寫入 `ART_TODO.md` 交給有
> prompt 繪圖能力的 agent 生成。程式只負責**動畫架構**（tween / 位移 / 縮放 / 淡入淡出 /
> flash 既有節點），圖到位後自動升級——每支特效都要寫成「無圖時退化為純動作回饋」。

## 現況（2026-06-11 盤點）

- 戰鬥特效 27 支 `_animate_*_effect`，由 `play_card` 的 `match card.id` 分派。
- **60 / 181 張卡**有專屬特效；沒進 match 的卡只有「卡片飛出 + 換姿勢 + 敵人 shake + 傷害數字」。

| 角色 | 專屬特效 | 總卡數 | 覆蓋率 |
|---|---|---|---|
| 趙靈兒 | 24 | 45 | 53%（雷8/冰3/火2/土2/治4/夢蛇2/還魂/旋風2）|
| 阿奴 | 16 | 44 | 36% |
| 李逍遙 | 10 | 43 | 23% |
| 林月如 | 10 | 38 | 26% |
| 共同牌 | 0 | 14 | 0% |

### 既有特效圖庫（assets/art/effects/，可複用）
`ink_slash` `witch_blade_slash` `blue_flying_sword` `gold_giant_sword` `ink_dragon`
`poison_needle` `poison_explosion` `toxic_bee` `fireball` `ice_spike` `lightning_strike`
`mountain_stone` `serpent_shadow` `drunken_god` `stealing_hand`

## P1. 通用「分類 fallback」特效（本次實作）

`match card.id` 加 `_:` 預設分支 → `_play_generic_card_fx(card)`，依 effect kind 分類：

| 分類 | 觸發條件（優先序由上而下） | 動畫 | 用圖 | 圖狀態 |
|---|---|---|---|---|
| 能力啟動 | `card_type == "power"` | 法陣於腳下亮起放大淡出 | `fx_power_circle.png` | 🔴 待補 → 暫退化：金色 flash + 微上浮 |
| 劍光斬 | 含 `damage` / `damage_all` | 墨痕斜劈目標（AoE 逐敵 stagger）| `ink_slash.png` | 🟢 現有 |
| 毒擊 | 含 `poison` / `poison_all` | 毒針飛向目標（AoE 逐敵）| `poison_needle.png` | 🟢 現有 |
| 護體 | 含 `block` | 護盾浮現於玩家前方淡出 | `fx_shield.png` | 🔴 待補 → 暫退化：藍色 flash + scale pulse |
| 治療 | 含 `heal` / `heal_party` | 靈光自腳下上飄 | `fx_heal_glow.png` | 🔴 待補 → 暫退化：綠金 flash |
| 抽牌/靈力 | 僅 `draw` / `energy` | 抽牌堆按鈕 flash / 能量珠 flash | 無需圖（既有 UI 節點）| 🟢 |

- 攻擊+毒複合卡：劍光斬 modulate 帶毒綠 tint（不疊兩支特效）。
- 單體目標 = active 敵 wrap（沿用 `_animate_du_zhen_effect` 的 target 解析 pattern）。
- 待補圖登錄於 `ART_TODO.md` 第十四節；PNG 放進 `assets/art/effects/` 即自動生效。

## P2. 高光卡專屬特效（🟢 2026-06-11 已實作；待補圖到位自動升級）

| 卡 | 實作 | 用圖 | 狀態 |
|---|---|---|---|
| 焚盡訣 | `_animate_fen_jin_effect`：火球自手牌區弧線飛向每隻活敵、命中爆燃 | `fireball.png` | 🟢 |
| 銅錢鏢/亂雲連斬/鴛鴦雙劍/旋劍花舞/青煙竹影 | `_animate_multi_slash_effect`：N 連斬（吃 hits、左右鏡像交替；青煙帶竹綠 tint）| `witch_blade_slash.png` | 🟢 |
| 破軍劍/索命一劍/索魂十三劍/趁隙破勢 | `_animate_heavy_sword_effect`：重劍蓄力急墜突刺（索魂/趁隙暗紅 tint）| `gold_giant_sword.png` | 🟢 |
| 萬靈噬 | `_animate_wan_ling_shi_effect`：五色 tinted ink_slash 環攻每敵；`fx_five_spirits.png` 補圖後自動改用 | `ink_slash.png`（暫）/ `fx_five_spirits.png` 🔴 | 🟢（退化版）|
| 冥河引渡/鬼火燎原 | `_animate_ghost_flame_effect`：幽藍鬼火由左至右逐敵爆燃；`fx_ghost_flame.png` 補圖後自動改用 | `poison_explosion.png` 幽藍 tint（暫）/ `fx_ghost_flame.png` 🔴 | 🟢（退化版）|
| 蠱血噬心/毒入膏肓/萬蠱噬天 | `_animate_poison_nova_effect`：毒液聚小→爆大 | `poison_explosion.png` | 🟢 |
| 醉龍翻江 | 共乘 `_animate_jiu_shen_effect`（酒神系）| `drunken_god.png` | 🟢 |
| 水靈封印 | 共乘 `_animate_ice_effect`（水系）| `ice_spike.png` | 🟢 |

> render_effects.gd 的 CARD_ANIM 已同步；`_card_anim_duration` 已登錄全部 >0.5s 新特效。

## P3. 既有特效打磨
- 🟢 `_card_anim_duration` 補全（新特效 7 組已登錄；修「打死最後一敵切尾巴」）。
- 🟢 `render_effects.gd` 的 `CARD_ANIM` 表同步（P2 全部登錄）。
- ⬜ 單體特效逐支確認多敵時打「實際目標 wrap」而非寫死 active（新特效已用 `_generic_fx_targets`；舊特效待巡）。
- ⬜ 雷系 8 張差異化微調（連珠/狂雷多段感）。
- ⬜ 實機抽查截圖（`render_effects.gd` 改 SHOTS 跑，非本機）。

## 不做
- 全 181 張逐張專屬（投報率低，P1+P2 已達 90% 體感）。
- 程式幾何自繪美術（見頂部鐵則）。

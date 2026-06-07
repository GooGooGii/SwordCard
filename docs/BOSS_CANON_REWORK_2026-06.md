# Boss Canon Rework (2026-06-07)

本次調整將部分偏原創、或與 PAL1 正史不完全相符的 boss 對位，校正為更貼近原作的版本。

原則：
- 優先修正 **顯示名稱、章節對位、招式文本**，讓遊戲內敘事先回到 PAL1 語境。
- 先保留既有 `enemy.id`，避免存檔、Ascension boss 判定、遺物綁定與測試全面改名。
- 圖資分批補正；本輪先補最影響辨識的 boss 肖像與部分 phase 2 變身圖。

## 對位調整

| 既有 ID | 舊顯示名 | 新顯示名 / PAL1 對位 |
|---|---|---|
| `red_eye_demon` | 赤眼山魈 | 蛇妖男 |
| `zombie_general` | 殭屍大帥 | 殭屍王 |
| `tomb_general` | 塚中亡將 | 赤鬼王 |
| `witch_queen` | 山靈巫后 | 火麒麟 |
| `centipede_lord` | 蜈蚣大王 | 石長老 |

## Phase 2 視覺調整

| Boss ID | Phase 2 顯示名 | 狀態 |
|---|---|---|
| `red_eye_demon` | 狐妖女 | 已新增 `red_eye_demon_phase2.png` 並接入 `phase_2_portrait_path` |
| `witch_queen` | 火眼麒麟 | 已新增 `witch_queen_phase2.png` 並接入 `phase_2_portrait_path` |
| `baiyue_lord` | 水魔獸 | 既有 `baiyue_lord_phase2.png` 已接入 |
| `tomb_general` | 赤鬼王 phase 2 | 後續可補專屬二階圖 |
| `centipede_lord` | 赤血毒焰 | 後續可補專屬二階圖 |

## 本輪新增 / 替換圖資

- `assets/art/enemies/red_eye_demon.png`：蛇妖男
- `assets/art/enemies/red_eye_demon_phase2.png`：狐妖女
- `assets/art/enemies/tomb_general.png`：赤鬼王
- `assets/art/enemies/witch_queen.png`：火麒麟
- `assets/art/enemies/witch_queen_phase2.png`：火眼麒麟
- `assets/art/enemies/centipede_lord.png`：石長老

## 相關程式檔

- `scripts/game_data.gd`
  - 更新 act boss 對位說明
  - 更新 boss 顯示名稱與招式文案
  - 補上 `red_eye_demon` / `witch_queen` 的 `phase_2_portrait_path`
- `scripts/relic_catalog.gd`
  - 同步校正相關 boss 專屬遺物名稱描述
- `docs/PAL1_CANON.md`
  - 八幕 boss 對照改為 PAL1 正史版本

## 後續

- 補 `石長老` phase 2 專屬圖
- 補 `赤鬼王` phase 2 專屬圖
- 若之後要完全正名，可再評估把 `enemy.id` 一併改為 PAL1 名稱；屆時需同步處理存檔遷移與 relic / smoke test 綁定

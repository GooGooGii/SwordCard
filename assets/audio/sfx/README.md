# SFX 檔名對照表

`AudioManager.play_sfx("card_play")` 會找 `assets/audio/sfx/card_play.wav`。**缺檔自動 skip**（不會 crash），所以可以一個一個換成更好的音色。

跑 `python tools/compose_sfx.py` 用 Python stdlib 合成全部占位音效（原創、無版權問題），共 ~170 KB。品質是復古 chiptune feel；想換成真實音色，丟同名 `.wav` 進來覆蓋即可。

播放細節：6 個 `AudioStreamPlayer` 的 round-robin 池（可疊放），同一 id 在 35ms 內不重複觸發（避免連擊分次扣血時轟鳴）。

## 已串接的 sfx_id（main.gd 觸發點）

| sfx_id | 觸發時機 |
|---|---|
| `card_play` | 打出任一張卡（`play_card`） |
| `attack_hit` | 敵人被扣血（含連擊每段、AOE）（`_show_enemy_slot_feedback`） |
| `heal` | 玩家回血（`_show_state_feedback`） |
| `player_hurt` | 玩家被扣血 |
| `block` | 玩家獲得護體 |
| `end_turn` | 結束回合（`end_player_turn`） |
| `boss_phase` | Boss 二階段變身（`_on_phase_transitioned`） |
| `summon` | 敵方召喚（enemy row 重建，`_rebuild_enemy_row_in_place`） |
| `potion` | 使用藥品（戰鬥內外） |
| `victory` | 通關結算（`show_result(true)`） |
| `defeat` | 戰敗結算（`show_result(false)`） |

## 尚未串接（已生成，備用）

| sfx_id | 用途建議 |
|---|---|
| `button` | UI 按鈕點擊（要全域套用需在 UIFactory 按鈕 helper 加 hook） |
| `card_select` | 桌面點選卡片抬起（`set_selected_button`） |

## 命名規則 / 擴充

放進來的檔案必須是 `<sfx_id>.wav`。要加新觸發點：在 main.gd 對應位置加一行 `_sfx("xxx")`，再把同名 wav 丟進來。

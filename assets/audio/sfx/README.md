# SFX 檔名對照表

`AudioManager.play_sfx("hit")` 會找 `assets/audio/sfx/hit.ogg` 或 `.wav`（兩種都接受，`.ogg` 優先）。**缺檔自動 skip**（不會 crash），所以可以一個一個慢慢換。

SFX 走 `SFX` audio bus（音量由 `SettingsManager.sfx_volume` 控制）。
AudioManager 有 8 個 voice 輪流播，連打 / 多敵受擊不會互相打斷。

## 目前的占位音效

跑 `python tools/compose_sfx.py` 會用 Python stdlib 合成 11 個 chiptune 風 WAV 占位音效（原創、無版權問題），共 ~250 KB。
品質是 8-bit 復古 feel —— 能聽，但若想換成真實音色，丟同名 `.ogg` 進來就會自動取代（`.ogg` 優先）。

## 已串接的 sfx_id（main.gd 觸發點）

| sfx_id | 觸發時機 | 掛載點 |
|---|---|---|
| `card_attack` | 打出攻擊牌 | `play_card`（`card_type == "attack"`）|
| `card_skill` | 打出技能牌 | `play_card`（其他 card_type）|
| `card_power` | 打出能力牌 | `play_card`（`card_type == "power"`）|
| `card_draw` | 玩家回合開始抽牌 | `_start_player_turn` |
| `hit` | 造成傷害（玩家或敵人受擊）| `_spawn_damage_popup`（`kind == "damage"`）|
| `block` | 獲得護體 | `_spawn_damage_popup`（`kind == "block"`）|
| `heal` | 回復生命 | `_spawn_damage_popup`（`kind == "heal"`）|
| `debuff` | 施加蠱毒 / 虛弱 / 破綻 | `_spawn_damage_popup`（poison/weak/vulnerable）|
| `button` | UI 按鈕點擊 | `_button()` wrapper |
| `victory` | 戰役勝利結算 | `show_result(true)` |
| `defeat` | 戰敗結算 | `show_result(false)` |

部分掛載點會傳 `pitch_min/max`，每次播放隨機微調音高，避免連打聽起來機械。

## 命名規則

放進來的檔案必須是 `<sfx_id>.ogg`，例如：

```
assets/audio/sfx/card_attack.ogg
assets/audio/sfx/hit.ogg
...
```

WAV / MP3 轉 OGG：`ffmpeg -i in.wav -c:a libvorbis -q:a 5 out.ogg`

## 之後擴充

要加新觸發點：在 main.gd 對應位置加一行 `_play_sfx("xxx")`，再把同名音檔丟進來。
缺檔時靜默 skip，所以可以先接 code、之後再補音檔。

## 著作權提醒

占位音效為原創合成（CC0 等級，可公開散布）。若改用外部素材，公開前請確認授權。

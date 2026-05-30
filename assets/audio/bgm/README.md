# BGM 檔名對照表

`AudioManager.play_bgm("title")` 會找 `assets/audio/bgm/title.ogg` 或 `.wav`（兩種都接受，`.ogg` 優先）。**缺檔自動 skip**（不會 crash），所以可以一首一首慢慢換。

AudioManager 會在播放時強制 `loop = true`（OGG）或 `LOOP_FORWARD`（WAV），不用手動匯入設定。

## 目前的占位曲

跑 `python tools/compose_bgm.py` 會用 Python stdlib 合成 14 個 chiptune 風 WAV 占位曲（原創、無版權問題），共 ~7 MB。
品質是 8-bit 復古 feel —— 能聽，但若想換成厚實樂器音色，丟同名 `.ogg` 進來就會自動取代（`.ogg` 優先）。

PAL1 / 真實樂器音源的取得方式見 CLAUDE.md 上方的討論（買 Steam 正版抽檔最乾淨）。

## 必要曲目（main.gd 已串接的 track_id）

| track_id | 觸發時機 | PAL1 推薦曲（任選一） | 備案 |
|---|---|---|---|
| `title` | 主選單、character_select | `M027 樂逍遙` | `M064 雲穀鶴峰` |
| `bestiary` | 敵將圖鑑 | `M056 看盡前塵` | `M018 魂縈夢牽` |
| `map_act1` | 第一幕地圖（餘杭/蘇州） | `M005 余杭春日` | `M038 富甲一方` |
| `map_act2` | 第二幕地圖（神木林/苗疆） | `M031 神木林` | `M044 心忐忑` |
| `map_act3` | 第三幕地圖（鎖妖塔/拜月教壇） | `M015 鬼陰山` | `M070 鬼影幢幢` |
| `map_act4` | 第四幕地圖（若有） | `M057 靈山` | `M065 步步為營` |
| `map_act5` | 第五幕地圖（若有） | `M059 淩雲壯志` | `M064_1 九霄雲外` |
| `battle_normal` | 一般戰鬥（非 boss） | `F005_1 勢如破竹` | `F007_2 戰意昂` |
| `battle_boss` | Boss 戰（`Ascension.is_boss_id` 為 true） | `F004_1 逆天而行` | `F012 禦劍伏魔`（拜月終戰） |
| `shop` | 商店節點 | `M038 富甲一方` | `M041 大開眼界` |
| `event` | 奇遇節點 | `M037 風光`（正面） | `M008 驚`（負面） |
| `rest` | 休息節點 | `M061 美景` | `M009_1 小橋流水` |
| `victory` | 戰役勝利結算 | `S07 雲穀鶴峰` | `M050 終曲` |
| `defeat` | 戰敗結算 | `M019 蒙難` | `M045 頹城` |

## 命名規則

放進來的檔案必須是 `<track_id>.ogg`，例如：

```
assets/audio/bgm/title.ogg
assets/audio/bgm/battle_normal.ogg
assets/audio/bgm/battle_boss.ogg
...
```

PAL1 原檔多為 MIDI，先用任何 DAW / `fluidsynth` + 音色 SoundFont 渲染成 OGG。已是 MP3/WAV 的話用 `ffmpeg -i in.mp3 -c:a libvorbis -q:a 5 out.ogg`。

## 之後擴充

要加新觸發點：在 main.gd 對應 `show_*` / `start_*` 開頭加一行 `AudioManager.play_bgm("xxx")`，再把同名 ogg 丟進來。重複呼叫同 track_id 不會重播（AudioManager 內部 dedupe）。

## 著作權提醒

PAL1 OST 著作權屬大宇資訊。**僅限私人粉絲向原型**內使用；任何公開散布（itch.io / GitHub release / 影片）前必須移除或替換成自製 / CC0 素材。

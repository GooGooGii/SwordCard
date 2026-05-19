# SwordCard

Godot 4 仙劍1 同人卡牌戰鬥原型。這個專案是私人學習/展示用途，不處理公開發行、商用上架或素材授權。

## 已實作

- 主選單、角色選擇、戰鬥、勝敗結算。
- 四名角色：李逍遙、趙靈兒、林月如、阿奴。
- Slay the Spire 式單場戰鬥：抽牌、靈力、出牌、棄牌、洗牌、敵人意圖。
- 狀態與效果：傷害、護體、治療、蠱毒、虛弱、破綻、抽牌、回靈、反噬、戰鬥增傷。
- 仙劍1 風格招式卡牌資料。

## 執行

1. 用 Godot 4 開啟此資料夾。
2. 執行主場景 `res://scenes/main.tscn`。
3. 選擇角色後即可進入單場戰鬥。

## 匯出

- `export_presets.cfg` 已包含 Windows Desktop 與 Android 草稿。
- Android 匯出仍需在 Godot Editor 內設定 Android SDK、debug keystore 與 export templates。
- Windows 匯出需安裝 Godot export templates。

## 下一步

- 加入 Android / Windows export presets 與實機匯出測試。
- 補正式卡面、角色立繪與戰鬥特效。
- 擴充到爬塔地圖、事件、商店、遺物與存檔。

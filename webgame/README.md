# 劍卡奇緣（SwordCard Web）— 餘杭篇

SwordCard 的純網頁重製原型：零依賴 HTML/CSS/JS，雙擊 `index.html` 或任何靜態伺服器即玩。
美術直接重用本 repo 的 `assets/art/`（建構時複製到 `webgame/assets/`），
數值與卡片效果移植自 `scripts/game_data.gd`。

## 玩法範圍（v1）

- **單幕完整 run**：餘杭山間 9 層節點地圖（戰鬥/精英/奇遇/休息/商店/寶箱）→ Boss 蛇妖男（半血變身狐妖女 phase 2）
- **4 角色**：李逍遙（首攻減費）/ 趙靈兒（開戰力量+3）/ 林月如（護體反擊）/ 阿奴（開場下蠱 5 層），各自起手 12 張 + 專屬獎勵池（20–25 張）
- **戰鬥機制**：靈力 3 / 護體 / 蠱毒 / 虛弱 / 破綻 / 力量 / 荊棘 / 連擊 / AOE / 毒引爆 / 蓄劍翻倍 / 各種 per-turn 引擎 power、敵人 intent 預測傷害、多敵點選目標
- **Run 機制**：卡獎勵三選一、休息（回血/升級卡）、商店（卡/藥/遺物/除卡）、8 遺物、6 藥品、4 奇遇、localStorage 存檔續玩

## 跑法

```bash
python -m http.server 8765 --directory webgame   # 然後開 http://localhost:8765
node webgame/test_smoke.js                        # 邏輯煙霧測試（資料完整性+模擬戰鬥+地圖+phase2+升級）
```

## 結構

| 檔案 | 內容 |
|---|---|
| `data.js` | 卡片（~120）/ 角色 / 敵人 / 遭遇組 / 遺物 / 藥品 / 奇遇；卡片描述由 `FX_DESC` 自動生成（顯示與機制同源） |
| `engine.js` | 戰鬥引擎（出牌結算/敵人回合/狀態衰減/phase 2/被動）+ run 狀態 + 地圖生成 + 存檔 |
| `ui.js` | 全部畫面（選單/選角/地圖/戰鬥/獎勵/奇遇/休息/商店/結局），純 DOM 建構 |
| `test_smoke.js` | Node 煙霧測試 |

## 與 Godot 本體的對應

效果 kind 命名與 `effect_resolver.gd` 對齊（`damage` / `damage_all` / `poison_burst` /
`next_attack_mult` / `poison_engine`…），敵人資料含 intent 輪替、`enrage_after` 被動、
boss `phase_2_actions`。未移植：組隊主備制、召喚、八幕、Ascension、暈眩以外的控制系（silence/berserk）。

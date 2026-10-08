# 人臉美術重做清單（依影片樣本，由 Codex 出圖）

> 自動產生：`python tools/art/redo_status.py`（依檔案是否存在打勾）。不要手改勾選。
> 背景：2026-10-08 使用者指出劇情頭像是 Pixar 卡通臉、不像影片樣本；本機模型做不到樣本的寫實 CG，改由 Codex 帶參考圖出圖。
> 額度：Codex Plus，實測約每張 0.5% 的 5 小時／每週額度。每週額度重置時接著做。
> 不用重做：劇情背景、地圖、戰場、怪物類敵人、無人物卡圖（本機已出、沒有人臉問題）。巫后依使用者指示暫不做。

**總進度：44/95**

## 第一批：主角四人（每人 11 張）

輸出：`source_art/cine/codex/<id>/`；指令：`python tools/art/codex_batch1.py`（只補缺的）→ `python tools/art/publish_codex.py <id>`

### Li Xiaoyao（`li_xiaoyao`）：11/11，已發布到遊戲
- [x] portrait.png
- [x] portrait_smile.png
- [x] portrait_angry.png
- [x] portrait_surprise.png
- [x] portrait_sad.png
- [x] portrait_resolve.png
- [x] standee.png
- [x] pose_attack.png
- [x] pose_cast.png
- [x] pose_guard.png
- [x] pose_hit.png

### Zhao Ling'er（`zhao_linger`）：11/11，已發布到遊戲
- [x] portrait.png
- [x] portrait_smile.png
- [x] portrait_angry.png
- [x] portrait_surprise.png
- [x] portrait_sad.png
- [x] portrait_resolve.png
- [x] standee.png
- [x] pose_attack.png
- [x] pose_cast.png
- [x] pose_guard.png
- [x] pose_hit.png

### Lin Yueru（`lin_yueru`）：11/11，已發布到遊戲
- [x] portrait.png
- [x] portrait_smile.png
- [x] portrait_angry.png
- [x] portrait_surprise.png
- [x] portrait_sad.png
- [x] portrait_resolve.png
- [x] standee.png
- [x] pose_attack.png
- [x] pose_cast.png
- [x] pose_guard.png
- [x] pose_hit.png

### A'nu（`anu`）：11/11
- [x] portrait.png
- [x] portrait_smile.png
- [x] portrait_angry.png
- [x] portrait_surprise.png
- [x] portrait_sad.png
- [x] portrait_resolve.png
- [x] standee.png
- [x] pose_attack.png
- [x] pose_cast.png
- [x] pose_guard.png
- [x] pose_hit.png

## 第二批：配角劇情頭像（每人 1 張）

輸出：`source_art/cine/codex/<id>/portrait.png`（腳本待寫：照 codex_batch1 的做法）

- [ ] `aunt` Aunt Li (Li Dayang), Li Xiaoyao's aunt a…
- [ ] `drunk` The Drunken Sword Immortal, a scruffy un…
- [ ] `granny` Granny (Lao Lao), Zhao Ling'er's grandmo…
- [ ] `miao_leader` The Black Miao raider leader, a fierce s…
- [ ] `fat_miao` A fat Black Miao bully, a heavy-set man …
- [ ] `tang_yu` Tang Yu, earnest honest 18-year-old Shus…
- [ ] `wuwang` The King of Nanzhao, a dignified kingly …
- [ ] `lin_tiannan` Lin Tiannan, master of the Lin family ma…
- [ ] `liu_jinyuan` Liu Jinyuan, the newly crowned imperial …
- [ ] `caiyi` Caiyi, a butterfly spirit who became a h…
- [ ] `shi_zhanglao` Elder Shi, a sinister old Black Miao sha…
- [ ] `sword_saint` The Sword Saint of Shushan, an ancient s…
- [ ] `shenggu` Shenggu (the Holy Aunt), a mysterious Mi…
- [ ] `gai_luojiao` Gai Luojiao, a seductive dangerous Black…
- [ ] `baiyue` The Moon Worship Cult Leader, the main v…
- [ ] `ji_sanniang` Ji Sanniang, a bold charming female thie…
- [ ] `zhixiu` Master Zhixiu, an old Buddhist abbot abo…
- [ ] `villager` An ordinary Yuhang villager, a weathered…

## 卡圖：不由 Codex 出圖

主角卡由 CARD-001（另一個 Claude Code 工作階段）用主角姿勢去背圖合成，第一批發布後重跑 `python tools/art/cards_compose.py compose` 就會換成寫實臉。

## 第三批：人形敵人（33 張）

輸出：`source_art/cine/codex/enemies/<id>.png`（發布到 public/assets/enemies/<id>.webp）

- [ ] `axe_warrior`
- [ ] `baiyue`
- [ ] `black_thief`
- [ ] `black_wizard`
- [ ] `cleaver_granny`
- [ ] `drunk_arhat`
- [ ] `du_niangzi`
- [ ] `fat_miao`
- [ ] `gai_luojiao`
- [ ] `grey_lama`
- [ ] `hammer_warrior`
- [ ] `ji_sanniang`
- [ ] `jiang_qing`
- [ ] `jiangshi_king`
- [ ] `kick_thug`
- [ ] `knife_thug`
- [ ] `lin_tiannan`
- [ ] `miao_fist`
- [ ] `miao_spear`
- [ ] `red_ghost_king`
- [ ] `red_lama`
- [ ] `royal_guard`
- [ ] `shi_elder`
- [ ] `snake_linger`
- [ ] `spy_miao`
- [ ] `staff_monk`
- [ ] `sword_guard`
- [ ] `toad_mother`
- [ ] `yueru_sword`
- [ ] `yueru_whip`
- [ ] `zombie_soldier`
- [ ] `caiyi_moth`
- [ ] `fox_spirit`


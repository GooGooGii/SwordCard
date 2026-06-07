# SwordCard Art Guide

> ⚠️ **工具分工（重要）**：Claude Code **無法自行繪製美術圖**（PNG 插畫／肖像／背景），只能負責程式碼、資料、`.import` 設定與借圖（`art_id`）安排。
> **實際繪圖只有 codex 與 gemini 能做**。需要新美術時，請交由 codex／gemini 產圖，Claude Code 再負責接入（路徑、import、smoke 驗證）。

## Current Art Direction

- Style: 2D painted xianxia fantasy, ink-wash atmosphere with readable game UI contrast.
- Palette: ink blue, charcoal, muted teal, jade green, antique gold, restrained red/purple accents.
- Use: private fan prototype, not public or commercial release.
- **Card & Enemy Art Guidelines**:
  - 卡圖盡量不要出現人物與文字（專注於仙術效果、符咒、武器或道具意境）。
  - 蟲形敵人（如蠱蟲、蜈蚣等）不要太過寫實，應以水墨寫意風格進行藝術化簡化，避免造成視覺上的噁心感。
- **戰鬥角色肖像設計 (Battle Character Design)**:
  - **風格簡化 (Simplified Style)**: 戰鬥中角色肖像改為 **正常比例、手繪插畫國風水墨風格**（比例同 Slay the Spire 角色，特徵鮮明、線條簡潔、色彩飽和度適度降低），而非 Q 版。與選角時的寫實水墨全身肖像區隔。
  - **左右對立構圖 (StS Layout)**: 角色居左面向右，敵人在右面向左。
  - **動態姿勢 (Dynamic Poses)**: 每個主角需要 6 種戰鬥動作姿勢，均為**強制去背/透明背景**：
    1. `idle` (待命): 基礎防守或準備架勢。
    2. `attack` (攻擊): 物理攻擊，武器揮斬或前傾出招。
    3. `cast` (施法): 單手施法指引、仙術掐指訣或引導能量。
    4. `block` (擋格): 側身護體，伴隨八卦或盾牌架勢。
    5. `low_hp` (命危): 半蹲、捂傷口喘息。
    6. `downed` (倒地): 閉眼昏迷倒下。

## Background Assets

Current generated backgrounds:

- `main_menu_bg.png`  
  Used by main menu and character select.
- `battle_bg.png`  
  Legacy fallback used by the battle scene.
- `battle_bg_act_1.png`  
  Used by act 1 battles.
- `battle_bg_act_2.png`  
  Used by act 2 battles.
- `battle_bg_act_3.png`  
  Used by act 3 battles.
- `battle_bg_act_4.png`  
  Used by act 4 battles.
- `battle_bg_act_5.png`  
  Used by act 5 battles.
- `event_bg.png`  
  Used by route, rest, event, reward, and result screens.
- `map_bg_ink.png`  
  Used by the route map screen.

Target size:

- 1280 x 720
- Route map: 1280 x 1800
- PNG
- No text, no logos, no watermarks
- Keep central negative space for UI panels

## Planned Event Story Illustrations

Suggested paths:

- `assets/art/events/[event_id].png`
  - Event IDs correspond to the types in `EventData.gd` (e.g., `shrine`, `spring`, `talisman_cache`, `treasure_chest`, `tavern_acquaintance`, `sword_tomb`, `miao_healer`, etc.)

Target:

- 1280 x 720 PNG (to fit the game resolution)
- Style: 2D painted xianxia fantasy, classic PAL1 scene-oriented story illustrations (e.g., encountering a wandering sage, the mystical moonlit pool, an ancient furnace, or the mysterious Baiyue Altar).
- Composition: Restrained detail in the center/sides where event options and dialogue text boxes are overlaid, ensuring text remains highly legible.

## Planned Character Portraits


Suggested paths:

- `assets/art/portraits/li_xiaoyao.png`
- `assets/art/portraits/zhao_linger.png`
- `assets/art/portraits/lin_yueru.png`
- `assets/art/portraits/anu.png`

Target:

- 768 x 1024 portrait PNG
- **強制去背 (Transparent background is REQUIRED)**: 必須是去背透明背景，以便與遊戲戰鬥及主選單背景完美融合。

## Planned Enemy Portraits

Suggested paths:

- `assets/art/enemies/bandit.png`
- `assets/art/enemies/beast.png`
- `assets/art/enemies/gu_cultist.png`
- `assets/art/enemies/moon_worshipper.png`
- `assets/art/enemies/sword_spirit.png`
- `assets/art/enemies/fox_spirit.png`
- `assets/art/enemies/serpent_demon.png`
- `assets/art/enemies/centipede_lord.png`
- `assets/art/enemies/witch_queen.png`

Target:

- 768 x 768 PNG
- **強制去背 (Transparent background is REQUIRED)**: 必須是去背透明背景，便於在戰鬥場景中渲染。
- Clear silhouette
- Readable at small in-game size

## Planned Battle Character Portraits

Suggested paths:

- `assets/art/battle_characters/[character_id]_[pose].png`
  - Poses: `idle`, `attack`, `cast`, `block`, `low_hp`, `downed`
  - Character IDs: `li_xiaoyao`, `zhao_linger`, `lin_yueru`, `anu`

Target:

- 768 x 768 PNG
- **強制去背 (Transparent background is REQUIRED)**: 必須是去背透明背景。
- 角色朝向：面朝右方（StS 戰鬥左側玩家向）。

## Planned Potion Icons

Suggested paths:

- `assets/art/potions/huichun_dan.png` (回春丹)
- `assets/art/potions/lingli_dan.png` (靈力丹)
- `assets/art/potions/huti_fu.png` (護體符)
- `assets/art/potions/jiedu_san.png` (解毒散)
- `assets/art/potions/lingshe_dan.png` (靈蛇膽)
- `assets/art/potions/hugu_jiu.png` (虎骨酒)
- `assets/art/potions/jinchuang_yao.png` (金瘡藥)
- `assets/art/potions/tianling_dan.png` (天靈丹)
- `assets/art/potions/xianren_xue.png` (仙人遺血)
- `assets/art/potions/yuehun_cao.png` (月魂草)
- `assets/art/potions/baihua_xianniang.png` (百花仙釀)

Target:

- 512 x 512 PNG
- **強制去背 (Transparent background is REQUIRED)**: 必須是去背透明背景，便於在戰鬥列及商店中渲染。
- Style: 2D hand-painted Chinese ink-wash style, watercolor texture, clean ink outlines, matching the relic style.

## Planned UI Assets

Suggested paths:

- `assets/ui/card_frame_attack.png`
- `assets/ui/card_frame_skill.png`
- `assets/ui/card_frame_power.png`
- `assets/ui/node_battle.png` ( Crossed Chinese Swords - 水墨雙劍 )
- `assets/ui/node_shop.png` ( Copper Coin - 水墨金銅錢 )
- `assets/ui/node_black_shop.png` ( Dark Copper Coin - 暗黑紫煙銅錢 )
- `assets/ui/node_event.png` ( Mysterious Scroll - 國風水墨古卷 )
- `assets/ui/node_rest.png` ( Campfire - 篝火營地 )
- `assets/ui/node_boss.png` ( Yaoguai Demon Mask - 猙獰山魈魔臉 )

Target:

## 美術狀態 (Art Status)

> **現況**：所有流派卡 / 等級解鎖卡 / 專武遺物，以及連打牌組、毒引擎與 colorless 移植卡牌等全部 27 張原本借圖的卡牌皆已補齊專屬 2D 水墨插圖。現已無借圖（`art_id`）情況。
>
> **最近驗證（2026-05-31）**：補上 12 張李逍遙／趙靈兒／林月如／阿奴的水墨卡圖（含工作區另 4 張林月如卡），
> 已實際在 Godot 內重新匯入並驗證 `valid=true` + 產生非佔位的 `.ctex`，確認真的會顯示在遊戲中。

### 🔴 待重製：卡圖含文字（2026-06 全卡盤點，共 18 張）

卡圖原則「**不要出現文字**」（標題／英文／浮水印／數值框／水墨題跋落款）。
例外：**符咒（符／法陣）上的符文字保留**（如 `lxy_tianshi` 天師符、`zl_shuiyin` 法陣）。
下列卡圖違反原則，需重製去除文字：

**A. 烤進卡圖的卡框／標題／英文／浮水印／數值（最優先 — 會與程式自繪卡框疊起來）**
| ID | 問題 |
|---|---|
| `zl_huihun` | 「迴魂咒 (Huihun Zhen)」+ 英文 + 整張卡框與說明 |
| `zl_leiguang` | 「紫金雷霆術」+「ATK 8 HP 4」數值框 + 卡框 |
| `lyr_tieyi` | 「鐵衣功 / Tieyi Gong」+ 英文敘述 + 底部版權浮水印 |
| `zl_bingxin` | 「清心咒」+「SR」稀有度標 + 卡框 |
| `zl_lingxi` | 「靈犀」+ 卡框 + 說明文字 |
| `zl_shenlei` | 「神雷」+ 裱框標題 |
| `zl_shuiling` | 「水靈盾／持寧」+ 紅色印章 |
| `lyr_xuanjian` | 「旋劍花舞」標題框 + 印章 |
| `zl_jingang` | 幡旗直書標題字（borderline，偏標題） |
| `tong_ji`（詛咒卡） | 裱框水墨 + 紅色落款印 |

**B. 水墨題跋／落款印章（畫上詩文題字、藝術家紅印，非符咒）**
| ID | 問題 |
|---|---|
| `anu_duwu` | 左上題字 |
| `anu_guwang` | 題字 + 紅印 |
| `anu_guxue` | 直書題字數行 |
| `anu_sanmao` | 左上題字 |
| `lyr_poqian` | 左下題字 |
| `lyr_tianv` | 左下題字 |
| `lyr_tongqianbiao` | 右上題字 |
| `lyr_qijuejianqi` | 右上角紅色落款印 |

> 其餘約 90 張（純法術光效／人物／無題字水墨山水如 `lxy_qingfeng`、`lxy_jiulong`、`lxy_ningyuan_ls`、`anu_gushen`）皆乾淨無文字。
> 重製後放回原路徑 `assets/art/cards/<id>.png`（依上方硬性要求：真 PNG + 重新匯入驗證）。

### 🔴 待重製：戰鬥肖像對齊／大小不一（2026-06）

**問題**：戰鬥肖像用 `STRETCH_KEEP_ASPECT` 塞進固定框，但各角色原圖**比例與取景不一致** →
高度漂移（林月如「位置特別高」）、人物大小不一。程式已加「底部對齊地面線」（`UIFactory.ground_portrait`）
把各圖底部對齊，但**大小一致＋乾淨去背**仍需統一原圖才能解決。

**統一規格（重出 `assets/art/battle_characters/<id>_<pose>.png` 時遵守）**：
1. **畫布統一 768×768**（正方，與李逍遙／阿奴一致）。
2. **強制透明去背**（PNG RGBA，不可白底）。
3. **人物高度一致**：頭頂→腳底約佔畫布高 85–90%。
4. **腳底對齊同一基準線**：腳底約在畫布底部 ~92% 處（底對齊後四角色與人型敵人站同一條地面線）。
5. 人型敵人比照同一人物高度；大型／非人型 boss 才可放大。

**待重出清單**：
- **林月如（6 張，最優先）**：`lin_yueru_idle/block/cast/attack/downed/low_hp` —— **白底未去背**且比例各異
  （576×768 / 768×615 / 768×512 / 602×768），需重出成 768×768 透明、與其他角色同取景。
- **趙靈兒 v2（6 張）**：`zhao_linger_*_v2` 為 512×768（比例 0.667），與李逍遙／阿奴的 768×768 不一致 →
  對齊規格（或在程式端統一改用非 v2 的 768×768 版本）。
- 李逍遙 / 阿奴：已是 768×768 透明，符合規格（基準）。

### ⚠️ 新增美術資源的硬性要求（踩過的雷）

產生 / 置換卡圖、圖示時務必確認，否則圖**不會進到遊戲**（匯入失敗、悄悄 fallback 回舊圖）：

1. **副檔名要與真實格式一致**：`.png` 檔案內容必須是真正的 PNG（檔頭 `89 50 4E 47`），
   不可把 JPEG（檔頭 `FF D8`）改個副檔名當 PNG。Godot 依副檔名挑 loader，假 PNG 會匯入失敗 → `valid=false`。
   檢查：`file assets/art/cards/<id>.png` 應回報 `PNG image data`。
2. **每個 `.import` 的 `uid` 必須唯一**：不要連同 `.import` 一起複製貼上（會共用同一個 `uid://…`，
   Godot 偵測 UID 衝突就拒絕匯入整批）。最安全做法：**只放 `.png`，刪掉舊 `.import`**，
   讓 `godot --headless --path . --import` 自動產生全新唯一 UID（程式以路徑 `load("res://…png")` 載圖，不靠 UID）。
3. **匯入後驗證**：跑 `--import`，確認對應 `.godot/imported/<id>.png-*.ctex` 有重新產生（非舊的佔位大小）、
   且 `.import` 內無 `valid=false`、無重複 `uid`。最後 `-s scripts/smoke_test.gd` 應印 `passed`。

### 美術統計

| 類別 | 缺圖數 | 狀態 | 優先級 |
|---|---|---|---|
| 流派 / 新機制卡（CARD_DESIGN ch.3-4） | 0 | 已完成專屬插圖 | 🟢 已完成 |
| 等級解鎖卡（LevelSystem） | 0 | 已完成專屬插圖 | 🟢 已完成 |
| 角色專武遺物 | 0 | 已補齊專屬圖示 | 🟢 已完成 |
| 連打牌組卡（2026-06）+ 毒引擎 | 0 | 已完成專屬插圖 | 🟢 已完成 |
| 共同牌（colorless 移植，2026-06） | 0 | 已完成專屬插圖 | 🟢 已完成 |
| **合計** | **0** | | |

> 連打抽牌遺物（循環珠 / 連環珮 / 疾風鈴）使用程序繪製圖示（`RelicCatalog` 的 `icon_color` + `icon_shape`），無 PNG 需求。

### 🔴 流派／新機制卡（8 張）

所有卡片皆已補齊專屬 2D 水墨國風插畫：
- `anu_cuifeng` (淬鋒蠱刃)
- `anu_wuyuezhan` (巫月斬)
- `anu_xuerenwu` (血刃亂舞)
- `lxy_wanjianguizong` (萬劍歸宗)
- `lyr_fenghuan` (鳳鳴反擊)
- `lyr_yuehua` (月華護體)
- `zl_shuiyin` (水靈封印)
- `zl_ganlin` (甘霖咒)

### 🟡 等級解鎖卡（27 張）

所有解鎖卡牌皆已擁有專屬卡圖，不再依賴其他卡牌插畫：
- **李逍遙 (8 張)**: `lxy_tiangangqi` (天罡戰氣)、`lxy_ningyuan_ls` (凝神歸元)、`lxy_yuanlinggui` (元靈歸心術)、`lxy_zhenyuan` (真元護體)、`lxy_tianjian` (天劍)、`lxy_jinchan_ls` (金蟬脫殼)、`lxy_xiaoyao_shenjian` (逍遙神劍)、`lxy_jianshen` (劍神)。
- **趙靈兒 (8 張)**: `zl_xuanfengzhou` (旋風咒)、`zl_wuleizhou` (五雷咒)、`zl_sanmeizhenhuo` (三昧真火)、`zl_fengxuebing` (風雪冰天)、`zl_diliebeng` (地裂天崩)、`zl_mengshe_ls` (夢蛇)、`zl_taishan` (泰山壓頂)、`zl_kuanglei` (狂雷)。
- **林月如 (5 張)**: `lyr_tongqianbiao` (銅錢鏢)、`lyr_qijuejianqi` (七訣劍氣)、`lyr_yuanlinggui` (元靈歸心術)、`lyr_lielong` (裂龍式)、`lyr_wanlikuang` (萬里狂沙)。
- **阿奴 (6 張)**: `anu_sanshigu` (三屍蠱)、`anu_yanshazhou` (炎殺咒)、`anu_shuhun` (贖魂)、`anu_duohun` (奪魂)、`anu_wanyi_ls` (萬蟻蝕象)、`anu_wangushitian` (萬蠱蝕天)。

### 🟡 遺物（2 件）

兩件流派錨點專屬武器已成功配置專屬圖示，並移除了程序繪製 fallback 顯示：
- `wuyue_shendao` (巫月神刀): 阿奴刀流錨點。
- `fengming_dao` (鳳鳴刀): 林月如刀流錨點。

### 🔴 借圖待補（17 張，連打牌組 + 毒引擎）

下列卡片目前以 `art_id` 暫借同角色既有卡圖，補圖時放 `assets/art/cards/<id>.png` 即可生效
（並把 `game_data.gd` 對應 `make_card` 的最後 `art_id` 參數移除）。
**注意上方「新增美術資源的硬性要求」：必須是真 PNG、`.import` UID 唯一、匯入後驗證。**

- **李逍遙（4，御劍連擊）**
  - `lxy_jianjue` (劍引) ← 借 `lxy_yujian` 御劍術
  - `lxy_huijian` (揮劍引氣) ← 借 `lxy_qingfeng` 清風御劍
  - `lxy_yufengbu` (御風步) ← 借 `lxy_jianqi` 劍氣護身
  - `lxy_lianhuanjian` (連環御劍，減靈耗升級) ← 借 `lxy_jianzhen` 劍陣
- **趙靈兒（4，連咒）**
  - `zl_xiaoleizhou` (小雷咒) ← 借 `zl_leizhou` 雷咒
  - `zl_yinlingfu` (引靈符) ← 借 `zl_fengling` 風靈符
  - `zl_huguangzhou` (護光咒) ← 借 `zl_lingguang` 靈光護體
  - `zl_lianzhuzhou` (連珠雷咒，減靈耗升級) ← 借 `zl_leiguang` 雷光連擊
- **林月如（4，鞭劍連擊）**
  - `lyr_jici` (急刺) ← 借 `lyr_xuanjian` 旋劍花舞
  - `lyr_huaci` (花刺引身) ← 借 `lyr_tianv` 飛花亂舞
  - `lyr_qiebushan` (怯步閃) ← 借 `lyr_fanji` 回身反擊
  - `lyr_shuangjianci` (雙劍連刺，減靈耗升級) ← 借 `lyr_lianhuan` 連環快斬
- **阿奴（5，蠱毒連擊 + 毒引擎）**
  - `anu_sandu` (散蠱) ← 借 `anu_duwu` 毒霧繚繞
  - `anu_yindu` (引蠱) ← 借 `anu_yufeng` 御蜂術
  - `anu_huguzhao` (護蠱罩) ← 借 `anu_guling` 蠱靈護身
  - `anu_lianduzhen` (連環毒針，減靈耗升級) ← 借 `anu_duzhen` 毒針連射
  - `anu_guzhang` (蠱瘴瀰漫，毒引擎) ← 借 `anu_baizu` 百足蠱
- **阿奴（5，鬼／冥 主題·苗巫邪術）**
  - `anu_guiling_zhuansheng` (鬼靈轉生，復活) ← 借 `anu_guijiang` 鬼降
  - `anu_minghe_yindu` (冥河引渡，AOE 傷+毒) ← 借 `anu_wangushitian` 萬蠱噬天
  - `anu_suoming_egui` (索命厲鬼，傷+虛弱) ← 借 `anu_duohun` 奪魂術
  - `anu_youming_shigu` (幽冥蝕骨，毒+破綻) ← 借 `anu_sanshigu` 三屍蠱
  - `anu_guihuo_liaoyuan` (鬼火燎原，AOE 傷×2+毒) ← 借 `anu_yanshazhou` 燃殺咒

### 🔴 借圖待補（10 張，共同牌 colorless 移植）

`owner="無門"`，任何角色都能在 獎勵/商店/事件 取得（STS colorless 移植）。同樣借既有卡圖：
- `cl_xunjiezhan` (迅捷斬，Swift Strike) ← 借 `lxy_yujian`
- `cl_hanfengjue` (寒鋒訣，Flash of Steel) ← 借 `lyr_xuanjian`
- `cl_hushenjue` (護身訣，Good Instincts) ← 借 `lxy_jianqi`
- `cl_qiaojin` (巧勁，Finesse) ← 借 `zl_lingguang`
- `cl_zhimingfu` (致盲符，Blind) ← 借 `anu_mihun`
- `cl_poshi` (破式，Trip) ← 借 `lyr_juesha`
- `cl_jinchuangtie` (金創藥帖，Bandage Up，exhaust) ← 借 `lxy_qiliao`
- `cl_qimendunjia` (奇門遁甲，Dramatic Entrance) ← 借 `lxy_wanjian`
- `cl_yunchou` (運籌帷幄，Master of Strategy，exhaust) ← 借 `zl_lingxi`
- `cl_huacaijianyi` (華彩劍意，Panache，連打 payoff) ← 借 `lxy_jianshen`

## Card Layering Convention

Card UI should follow a fixed rendering stack so art replacements do not require layout rewrites:

1. Card art at the bottom
2. Card frame above the art
3. Decorative overlays above the frame
4. Text as the topmost layer

Decorative overlays include the mana badge, rarity badge, name plaque, and rules-panel ornaments. When replacing the three card frames with ink-wash versions, keep those elements as separate overlays unless they must be baked into the frame for a specific visual effect.


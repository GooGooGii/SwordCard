# SwordCard Art Guide

> ⚠️ **工具分工（重要）**：Claude Code **無法自行繪製美術圖**（PNG 插畫／肖像／背景），只能負責程式碼、資料、`.import` 設定與借圖（`art_id`）安排。
> **實際繪圖只有 codex 與 gemini 能做**。需要新美術時，請交由 codex／gemini 產圖，Claude Code 再負責接入（路徑、import、smoke 驗證）。

## Current Art Direction

- Style: 2D painted xianxia fantasy with readable game UI contrast. ink-wash 質感保留在**筆觸與單體資產**，**不再作為整體暗色濾鏡**。
- **明度基調＝日光**（2026-07-15 製作人裁決，見下方「明度紀律」）。
- Palette（主・日光基調，用於背景/選單/大場景）: warm sunlight cream（暖陽米白）, fresh bamboo green（嫩竹綠）, watertown teal（水鄉青）, sky azure（天青藍）, antique gold（古金）。
- Palette（副・僅限陰暗題材幕與鬼冥系資產）: ink blue, charcoal, muted teal, restrained red/purple accents.
- Use: private fan prototype, not public or commercial release.

### 明度紀律（2026-07-15 製作人裁決；⚠️ 2026-07-17 執行擱置中）

> **⚠️ 執行狀態（2026-07-17）**：依本紀律重繪的第一批（act_1/5/7＋主選單）**成品被製作人否決並已回退舊圖**
> ——敗因是**畫風**（童話/anime 水彩，與 act_2 基準及全遊戲水墨厚塗質感違和），非明度方向本身被推翻。
> 在製作人重新裁決前：**不要按本節批量重出任何背景**；若重啟，先單張對齊「act_2 的 painterly 質感＋日光明度」
> 驗證通過再批量（詳見 `ART_TODO.md` §18 結案紀錄）。本節其餘條文（palette 定義、prompt 負面控制等）保留備用。

**問題**：2026-07 盤點發現全部 8 張幕背景＋主選單皆為低明度 dark-fantasy 概念美術，開場 act_1 讀起來像恐怖遊戲。這與 PAL1 的基調相悖——**PAL1 前中期是白天、暖陽、田園、水鄉；陰暗是後期劇情轉折，是標點，不是基調。**

**裁決**：
1. **日光是預設**：背景/選單/事件/地圖圖預設為明亮日光場景。只有正史上就該暗的場景（鬼森、將軍塚、boss 殿、終局祭壇）允許低明度。
2. 幕背景明:暗目標比例約 **4:4**，且 **act_1（開場）必須是亮的**。
3. 產圖 prompt **必須**含亮側詞（`warm daylight` / `soft morning sunlight` / `bright, fresh, hopeful` 等）與負面控制 `not dark fantasy, not gloomy, not horror atmosphere, not night, not dusk`；陰暗幕豁免。
4. 「顏色克制、低飽和」原則**只適用於去背單體資產**（卡圖/敵人/遺物/藥品）——單體低飽和疊在亮背景上反而耐看，此原則不變；**不得**外推到背景。
5. 原「明暗弧線＝起→高點→步步入暗」的框架**作廢**，改為「明快為底、暗為劇情標點」（對齊 PAL1 情緒結構）。
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

## Prompt Pattern（2026-06 Enemy Batch）

> 2026-06-09 補 `bee_cocoon` / `miao_maiden` / `conch_maiden` / `turtle_demon` 等 10 張敵圖時，
> 效果最穩定的一組 prompt 寫法。之後續畫敵圖、人物型妖怪、水族怪、草木精怪，優先沿用這套。

### 核心寫法

- 先把用途講清楚：
  `transparent-background enemy portrait asset for a Godot card-battle game`
- 直接鎖死輸出型態：
  `768x768 PNG`, `no text`, `no watermark`, `no frame`, `no background scene`
- 直接鎖死遊戲需求：
  `readable at small UI size`, `clean silhouette`, `centered composition with safe margins`
- 明講戰鬥站位：
  `enemy should face left`
- 風格不要只寫「國風水墨」，要補可執行描述：
  `2D painted xianxia fantasy`, `ink-wash atmosphere`, `stylized for game readability`

### 這批圖成功的共通特徵

- **單體明確**：畫面只保留一個主體，不塞背景敘事，讓縮小後第一眼就認得出輪廓。
- **安全留白足夠**：主體不貼邊，武器、尾巴、殼、藤蔓可延伸，但不能撞到四角。
- **材質有層次，但不過度寫實**：例如龜殼、水紋、海螺殼、花瓣、繭絲都能看出材質，
  但仍保持插畫化，而不是照片感或概念設計稿感。
- **顏色克制**：用墨藍、灰綠、青藍、米白、淡紫、枯粉這類低飽和主色，亮點只留在靈氣、眼神、
  毒性、水紋、珠光等局部。
- **妖氣靠輪廓與氣質，不靠噴特效**：怪物的「邪」主要來自姿態、眼神、部件設計，而不是滿畫面光效。
- **PAL1 氣質優先，不走泛二遊仙俠**：不要過度華麗、不要滿身金屬件、不要現代 cosplay、不要韓系立繪味。

### 題材分組寫法

- **人型敵人 / 女妖 / 苗疆角色**
  - 先寫身份與勢力：例如 `Black Miao female fighter`, `aquatic female demon`
  - 再寫服飾語言：銀飾、披肩、鱗甲、海螺殼、苗銀、毒鏢、長鞭
  - 再補一句限制：`not over-sexualized`, `not cosplay`, `not a Western mermaid`
- **草木精怪**
  - 先寫「由什麼凝成」：leaf, vine, wet grass, petals, scented mist
  - 再寫所屬場景氣質：十里坡、仙靈島、山野木靈
  - 限制要避開西式精靈 / 德魯伊 / 花仙子
- **蟲形 / 蠱系 / 繭類**
  - 強調 `stylized`, `elegant`, `not gross`, `not realistic insect photography`
  - 可寫「半透明、可見內部輪廓」，但不要往血腥黏液方向跑
- **水族怪**
  - 用 `cold pearl glow`, `muted cyan`, `deep blue`, `water-worn shell`, `aquatic qi`
  - 避免可愛海洋生物、迪士尼人魚、科幻海怪感

### Prompt 結構建議

建議固定四段，穩定度最高：

1. **Asset instruction**
   說透明背景、用途、尺寸感、可讀性、朝向、不要文字水印背景。
2. **Subject identity**
   說是什麼怪、來自哪種 PAL1 場景氣質、等級或戰鬥定位。
3. **Visual design**
   說身體結構、材質、服飾、武器、顏色、表情、姿態。
4. **Negative control**
   明寫不要什麼：Western fantasy, cute mascot, photography, heavy background, sci-fi, cosplay.

### 可直接複用的英文關鍵詞

- `transparent-background`
- `isolated subject`
- `clean silhouette`
- `readable at small game UI size`
- `centered composition with safe margins`
- `2D painted xianxia fantasy`
- `ink-wash atmosphere`
- `stylized for game readability`
- `PAL1-inspired Chinese fantasy`
- `not realistic photography`
- `not cute mascot`
- `not Western fantasy armor`
- `no text, no watermark, no frame, no background scene`

### 這批圖帶來的風格校準

- `miao_maiden` 是之後 **苗疆人型敵人** 的基準：黑藍布料、銀飾密度高、冷冽俐落。
- `bee_cocoon` 是之後 **小型蟲妖 / 繭類怪** 的基準：可怕但不噁心，簡化寫意。
- `turtle_demon` 是之後 **厚重防守型水族怪** 的基準：大塊量感、低飽和、殼面紋理清楚。
- `flower_spirit` / `conch_maiden` 是 **妖魅型女妖** 的上限參考：
  可以妖異、優雅、帶人形美感，但要避免過度寫真、過度性感或偶像立繪感。

## Background Assets

Current generated backgrounds:

- `main_menu_bg.png` — main menu and character select.
- `battle_bg.png` — legacy fallback (used only if an act bg is missing; `main.gd:_battle_background_path`).
- `battle_bg_act_1.png` … `battle_bg_act_8.png` — act 1–8 battles（遊戲以 `clamp(run_state.act, 1, 8)` 選圖，8 張全在線上）。
- `event_bg.png` — route, rest, event, reward, result screens.
- `map_bg_ink.png` — route map screen.

### 8 幕戰鬥背景：地理／旅程對照＋明度目標（2026-07-15 明度重校；2026-07-17 重繪回退、全表擱置）

> ⚠️ 下表「動作」欄**已擱置**：act 1/5/7＋主選單的日光重繪版已於 2026-07-17 否決回退，現役仍是原低明度版。
> 明度目標欄留作日後重啟時的參考，勿據此逕行重出。

背景**確實承載了「餘杭→蘇州→苗疆」旅程感**（設計支柱 1 的美術兌現）。原「明暗弧線（起→高點→步步入暗）」框架已作廢（見頂部「明度紀律」），改為**明快為底、暗為劇情標點**：

| 幕 | 現況畫面 | PAL1 對應 | 明度目標 | 動作 |
|---|---|---|---|---|
| 1 | 黃昏霧竹林山道 + 小亭 | 餘杭/十里坡郊野 | ☀ **亮**（晨光田園） | 🔴 重出（最優先，開場第一印象） |
| 2 | 江南水鄉庭院・拱橋・蓮花・晨霧 | **蘇州** | ☀ 亮 | ✅ 保留——**全套明度基準** |
| 3 | 夜・枯樹廢廟・藍焰鬼火 | 鬼森/陰宅 | 🌙 暗（正史合理） | 保留，可加月光層次 |
| 4 | 陰天古戰場・將軍塚石像・斷旗裂地 | 將軍塚/殭屍 | 🌙 暗（正史合理） | 保留 |
| 5 | 藍水晶洞窟・刻紋石柱・晶簇 | 隱龍窟/鎖妖塔地宮 | ☀ 亮（晶光通明的靈氣洞窟） | 🟡 重出（暗場景也能亮） |
| 6 | 雙巨龍柱大殿・青焰・地面法陣・王座 | 拜月教壇/塔頂 boss 殿 | 🌙 暗（boss 壓迫感合理） | 保留 |
| 7 | 苗疆瘴氣叢林・圖騰・骷髏旗・竹刺・瀑布 | **苗疆** | ☀ 亮（白日苗疆：陽光瀑布、綠意、彩旗——PAL1 苗疆是鮮豔的） | 🟡 重出 |
| 8 | 夜・廢殿柱列・青魂火・水澤 | 終局祭壇 | 🌙 暗（終局合理） | 保留 |

另：`main_menu_bg.png`（深夜雲海，玩家開遊戲第一眼）建議同構圖重出為**晨曦仙山**；`event_bg` / `map_bg_ink` 一併檢視明度。

### 套用方式（畫背景時務必知道）

`background_rect` 用 `STRETCH_KEEP_ASPECT_COVERED`（`main.gd:581`）：**永不變形，但會裁切溢出**。
螢幕比例 16:9 → 非 16:9 的圖上下（或左右）會被切掉。**構圖務必留安全邊、把主體/敘事放中央**。

Target size:

- **1280 x 720（16:9）**；更高解析度可（如 1672×941）但**比例必須維持 16:9**，否則會被 COVERED 裁掉。
- Route map: 1280 x 1800
- PNG, no text/logos/watermarks
- Keep central negative space for UI panels

### 🟡 背景待辦（美術指導）

1. **`act_5` 比例為 3:2（1536×1024）**——唯一非 16:9，在戰場會被裁掉上下（鐘乳石頂＋前景晶簇）。明度重出時一併改成 16:9（1280×720 或 1672×941）。
2. ~~`act_2` 色調離群（open decision）~~ **已裁決（2026-07-15）**：act_2 不是離群，是**唯一對的**——它成為全套的明度基準，其餘往它對齊（優先序見上表「動作」欄）。舊「兩種讀法」條目作廢。

### 背景 Prompt Pattern（2026-07 明度重校批次）

背景圖（**不去背、畫滿**）與單體資產的 prompt 寫法不同，固定五段：

1. **Asset instruction**：`background asset for a Godot card-battle game, 1280x720 landscape (16:9), PNG, no text, no watermark, no characters`
2. **Scene identity**：PAL1 場景身分＋地理（餘杭竹林山道／蘇州水鄉／苗疆山寨…）
3. **Lighting & mood（關鍵段，明度紀律落地處）**：亮幕必寫 `warm daylight` / `soft morning sunlight` / `bright, fresh, hopeful`；暗幕才准用夜色詞
4. **Style**：`2D painted xianxia fantasy, hand-painted brushwork with light ink-wash texture, high-key lighting, airy and inviting`（暗幕改 `low-key` 但仍需可讀）
5. **Composition + Negative**：`keep center and lower-middle relatively open for game UI and combatants; safe margins (cropped keep-aspect-covered)` ＋ 亮幕必附 `not dark fantasy, not gloomy, not horror, not night, not dusk, no heavy fog, no photorealism`

#### act_1 參考範例（2026-07-15 首驗證張）

> Background asset for a Godot card-battle game, 1280x720 landscape (16:9), PNG, no text, no watermark, no characters.
> Scene: a sunlit bamboo-forest mountain path in the Jiangnan countryside near Yuhang, the opening region of a classic Chinese xianxia journey — a small rustic wooden pavilion beside a stone-paved path, distant green karst hills softened by thin morning haze under a clear blue sky, wildflowers and grass along the roadside, a few birds in the sky.
> Lighting & mood: early morning warm sunlight streaming through tall green bamboo; bright, fresh, hopeful — the beginning of a young hero's adventure.
> Style: 2D painted xianxia fantasy, hand-painted brushwork with light ink-wash texture; colors: warm cream sunlight, fresh bamboo green, sky azure, soft teal shadows. High-key lighting, airy and inviting.
> Composition: keep the center and lower-middle area relatively open and uncluttered (game UI and combatants overlay there); main scenery on the sides and upper third; safe margins, nothing important near the edges (image is cropped keep-aspect-covered).
> Negative: not dark fantasy, not gloomy, not horror, not night, not dusk, no heavy fog covering the scene, no photorealism, no anime characters, no text.

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
> **最近盤點（2026-06-30，美術指導對賬）**：直接掃磁碟＋讀圖驗證，確認**美術資產覆蓋率已近 100%**：
> `game_data.gd` 的 `art_id` 借圖實際使用 = **0**（下方所有「借圖待補」清單皆已補實，故移除）；
> 5 隻原列「placeholder 敵人」（`flower_spirit`／`red_eye_imp`／`zombie_thrall`／`centipede_brood`／
> `tower_wisp`）皆為獨立圖；18 張烤字卡已重製乾淨；12 張戰鬥肖像已統一 768²＋去背；`node_elite.png` 存在。
> 美術重心已從「補洞」轉為「一致性 QA／旅程感凝聚」（見下方統計與本檔頂部風格紀律）。

### ✅ 已解決：卡圖含文字（原 18 張，2026-06-30 全部重製確認）

卡圖原則「**不要出現文字**」（標題／英文／浮水印／數值框／水墨題跋落款）。
例外：**符咒（符／法陣）上的符文字保留**（如 `lxy_tianshi` 天師符、`zl_shuiyin` 法陣；
`zl_jingang` 的金色法陣符文亦屬此例外）。

**狀態**：原本被點名烤進文字的 18 張卡（A 類卡框／標題／英文／浮水印／數值：`zl_huihun`、
`zl_leiguang`、`lyr_tieyi`、`zl_bingxin`、`zl_lingxi`、`zl_shenlei`、`zl_shuiling`、`lyr_xuanjian`、
`zl_jingang`、`tong_ji`；B 類題跋／落款印：`anu_duwu`、`anu_guwang`、`anu_guxue`、`anu_sanmao`、
`lyr_poqian`、`lyr_tianv`、`lyr_tongqianbiao`、`lyr_qijuejianqi`）**已全部重製為乾淨無文字版**
（2026-06-30 逐張讀圖確認）。全卡庫目前無烤字問題。

> ⚠️ **風格觀察（非債，待裁決）**：重製後有數張改採「人物動勢」構圖（`lyr_tieyi`、`zl_shuiling`、
> `lyr_xuanjian`、`zl_jingang`、`anu_guwang`、`lyr_tongqianbiao`），與本指南「卡圖盡量不要出現人物」
> 的軟性原則相左。並非錯誤，但若要維持牌組縮圖的視覺齊整，建議明確裁決人物卡比例上限或分流規則。
> 另：`lyr_qijuejianqi` 與 `lyr_xuanjian` 構圖近乎相同，疑似復用，可複查是否需差異化。

### ✅ 已解決：戰鬥肖像對齊／大小／去背（原 12 張，2026-06-30 確認）

**狀態**：四角色 × 6 姿勢全部已統一 **768×768 ＋ 真透明去背**（2026-06-30 量測：
`lin_yueru_*` 6 張、`zhao_linger_*_v2` 6 張皆 768²；alpha range 0–255、近透明像素 ~74%，
與基準 `li_xiaoyao`／`anu` 同級，林月如不再是白底）。程式端 `UIFactory.ground_portrait`
做底部對齊。對齊／大小／去背三問題均已收斂。

**規格備忘（未來重出 `assets/art/battle_characters/<id>_<pose>.png` 時沿用）**：
1. 畫布統一 **768×768**（正方）。
2. 強制透明去背（PNG RGBA，不可白底）。
3. 人物高度一致：頭頂→腳底約佔畫布高 85–90%。
4. 腳底對齊同一基準線：約在畫布底部 ~92% 處。
5. 人型敵人比照同一人物高度；大型／非人型 boss 才可放大。

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

### 🟢 全部已補實（流派卡 8 + 等級解鎖卡 27 + 專武遺物 2 + 連打/毒引擎 17 + colorless 10）

上述各批原列的「借圖待補」**已全部補上專屬卡圖**，`game_data.gd` 內 `art_id` 借圖參數實際使用量 = **0**
（2026-06-30 `grep art_id scripts/game_data.gd` 僅剩函式簽名定義與 `image_id` 賦值兩處）。
故原本逐張的借圖對照表（lxy 御劍連擊 4、zl 連咒 4、lyr 鞭劍連擊 4、anu 蠱毒/鬼冥 10、colorless 10 等）
已無作用，移除以免誤導協作者重畫。專武 `wuyue_shendao`（巫月神刀）／`fengming_dao`（鳳鳴刀）已配專屬圖示。

> 若日後新增卡牌再以 `art_id` 暫借，請在本處補一張「現役借圖」小表，並於補實後即時刪除。

## Card Layering Convention

Card UI should follow a fixed rendering stack so art replacements do not require layout rewrites:

1. Card art at the bottom
2. Card frame above the art
3. Decorative overlays above the frame
4. Text as the topmost layer

Decorative overlays include the mana badge, rarity badge, name plaque, and rules-panel ornaments. When replacing the three card frames with ink-wash versions, keep those elements as separate overlays unless they must be baked into the frame for a specific visual effect.

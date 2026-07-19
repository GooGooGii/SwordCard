# PAL1 敵人立繪參考板

> 敵人與 Boss 重製必須先實際查看 PAL1 原作／官方復刻圖，完成辨識元素、禁用元素與 prompt，經使用者核可後才可生成候選立繪。

## 鬼將軍／殭屍王（將軍塚第一層 Boss）

### 原作參考（已實際查看）

1. [新仙劍鬼將軍 Boss 實際戰鬥圖](https://www.gamersky.com/handbook/201507/620005_14.shtml)：本地保存 `tmp/pal1_refs/tomb_boss/ghost_general_gamersky.jpg`。
2. [新仙劍將軍塚棺槨與現身流程](https://aikoaction.pixnet.net/blog/posts/1030587884)：確認鬼將軍由棺槨現身，戰後地裂墜入血池。
3. [DOS 版將軍塚攻略](https://chiuinan.github.io/game/game/intro/ch/c11/pal/pal/pal-dos.htm)：原版稱殭屍王，怕火，擊敗後地板崩塌。

### 原作可辨識元素

- **體型：** 遠大於正常人，寬肩厚重、上半身前傾，帶有從棺中爬出的壓迫感。
- **頭部：** 骷髏化／乾屍化面容，凹陷眼窩、外露牙齒、亂黑髮；不是青面鬍鬚武將。
- **盔甲：** 金褐／銅褐色腐朽古代將軍甲，大型獸面或厚重肩甲，甲片殘破失色。
- **衣料：** 暗紅破布與黑褐殘披掛從盔甲間垂落，邊緣撕裂。
- **姿勢：** 雙臂向外伸展、十指如枯爪，身體扭曲前撲；沒有手持武器。
- **輪廓：** 左右不完全對稱，一側手臂或甲片更殘破，整體像巨大腐屍而非整齊站立的士兵。
- **方向：** 正式戰鬥站在右側，臉部、胸口與撲擊動勢須朝向左側玩家。

### 現役立繪的錯誤

- 直立站姿過於端正，接近普通亡靈武將。
- 手持大型關刀；原作鬼將軍以枯爪撲擊，沒有武器。
- 青綠皮膚、完整華麗盔甲與飄動披風偏向泛用奇幻 undead knight。
- 體型偏高瘦；原作是寬大、腐朽、前傾的巨大屍王。
- 缺少原作鮮明的骷髏臉、金褐殘甲與暗紅破布。

### 禁用元素

- 關刀、長槍、劍、盾或任何手持武器。
- 完整精亮鎧甲、英雄式站姿、騎士披風、發光符文。
- 西式骷髏騎士、吸血鬼、巫妖王或青面長鬚關公造型。
- 血池、紅色液體底座或赤鬼王特徵。
- 背景、地面、文字、UI、陰影底板；輸出必須為乾淨透明角色立繪。

### 候選生成 Prompt（已核可並執行）

`PAL1-faithful Ghost General / Zombie King full-body enemy portrait for a Godot card-battle game, derived directly from the verified New Legend of Sword and Fairy Ghost General battle sprite: a gigantic broad-shouldered ancient Chinese corpse general leaning and lunging forward, much wider and heavier than a normal human, skeletal desiccated face with deep eye sockets, exposed teeth and wild tangled black hair, decayed dark bronze and tarnished gold lamellar armor with massive broken shoulder guards, ragged dark-red cloth and black-brown funeral fabric hanging between damaged armor plates, both long corpse arms spread outward with empty claw-like hands and crooked fingers, no weapon, asymmetrical damaged silhouette, oppressive undead weight rather than heroic posture, face chest and attack motion clearly directed toward screen-left player, mature hand-painted Chinese ink-and-gouache illustration matching SwordCard, strong readable silhouette at battle size, transparent background, no text, no watermark, no floor, no blood pool, no sword, no polearm, no shield, no glowing runes, no Western knight armor.`

### Gate 狀態

| 項目 | 狀態 |
|---|---|
| 原作／官方復刻圖已實際查看 | ✅ 2026-07-19 |
| 現役差異分析完成 | ✅ 2026-07-19 |
| 參考板向使用者展示 | ✅ 已核可（2026-07-19） |
| 候選立繪生成 | ✅ `zombie_general_pal1_v2.png`（2026-07-19） |
| 左右朝向對照實機驗收 | ✅ 朝左版本已核可（2026-07-19） |
| 正式資產接入 | ✅ 第四幕 `ghost_general` 專用立繪（2026-07-19） |

---

## 赤鬼王（將軍塚第二層 Boss）

### 原作參考（已實際查看）

1. [新仙劍赤鬼王 Boss 實際戰鬥圖](https://www.gamersky.com/handbook/201507/620005_15.shtml)：赤鬼王以巨大上半身浮在血池中，與右側三名角色對峙。
2. [新仙劍血池對峙與台詞流程](https://aikoaction.pixnet.net/blog/posts/1030587884)：本地保存 `tmp/pal1_refs/tomb_boss/scene_4.jpg` 至 `scene_6.jpg`，可確認臉、官帽、服裝、血池下半身與左右朝向。
3. [DOS 版將軍塚／血池攻略](https://chiuinan.github.io/game/game/intro/ch/c11/pal/pal/pal-dos.htm)：確認赤鬼王位於血池最深處，掉落土靈珠，與上層殭屍王是不同 Boss。

### 原作可辨識元素

- **體型：** 巨大、寬厚的上半身直接浮出血池；與英雄相比明顯是 Boss 級尺寸，不是正常人跪在水中。
- **頭部：** 高聳黑色古代官帽，正面有縱向稜線；灰白屍臉、紅眼、粗黑眉、黑色鬍鬚與獠牙般怒容。
- **服裝：** 黑褐／深炭色寬大官袍，領襟有暗紅與灰藍交疊紋理，輪廓厚重。
- **姿勢：** 上身前傾，一手壓低、一臂外張或撐在血面，像從血池升起質問眾人；不是垂手站直。
- **下半身：** 腰部以下完全沒入、溶入或被血霧遮蔽，以不規則血浪收尾；不畫腿腳。
- **方向：** 正式站在右側，臉、胸口與動勢朝向左側玩家。
- **色彩：** 灰白臉與黑袍由高飽和暗紅血浪托起，紅色集中在眼睛、袍緣與血面。

### 現役立繪的錯誤

- 體型接近普通人，肩寬與頭身比例不足，實機缺乏原作巨大壓迫感。
- 垂手跪立、姿勢僵直，像一般殭屍官員而不是從血海升起的魔王。
- 臉部偏骷髏化且表情平淡；原作有清楚眉眼、怒容、鬍鬚與紅眼。
- 官袍過於單薄破舊，缺少原作寬厚黑袍與交疊領襟。
- 血池底座小而平，未與下半身自然融合，也沒有向外翻湧的血浪。

### 禁用元素

- 腿、鞋、完整站姿、跪姿或可見下半身。
- 王座、武器、法杖、盔甲、披風、骷髏騎士元素。
- 西式吸血鬼、惡魔角、火焰、岩漿或橘色魔法。
- 背景洞穴、地面或矩形底板；只保留角色與自然收尾的血浪／紅霧。
- 文字、符紙字樣、UI、水印與大面積白色底。

### 候選生成 Prompt（已核可並執行）

`PAL1-faithful Red Ghost King full-body enemy portrait for a Godot card-battle game, derived directly from the verified New Legend of Sword and Fairy blood-pool confrontation and battle sprite: an enormous broad heavy upper body rising directly from a dark crimson blood pool, dramatically larger than a normal human, no visible legs or feet, waist and lower robe dissolving naturally into irregular spreading blood waves and low maroon mist, tall black ancient Chinese official hat with strong vertical ridges, pale gray corpse face with glowing dark-red eyes, thick black brows, fierce angry expression, black mustache and beard, subtle exposed fangs, massive charcoal-black and deep brown official robe with broad sleeves and layered dark-red and muted blue-gray collar trim, torso leaning toward screen-left player, one heavy arm braced low near the blood surface and the other reaching or spreading outward in accusation, mature hand-painted Chinese ink-and-gouache illustration matching SwordCard, strong readable boss silhouette at battle size, transparent background, no text, no watermark, no floor, no cave background, no throne, no weapon, no staff, no armor, no legs, no shoes, no fire, no magma, no Western vampire styling.`

### Gate 狀態

| 項目 | 狀態 |
|---|---|
| 原作／官方復刻圖已實際查看 | ✅ 2026-07-19 |
| 現役差異分析完成 | ✅ 2026-07-19 |
| 參考板向使用者展示 | ✅ 已核可（2026-07-19） |
| 候選立繪生成 | ✅ `tomb_general_pal1_v2.png`（2026-07-19） |
| 左右朝向與雙層 Boss 實機驗收 | ✅ 朝左版本搭配半血池背景已核可（2026-07-19） |
| 正式資產接入 | ✅ 赤鬼王專用立繪與 `battle_bg_boss_tomb_general_v2.png`（2026-07-19） |
---

## 火眼麒麟（第五幕 Boss）

### 原作參考與辨識元素

1. [新仙劍火眼麒麟實際戰鬥圖](https://www.gamersky.com/handbook/201507/620005_39.shtml)：本地 `tmp/pal1_refs/fire_qilin/boss_040.jpg`。
2. [95 版火麒麟洞戰勝畫面](https://www.gamersky.com/handbook/201607/786402_46.shtml)：本地 `image258.jpg`、`image259.jpg`。
3. [火麒麟洞劇情流程](https://gamegene.cn/wiki/364)：確認其為守護火靈珠、戰後化為麒麟老人的火眼麒麟。

- 四足低伏、厚重而修長的中國麒麟輪廓；龍首、鹿角／獨角、鬃毛、長尾和清楚獸爪。
- 主色是熾紅、朱橙與金黃，背脊和鬃毛像內部發熱，但身體仍是實體瑞獸，不是純火焰元素怪。
- 正式站在右側，頭部、胸口與撲擊動勢朝向畫面左側玩家。
- 禁止西式獅子、惡魔角、鎧甲、鞍具、翅膀、人形、三頭蜥蜴或全身被火焰遮沒。

### 候選生成 Prompt（已核可並執行）

`PAL1-faithful Fire-Eyed Qilin enemy portrait derived directly from the verified New Legend of Sword and Fairy battle sprite: a huge low-crouching four-legged Chinese qilin with a long heavy body, fierce dragon-like head, swept antler-like horn, thick flame-shaped mane, long curved tail and powerful clawed feet, solid anatomical body in saturated vermilion red, ember orange and molten gold with dark crimson shadow planes, glowing yellow-red eyes, body and attack momentum clearly facing screen-left toward the player, mature hand-painted Chinese ink-and-gouache illustration matching SwordCard, transparent background, no text, no watermark, no ground, no cave background, no rider, no armor, no saddle, no wings, no Western lion, no demon, no humanoid, no three heads, not made entirely of flames.`

### Gate 狀態

| 項目 | 狀態 |
|---|---|
| 原作圖已實際查看 | ✅ 2026-07-19 |
| 參考板向使用者展示 | ✅ 已核可（2026-07-19） |
| 候選立繪生成 | ✅ `fire_qilin_pal1_v1.png`（2026-07-19） |
| 左右朝向實機驗收 | ✅ 朝左版本已核可（2026-07-19） |
| 正式資產接入 | ✅ 第五幕火眼麒麟專用立繪（2026-07-19） |
---

## 鎮獄明王（第六幕 Boss）

### 原作參考（已實際查看）

1. [新仙劍鎮獄明王實際戰鬥圖](https://www.gamersky.com/handbook/201507/620005_28.shtml)：本地 `tmp/pal1_refs/zhenyu_mingwang/boss_029.jpg`。
2. [95 版鎮獄明王戰鬥流程](https://www.gamersky.com/handbook/201607/786402_24.shtml)：本地 `scene_138.jpg`、`scene_139.jpg` 等。
3. [仙劍系列鬼怪圖鑑：鎮獄明王](https://www.gamersky.com/handbook/201608/798962_2.shtml)：確認核心辨識為三眼六臂、二郎神與哪吒式神將形象。

### 原作可辨識元素

- 巨大、寬肩、裸上身的神將身軀，盤腿或半浮坐姿，整體比英雄大數倍。
- 正面額頭有第三眼；黑色怒髮向上張開，濃黑眉、長鬚與威怒面孔。
- 明確六臂，手臂以扇形向兩側與上方張開；多數手握拳或結印，不依靠武器辨識。
- 下身穿藍綠、紅、金相間的短裙與斜跨披帶，金色腰飾；胸腹大面積裸露。
- 正式位於右側時，臉、胸口與主要手勢朝向畫面左側玩家。

### 現役立繪問題與禁用元素

- 現役是全身金甲、多武器、四臂觀感，較像原創天將；遮住原作裸胸、三眼與六臂核心。
- 禁止全覆式盔甲、降魔杵、彎刀、鎖鏈武器、火焰光輪、披風與站立衝鋒姿勢。
- 禁止西式惡魔、骷髏王、機械手臂、八臂以上、缺少第三眼或缺少六臂。
- 透明背景；無地面、陰影底板、文字、UI 或水印。

### 候選生成 Prompt（待核可）

`PAL1-faithful Zhenyu Mingwang transparent enemy portrait derived directly from the verified New Legend and DOS/95 battle sprites: an enormous broad-shouldered bare-chested divine jailer in a grounded cross-legged or half-floating seated pose, exactly six muscular arms fanning clearly upward and sideways with mostly clenched fists or stern mudra gestures, no handheld weapons, a clearly visible third eye centered on the forehead, wild black hair rising behind a small restrained gold crown, thick black eyebrows, fierce human face, long black mustache and beard, blue-green red and gold layered short battle skirt and diagonal ceremonial sash, gold waist ornaments, mature hand-painted Chinese ink-and-gouache illustration matching SwordCard, powerful readable silhouette at battle size, body face and primary gestures directed toward screen-left player, transparent background, no text, no watermark, no floor, no full-body armor, no polearm, no sword, no chains, no fire halo, no Western demon, exactly six arms.`

### Gate 狀態

| 項目 | 狀態 |
|---|---|
| 原作圖已實際查看 | ✅ 2026-07-19 |
| 現役差異分析完成 | ✅ 2026-07-19 |
| 參考板向使用者展示 | ✅ 已核可（2026-07-19） |
| 候選立繪生成 | ✅ `zhenyu_mingwang_pal1_v3.png`（2026-07-19） |
| 左右朝向實機驗收 | ✅ 頭部與高膝同側朝向玩家（2026-07-19） |
| 正式資產接入 | ✅ 第六幕鎮獄明王專用立繪（2026-07-19） |

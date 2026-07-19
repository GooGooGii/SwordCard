# PAL1 Boss 戰鬥背景：原作參考板

> 本文件是 Boss 專屬背景的強制繪製 gate。每一張背景必須先查看 PAL1 原作／官方復刻遊戲圖、向使用者展示並取得核可，才可生成候選圖。候選完成後必須以「多件遺物＋滿藥格」的實機戰鬥 UI 驗收。

## 苗人頭領 — 餘杭客棧一樓大堂

### 原作圖像參考

1. **官方《新仙劍奇俠傳》苗人頭領戰鬥圖**
   [游民星空 Boss 圖鑑：苗人頭領（餘杭客棧）](https://www.gamersky.com/handbook/201507/620005_3.shtml)
   確認 Boss 戰發生於客棧內；寬闊灰色方磚地、深色木牆、格窗、桌椅與室內盆栽清楚可見。
2. **95／98 版黑苗戰與苗人頭領對峙畫面**
   [餘杭客棧與仙靈島圖文攻略](https://gi780602.pixnet.net/blog/posts/11404957512)
   相關圖位於「黑苗族，戰鬥畫面」及後段「黑苗族，拜月教」：朱紅木柱與格窗、右上紅燈籠、灰磚地、木桌長凳、盆栽；苗人頭領在同一大堂帶兩名苗人迎戰。
3. **95 版餘杭客棧一樓全景／座標圖**
   [仙劍奇俠傳 1 圖文攻略：餘杭客棧](https://serverless-page-bucket-2mxrpvxa-1253933558.cos-website.ap-shanghai.myqcloud.com/xjgl/p1.htm)
   確認大堂格局：大面積灰磚中央活動區、左側櫃台與廚房、四周朱紅格窗、後方木樓梯、分散的方桌與長凳。

本地檢視用參考圖保存在 `tmp/pal1_refs/miao_inn/`；不作為遊戲資產提交。

### 可辨識元素

- **空間身分：** 餘杭客棧一樓大堂，不是仙靈島戶外、客房、林家堡或豪華酒樓。
- **地面：** 冷灰色大方磚，規整斜向透視縫；中央寬敞、可供五人交戰。
- **建築：** 朱紅／深紅木牆、木柱、密集中式格窗；木作樸實，帶早期江南村鎮客棧感。
- **家具：** 深褐色方桌、圓桌、長凳；靠畫面兩側與後景放置，中央戰鬥區保持淨空。
- **裝飾：** 少量盆栽、右後側一排暖紅燈籠；可在遠側暗示通往二樓的木梯。
- **光線：** 夜間或清晨前的室內暖燈，整體仍須清晰可讀；灰磚受暖光形成低對比反射。
- **氣氛：** 本來日常、樸素的家族客棧突然遭黑苗人闖入；緊張但不是鬼屋或邪教大殿。

### 禁用元素

- 仙靈島蓮池、竹林、庭院、山景或戶外天空。
- 蘇州豪華酒樓、林家堡式雕樑畫棟、大型舞台。
- 王座、祭壇、法陣、骷髏、血跡、火災、破敗廢墟。
- 西式酒館吧台、玻璃酒瓶、吊燈、石砌城堡。
- 過量金飾、巨型龍雕、霓虹、現代餐廳元素。

### 本作 16:9 構圖草案

- **上方／後景：** 朱紅木牆與格窗橫向建立客棧身分；右後側掛 3–4 盞暖紅燈籠，左後側以盆栽或樓梯收邊。
- **兩側：** 左右邊緣各保留一組被推開的木桌／長凳，家具不可侵入玩家與三敵站位。
- **中央與下中段：** 大面積連續灰磚戰場，保留角色、三名敵人、HP、意圖與傷害數字的清楚輪廓。
- **UI 安全區：** 頂部中央遺物與三格藥品可與後牆／燈籠視覺重疊，因此該區使用低細節深色木牆；不放高對比窗光或醒目招牌。
- **透視：** 接近原作的略俯視室內空間，但降低等角感，與 SwordCard 側視戰鬥人物的腳底線相容。

### 候選生成 Prompt（待使用者核可後使用）

`PAL1-faithful Yuhang inn first-floor hall Boss battle background, based directly on the official New Legend of Sword and Fairy and 95/98 game scenes: a broad cool-gray square-tiled floor kept open across the center and lower middle, rustic deep vermilion wooden walls and dense Chinese lattice windows across the back, a modest wooden stair suggested in one rear corner, several dark brown square tables and long benches pushed safely to the far left and right edges, two restrained potted plants, three or four warm red lanterns hanging along the upper-right wall, tense pre-dawn indoor atmosphere with warm lantern light but clear readable values, humble Jiangnan fishing-village family inn rather than a palace, mature hand-painted Chinese ink-and-gouache environment matching SwordCard, 16:9 PNG, no characters, no text, no watermark, no outdoor scenery, no lotus pond, no luxury restaurant, no throne, no altar, no magic circle, no horror, no fire, keep the top-center relic and potion UI zone low-detail and dark, keep the center and lower-middle completely open for one player and three enemies.`

### Gate 狀態

| 項目 | 狀態 |
|---|---|
| 原作／官方復刻圖已實際查看 | ✅ 2026-07-18 |
| 參考板已向使用者展示 | ✅ 已核可（2026-07-18） |
| 候選背景生成 | ✅ `battle_bg_boss_miao_chieftain_v1.png`（2026-07-18） |
| 多遺物＋滿藥格實機驗收 | ✅ 已核可（2026-07-18） |
| 正式資產替換／程式接入 | ✅ 苗人首領專用背景與新版立繪已接入（2026-07-18） |

---

## 赤鬼王 — 將軍塚地底血池

### 原作場景參考（已實際查看）

1. **新仙劍：鬼將軍墓室與棺槨**
   [新仙劍破關記錄：將軍塚、血池與赤鬼王](https://aikoaction.pixnet.net/blog/posts/1030587884)
   冷灰藍方形石磚、厚重黑石牆、石階與中央棺槨；此處是鬼將軍戰及墜落前場景，只作為「上層墓室」對照，不直接當赤鬼王背景。
2. **新仙劍：墜入血池後的岩台**
   [同篇原作流程截圖](https://aikoaction.pixnet.net/blog/posts/1030587884)
   大面積高飽和猩紅液面、深褐黑的不規則天然岩台，人物只能站在少數露出血面的岩塊上。
3. **新仙劍：赤鬼王對峙與戰鬥**
   [赤鬼王（血池）Boss 圖鑑](https://www.gamersky.com/handbook/201507/620005_15.shtml)
   赤鬼王半身浮於血池，遠景幾乎被紅霧與血水吞沒；英雄位於右側斜岩平台，整體沒有宮殿、墓門或王座。
4. **DOS／95：將軍塚與血池完整場景座標圖**
   [DOS 版將軍塚圖文攻略](https://chiuinan.github.io/game/game/intro/ch/c11/pal/pal/pal-dos.htm)
   上層／下層是密集墓道；打敗殭屍王後地板崩塌，血池由連續紅色液面與零散深色浮岩構成，最深處標示赤鬼王。

本地查證圖保存於 `tmp/pal1_refs/tomb_boss/`，包含墓室、墜落岩台、赤鬼王對話／戰鬥與 DOS 場景總圖。

### 原作可辨識元素

- **場景定位：** 將軍塚下方的血池最深處，不是將軍墓室本身。
- **地面：** 可站立區是不規則、粗糙、近黑紅色的天然岩台；不能把整個下半部畫成平整石磚。
- **環境：** 岩台外圍是連續血池，紅色液面帶暗色旋流、霧氣與微弱反光。
- **結構：** 遠處以低矮浮岩和洞壁剪影形成層次；沒有人工柱列、祭壇、墓碑或棺槨。
- **光線：** 血池本身提供暗紅下照光，岩台上緣偏赤、凹面近黑；整體壓抑但角色輪廓仍須清楚。
- **氣氛：** 潮濕、窒息、邪術長期聚血的地下深處；不是火山熔岩，也不是燃燒地獄。

### 禁用元素

- 熔岩裂縫、火焰柱、火山噴發、橘黃色岩漿。
- 王座、魔王城、哥德尖塔、惡魔雕像、巨大魔法陣。
- 將軍墓門、棺槨與整片方磚地板（屬於墜落前的鬼將軍墓室）。
- 大量白骨、骷髏旗、刑具或現代恐怖片式血肉牆。
- 把赤鬼王本人或任何角色畫進背景。

### SwordCard 16:9 構圖草案

- **中央與下中段：** 一塊橫向延展、足以容納玩家與最多三名敵人的黑紅岩台；表面略有高低紋理，但角色腳底區保持平順清楚。
- **左右邊緣：** 岩台逐漸碎裂並沉入血池，可放少量較低的浮岩引導視線，不侵入角色站位。
- **後景：** 大面積暗紅血池向洞穴深處延伸，遠端以黑色洞壁與紅霧收束，不建立人工建築中心線。
- **UI 區：** 頂部中央遺物與藥品區保持暗、低細節；意圖數字後方避免高亮紅白浪花。
- **讀圖重點：** 血池與岩台必須一眼可分；HP 紅條仍靠較暗岩台承托，避免整張畫面紅成一片。

### 候選生成 Prompt（待使用者核可後使用）

`PAL1-faithful Red Ghost King boss battle background at the deepest blood pool beneath the General's Tomb, based directly on the DOS/95 and New Legend of Sword and Fairy scenes: one broad irregular natural black-red rock shelf spanning the center and lower middle as a stable battle platform for one player and up to three enemies, its rough upper surface readable but not busy beneath character feet, an immense continuous dark crimson blood pool surrounding the shelf and receding into the cavern, restrained slow maroon currents and low red mist, scattered low basalt-like stepping rocks only near the far edges, shadowy natural cave walls fading into the rear, oppressive wet subterranean atmosphere illuminated from below by muted blood-red reflected light, deep charcoal shadows and controlled crimson highlights, mature hand-painted Chinese ink-and-gouache environment matching SwordCard, 16:9 PNG, no characters, no text, no watermark, no lava, no fire, no orange magma, no throne, no palace, no altar, no magic circle, no coffin, no tomb gate, no tiled floor, no skeleton banners, keep the top-center relic and potion UI zone dark and low-detail, preserve clear silhouettes and HP readability.`

### Gate 狀態

| 項目 | 狀態 |
|---|---|
| 至少三張原作／可信攻略圖已實際查看 | ✅ 2026-07-18 |
| 參考板已向使用者展示 | ✅ 已核可（2026-07-18） |
| 候選背景生成 | ✅ `battle_bg_boss_tomb_general_v2.png`：左側岩台、右側連續血池（2026-07-19） |
| 多遺物＋滿藥格實機驗收 | ✅ 已核可（2026-07-19） |
| 正式資產替換／程式接入 | ✅ 赤鬼王半身浸入血池專用路由（2026-07-19） |

---

## 鬼將軍 — 將軍塚墓室

### 原作場景參考（已實際查看）

1. **新仙劍：鬼將軍 Boss 實際戰鬥畫面**
   [鬼將軍 Boss 圖鑑](https://www.gamersky.com/handbook/201507/620005_14.shtml)
   已直接取得並查看頁面原圖 `image015.jpg`：大型腐朽披甲鬼將軍位於冷灰藍方磚墓室，四周為厚重深色石牆；敵我站在平整墓室地坪，沒有血池或紅霧。
2. **新仙劍：中央棺槨與鬼將軍現身**
   [同篇墓室劇情截圖](https://aikoaction.pixnet.net/blog/posts/1030587884)
   墓室中央偏後設有大型長方形石棺／棺槨，鬼將軍由其中現身；房間以低矮黑石牆、石階與開闊方磚構成。
3. **新仙劍：將軍塚墓室流程對照**
   [將軍塚與血池流程截圖](https://aikoaction.pixnet.net/blog/posts/1030587884)
   連續畫面確認棺槨現身、鬼將軍戰、戰後地裂墜落與血池是依序發生的不同場景。
4. **DOS／95：將軍塚上層與下層座標總圖**
   [DOS 版將軍塚圖文攻略](https://chiuinan.github.io/game/game/intro/ch/c11/pal/pal/pal-dos.htm)
   將軍塚由密集墓道、石室與樓梯構成，路線終點才是將軍墓；打敗殭屍王後地面崩塌進入血池。

本地查證圖保存於 `tmp/pal1_refs/tomb_boss/`：`ghost_general_gamersky.jpg`（鬼將軍實際 Boss 戰）、`scene_2.jpg`（棺槨現身）、`pal_dos_general_tomb_lower.jpg`（DOS 場景總圖）。`scene_1.jpg` 已確認是白無常雜兵戰，明確排除、不列入 gate。

### 原作可辨識元素

- **場景定位：** 將軍塚迷宮最深處、墜入血池之前的封閉將軍墓室。
- **地面：** 冷灰藍方形石磚，略有磨損、接縫與陰濕反光；中央需足夠平整供角色站立。
- **建築：** 厚重黑灰石牆、低矮石階、墓室門洞；石材方正、壓迫，不是華麗宮殿。
- **核心物件：** 大型長方形石棺放在後方或側後方，必須避開戰鬥站位與 UI。
- **光線：** 幽冷藍灰主光，極少量暗黃墓燈或縫隙微光；人物與敵人輪廓仍清楚。
- **氣氛：** 封閉、沉重、久無人跡的古墓；戰後才會地裂，不提前出現血池。

### 禁用元素

- 血池、紅霧、血河、赤色液面或岩漿（屬於第二層赤鬼王戰場）。
- 室外山景、亂葬崗、殘旗大軍與露天天空。
- 王座、祭壇、魔法陣、哥德教堂或西式地下城。
- 遍地骷髏、刑具、骷髏旗與大量 gore。
- 把鬼將軍、角色或其他人物畫進背景。

### SwordCard 16:9 構圖草案

- **中央與下中段：** 寬闊冷灰石磚地坪，維持平整清晰的共同腳底線。
- **左後／右後：** 一側放低矮石階與墓門，另一側放大型棺槨；兩者均壓在邊緣，不侵入角色區。
- **後景：** 深色厚石牆與少量立柱／門框形成封閉感，中軸保持低細節，避免干擾遺物與藥品。
- **地裂暗示：** 地面可有極細、未完全裂開的舊接縫，但不可畫出已崩塌的大洞；劇情發生後才墜落。
- **讀圖重點：** 鬼將軍深綠黑盔甲需從藍灰墓室中分離，棺槨不能與 Boss 輪廓重疊。

### 候選生成 Prompt（待使用者核可後使用）

`PAL1-faithful Ghost General boss battle background inside the deepest burial chamber of the General's Tomb, based directly on the verified New Legend and DOS/95 scenes: a broad cool blue-gray square-stone tiled floor spanning the center and lower middle, worn damp joints and restrained cold reflections but a stable readable standing plane for one player on the left and one large armored enemy on the right, massive dark charcoal stone walls enclosing the room, a modest low stone stair and heavy tomb doorway pushed to one far rear edge, one large rectangular ancient stone sarcophagus placed safely at the opposite rear edge, sparse old bronze tomb lamps with very dim warm points, oppressive sealed underground atmosphere, mature hand-painted Chinese ink-and-gouache game environment matching SwordCard, 16:9 PNG, no characters, no text, no watermark, no blood pool, no red mist, no lava, no outdoor sky, no battlefield flags, no throne, no altar, no magic circle, no gothic church, no skeleton banners, keep the top-center relic and potion UI zone dark and low-detail, preserve the center and lower-middle as clear battle space.`

### Gate 狀態

| 項目 | 狀態 |
|---|---|
| 至少三張原作／可信攻略圖已實際查看 | ✅ 2026-07-18 |
| 參考板已向使用者展示 | ✅ 修正白無常誤標後重新核可（2026-07-19） |
| 候選背景生成 | ✅ `battle_bg_boss_ghost_general_v1.png`（2026-07-19） |
| 多遺物＋滿藥格實機驗收 | ✅ 已核可（2026-07-19） |
| 正式資產替換／程式接入 | ✅ 鬼將軍專用墓室路由（2026-07-19） |
---

## 火眼麒麟 — 火麒麟洞後段

### 原作場景參考（已實際查看）

1. [95 版火麒麟洞與戰勝畫面](https://www.gamersky.com/handbook/201607/786402_46.shtml)：本地保存 `tmp/pal1_refs/fire_qilin/image258.jpg`、`image259.jpg`，可見紅色旋流狀洞底、黃色高熱中心與右側黑褐岩岸。
2. [新仙劍火眼麒麟 Boss 圖鑑](https://www.gamersky.com/handbook/201507/620005_39.shtml)：本地保存 `boss_040.jpg`，可見 Boss 洞室是寬闊灰褐岩盤，四周生長大型黃橙晶柱，後壁由暖火光照亮。
3. [火麒麟洞完整劇情攻略](https://gamegene.cn/wiki/364)：確認洞穴只有前後兩段，火眼麒麟位於後段；戰勝後取得火靈珠並化為麒麟老人。

### 構圖與禁用元素

- 玩家站位放在左側較暗、平坦的灰褐岩盤；火麒麟站位放在右側較亮的洞室深處。
- 洞壁與地面以天然岩層為主，黃橙晶柱集中在邊緣和後景，不刺入戰鬥留白。
- 光源來自晶柱、洞底熱氣與少量暗紅反光；不畫成整片熔岩湖。
- 禁止試煉窟祭壇、五靈壁刻、人工石橋、王座、火山天空、宮殿與角色。
- 16:9 PNG，無文字／水印；上中部遺物與藥品區保持低細節。

### 候選生成 Prompt（已核可並執行）

`PAL1-faithful Fire Qilin boss chamber inside the rear section of Fire Qilin Cave, based directly on verified PAL1 95-version and New Legend battle scenes: a broad natural dark gray-brown rock floor with a stable readable standing plane across the left and center, warmer cavern depth on the right for a large quadruped boss, clusters of tall translucent amber and yellow-orange mineral crystals growing only along the rear wall and outer edges, layered rough cave walls lit by restrained red-orange geothermal glow, faint heat haze and deep warm reflections, mature hand-painted Chinese ink-and-gouache game environment matching SwordCard, 16:9 PNG, no characters, no text, no watermark, no altar, no Five-Spirit carvings, no artificial stone bridge, no palace, no throne, no outdoor volcano, no full lava lake, keep the top-center relic and potion UI zone dark and low-detail.`

### Gate 狀態

| 項目 | 狀態 |
|---|---|
| 至少三張原作／可信攻略圖已實際查看 | ✅ 2026-07-19 |
| 參考板向使用者展示 | ✅ 已核可（2026-07-19） |
| 候選背景生成 | ✅ `battle_bg_boss_fire_qilin_v1.png`（2026-07-19） |
| 多遺物＋滿藥格實機驗收 | ✅ 已核可（2026-07-19） |
| 正式資產接入 | ✅ 第五幕火麒麟洞專用路由（2026-07-19） |
---

## 鎮獄明王 — 鎖妖塔內石坪

### 原作場景參考（已實際查看）

1. [新仙劍鎮獄明王 Boss 圖鑑](https://www.gamersky.com/handbook/201507/620005_28.shtml)：本地保存 `tmp/pal1_refs/zhenyu_mingwang/boss_029.jpg`；戰場為大面積灰色長方石磚平台，平台外緣接粗糙岩壁與黑暗空腔。
2. [95 版鎖妖塔鎮獄明王完整戰鬥](https://www.gamersky.com/handbook/201607/786402_24.shtml)：本地保存 `scene_138.jpg` 至 `scene_143.jpg`；確認 DOS／95 戰鬥底色是暗紅水平紋理，沒有王座、祭壇或華麗魔王宮。
3. [DOS 鎖妖塔迷宮詳圖](https://old.palhero.net/200211/players/pal_map/pal_map.htm)：區分鎮獄明王所在塔內層與更深處的化妖池／七星磐龍柱；龍柱不能提前成為明王戰主景。

### 原作可辨識元素與構圖

- **場景定位：** 鎖妖塔內部的寬闊石坪，不是塔底化妖池，也不是七星磐龍柱戰場。
- **地面：** 中央至下中段由磨損的冷灰長方石磚組成，接縫清楚但不畫大型發光法陣。
- **邊緣：** 平台兩側可露出破碎岩緣、垂直塔壁與向下黑暗空腔，暗示塔內高度。
- **建築語彙：** 遠景只保留厚重石牆、少量斷裂鐵鏈、窄門或向上空腔；裝飾克制。
- **光線：** 冷灰主光，極少量暗紅封印反光呼應 95 版；人物輪廓必須清楚。
- 玩家站左、明王站右；中央及下中段保留戰鬥空間，上中部遺物與藥品區低細節。

### 禁用元素

- 巨型盤龍柱作為左右門柱、七星龍柱陣、化妖水池或水面。
- 王座、魔王城、佛寺金殿、祭壇、巨大法陣、滿牆藍色鬼火。
- 戶外天空、山景、熔岩、血池、遍地骷髏或哥德式地牢。
- 任何角色、敵人、文字、UI 或水印。

### 候選生成 Prompt（待核可）

`PAL1-faithful Zhenyu Mingwang boss battle background inside the mid-lower interior of the Demon-Locking Tower, based directly on verified New Legend and DOS/95 battle scenes: a broad elevated platform of worn cold-gray rectangular stone tiles spanning the center and lower middle, stable readable standing planes for the player on the left and one enormous boss on the right, broken rough rock edges at the far sides dropping into a deep black vertical tower void, restrained massive stone walls and a narrow dark upper cavity in the rear, only a few old broken iron chains and subtle dull-red sealing reflections, oppressive ancient tower height, mature hand-painted Chinese ink-and-gouache environment matching SwordCard, 16:9 PNG, no characters, no text, no watermark, no throne, no altar, no glowing magic circle, no giant dragon pillars, no Seven-Star Coiling Dragon formation, no demon-dissolving pool, no blue-flame braziers, no gothic castle, keep the top-center relic and potion UI zone dark and low-detail.`

### Gate 狀態

| 項目 | 狀態 |
|---|---|
| 至少三組原作／可信攻略圖已實際查看 | ✅ 2026-07-19 |
| 參考板向使用者展示 | ✅ 已核可（2026-07-19） |
| 候選背景生成 | ✅ `battle_bg_boss_zhenyu_mingwang_v3.png`（2026-07-19） |
| 多遺物＋滿藥格實機驗收 | ✅ 左下站立石坪擴張版已核可（2026-07-19） |
| 正式資產接入 | ✅ 第六幕鎮獄明王專用路由（2026-07-19） |

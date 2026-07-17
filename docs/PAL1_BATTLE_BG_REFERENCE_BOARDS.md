# PAL1 戰鬥背景：場景參考板（繪製前置關卡）

> **狀態：等待美術核可，尚未開始生成／替換任何背景。**
>
> 本文件是 `battle_bg_act_1.png` 至 `battle_bg_act_8.png` 的逐幕繪製 gate。每幕在核可前必須完成三組線上視覺參考的檢視；核可後才可使用對應 prompt 產出單張候選圖。

## 共通視覺規格

- 1280×720、16:9、滿版 PNG；無角色、文字、Logo、水印。
- 厚塗場景原畫＋輕微水墨肌理，對齊現役 Act 2 的材質密度；禁止童話水彩／Q 版 anime。
- 中央及下中段為低對比、可站立的戰鬥空地；主建築、石碑、神像只放兩側或遠景。
- 每張候選圖完成後，先用 `scripts/render_battle_bg_review.gd` 截取戰鬥畫面，確認 16:9 裁切及 UI 可讀性。

## 視覺資料庫

| 代號 | 已檢視來源 | 用途 |
|---|---|---|
| R1 | [《仙劍奇俠傳》95 版全場景圖文攻略](https://www.gamersky.com/handbook/201607/786402.shtml) | 場景截圖主來源；目錄涵蓋仙靈島、水月宮、蘇州、隱龍窟、血池、鎖妖塔、南詔與最終戰。 |
| R2 | [DOS 版主要場景座標](https://pal.52pk.com/shtml/20060401/57065.shtml) | 場景名稱與地理關係核對；包含十里坡、仙靈島、水月宮、蘇州、隱龍窟及後段地點。 |
| R3 | [PAL95 流程攻略](https://xianjian95.readthedocs.io/02-Plot/) | 劇情順序核對；用以避免以續作、重製版或錯誤幕次的畫面取代 PAL1。 |
| R4 | [DOS 版圖文心得](https://taipeigoodgood.pixnet.net/blog/posts/11380279251) | 補充檢視 DOS 版村落、庭院、草地與原作像素環境的建築／地面語彙。 |

## Act 1 — 餘杭／十里坡

- **三組參考：** R1 的餘杭村、R2 的十里坡入口與山神廟座標、R3 的餘杭→十里坡流程。
- **看見的正史語彙：** 竹籬、鄉間石土路、小型山神廟／亭、低矮山村與江南植被；不是幽暗妖林。
- **構圖草案：** 左側竹林與小亭、右側上坡石階及遠村；中央保留乾燥土石戰鬥平台。
- **禁止：** 黃昏恐怖霧、巨大仙山、密集符文、人物。
- **候選生成 prompt：** `PAL1-inspired Yuhang and Shilipo playable battle ground, daytime bamboo hillside path, small humble mountain shrine pavilion on the left, worn stone steps and distant Jiangnan village on the right, open dry earth-and-stone fighting space in the center and lower middle, painterly Chinese xianxia environment concept art with restrained ink texture, mature thick-paint rendering, warm clean daylight, no characters, no text, no watermark, no floating mountains, no dark fantasy, 16:9`.

## Act 2 — 仙靈島／水月宮

- **三組參考：** R1 的仙靈島、水月宮、前期 Boss 場景；R2 的仙靈島入口、迷宮、靈池與水月宮座標；R3 的仙靈島求藥段落。
- **看見的正史語彙：** 白石、水面、蓮與島林；水月宮為隱世居所，清靈而非宮殿觀光全景。
- **構圖草案：** 左側蓮池、白石欄杆；右側半遮的宮門與石階；中央是一片微濕白石平台。
- **禁止：** 巨月、漂浮島、鋪滿畫面的正殿、大型法陣。
- **候選生成 prompt：** `PAL1-inspired Xianling Island and Shuiyue Palace exterior battle ground, lotus pond and white stone railings on the left, a modest side-facing palace gate and damp steps on the right, misty island trees in the distance, broad quiet pale stone platform open in the center for combat, refined Chinese xianxia painterly environment, mature thick paint with subtle ink texture, soft morning mist and clean cool daylight, no characters, no text, no watermark, no floating mountains, no giant moon, no huge magic circle, 16:9`.

## Act 3 — 蘇州／林家堡周邊

- **三組參考：** R1 的蘇州城與林家場景；R2 的蘇州碼頭、城門、林家堡座標；R3 的蘇州城與比武招親流程。
- **看見的正史語彙：** 江南石板、粉牆黛瓦、碼頭／拱橋、燈籠與市井建築；不屬於鬼廟。
- **構圖草案：** 左側粉牆屋簷與燈籠、右側小橋和水道，中央為寬石板街／城郊坪地。
- **禁止：** 墳墓、鬼火、枯樹廢廟、西式街道。
- **候選生成 prompt：** `PAL1-inspired Suzhou outskirts near Lin Family Fortress, Jiangnan cobbled battle street with white plaster walls and dark tiled eaves on the left, a small arched bridge and canal on the right, a few restrained warm lanterns, broad open gray stone paving in the center for combat, mature thick-painted Chinese fantasy environment with subtle ink texture, calm early evening rather than horror, no characters, no text, no watermark, no ghost fire, no ruined temple, 16:9`.

## Act 4 — 將軍塚

- **三組參考：** R1 的黑水鎮、血池與赤鬼王場景；R2 的將軍塚相關坐標資料；R3 的黑水鎮→赤鬼王流程。
- **看見的正史語彙：** 古墓入口、石室／塚前、亡將與血池陰影、殘軍遺跡；不是一般亂葬崗。
- **構圖草案：** 保留現圖灰霧與斷旗；縮小中央石像，加入側置墓門、折斷石燈和裂石空地。
- **禁止：** 可愛鬼火、鋪滿畫面的墓碑、潮濕叢林。
- **候選生成 prompt：** `PAL1-inspired General's Tomb forecourt battle ground, cracked gray stone platform open across the center, a sealed ancient tomb doorway and broken stone lamp on one side, sparse torn military banners and weathered burial mounds in the distance, dry cold gray mist, restrained hints of an undead general's old military legacy, mature thick-painted Chinese fantasy environment with subtle ink texture, no characters, no text, no watermark, no cute ghost fire, 16:9`.

## Act 5 — 試煉窟／火麒麟洞

- **三組參考：** R1 的女媧神殿／地魔獸與後段洞窟畫面；R2 的大理、火麒麟洞、女媧神殿座標；R3 的試煉洞與祭雨流程。
- **看見的正史語彙：** 天然石窟、石台、石橋、五靈試煉痕跡與火麒麟洞的暖色深處；不能退化為泛用水晶洞。
- **構圖草案：** 中央寬石台與低矮石橋；兩側洞壁只見少量五靈刻紋，右後方帶柔和赤橙反光。
- **禁止：** 巨型水晶簇、滿地霓虹、巨型法陣、科幻洞穴。
- **候選生成 prompt：** `PAL1-inspired Trial Cave and Fire Qilin cavern battle ground, natural limestone walls, low ancient stone bridge and broad worn rock platform open in the center, restrained Five Elements carvings on the side walls, subtle warm red-orange glow deep in the cave suggesting the Fire Qilin, mature thick-painted Chinese fantasy environment with light ink texture, readable cavern lighting, no characters, no text, no watermark, no giant crystals, no neon, no giant magic circle, 16:9`.

## Act 6 — 鎖妖塔

- **三組參考：** R1 的鎖妖塔、化妖池、七龍柱等場景；R2 的鎖妖塔各層與盤龍柱座標；R3 的蜀山→鎖妖塔流程。
- **看見的正史語彙：** 塔內高聳石構、封印柱、石階與垂直空腔；封妖禁地，而非戶外城堡或王座大殿。
- **構圖草案：** 左右各一根盤龍封柱、中段石階通往遠方；中央為龜裂圓石坪，遠景向上消失。
- **禁止：** 王座、天空閃電、西式哥德城堡、滿畫面祭壇。
- **候選生成 prompt：** `PAL1-inspired Locking Demon Tower interior battle ground, broad cracked circular stone floor open in the center, two side-set coiled dragon sealing pillars, worn stone stairs and high vertical tower walls receding upward into darkness, sparse blue-green demon flame as ambient light, mature thick-painted Chinese fantasy environment with subtle ink texture, a sealed prison atmosphere not a throne room, no characters, no text, no watermark, no outdoor sky, no western castle, 16:9`.

## Act 7 — 苗疆蠱土

- **三組參考：** R1 的南詔／女媧神殿前後段畫面；R2 的大理、南詔與地下宮殿坐標；R3 的大理→南詔→祭雨流程。
- **看見的正史語彙：** 南疆濕熱植被、部族聚落與祭儀痕跡；苗疆需要人文符號，不是無主的熱帶沼澤。
- **構圖草案：** 左右各有低調木圖騰和褪色彩旗；中央泥石祭場，遠方是濕林與瀑布水氣。
- **禁止：** 骷髏旗、螢光綠沼澤、西方叢林神殿。
- **候選生成 prompt：** `PAL1-inspired Miao frontier ritual clearing, a playable damp earth-and-stone clearing open in the center, weathered wooden tribal totems and faded colorful Miao cloth banners at the sides, vines, shallow water, humid forest and a distant waterfall in mountain mist, mature thick-painted Chinese fantasy environment with restrained ink texture, overcast tropical daylight, no characters, no text, no watermark, no skull flags, no fluorescent green swamp, no western jungle temple, 16:9`.

## Act 8 — 拜月教壇

- **三組參考：** R1 的十年前南詔、水魔獸與最終戰場景；R2 的南詔宮殿與地下宮殿座標；R3 的南詔、祭雨與結局流程。
- **看見的正史語彙：** 南詔宗教石構、濕冷水氣、月夜祭儀與水魔獸前兆；最終戰要保留足夠寬廣石坪。
- **構圖草案：** 中央寬石壇；兩側教壇石柱、低調蛇形／水紋雕刻；遠方山城和月色水霧。
- **禁止：** 金碧皇城、紅黑西式惡魔壇、過多血腥文字／符號。
- **候選生成 prompt：** `PAL1-inspired Moon Worship cult altar in Nanzhao, a broad wet stone ritual platform open across the center for a final battle, side-set carved pillars with restrained serpent and water motifs, tiered altar steps, distant Nanzhao mountain settlement silhouettes, ominous moonlight and cold water mist suggesting the Water Demon Beast, mature thick-painted Chinese fantasy environment with subtle ink texture, no characters, no text, no watermark, no western demon altar, no ornate imperial palace, 16:9`.

## 核可紀錄

| Act | 參考板核可 | 候選生成 | 戰鬥畫面驗收 | 最終替換 |
|---|---|---|---|---|
| 1 | 已核可（2026-07-17） | 已生成候選（2026-07-17） | GPU 實機：小怪／Boss 均通過；留白與立繪對比良好 | 已替換 |
| 2 | 已核可（2026-07-17） | 已生成候選（2026-07-17） | GPU 實機：小怪／Boss 均通過；連續石坪消除站在圍牆上的突兀感 | 已替換 |
| 3 | 已核可（2026-07-17） | 已生成候選（2026-07-17） | GPU 實機：小怪／Boss 均通過；江南水道與街坪辨識清楚 | 已替換 |
| 4 | 已核可（2026-07-17） | 已生成候選（2026-07-17） | GPU 實機：小怪／Boss 均通過；荒塚、墓門與石坪站位清楚 | 已替換 |
| 5 | 已核可（2026-07-17） | 已生成候選（2026-07-17） | GPU 實機：小怪／Boss 均通過；洞橋與暖紅洞深不影響戰鬥可讀性 | 已替換 |
| 6 | 已核可（2026-07-17） | 已生成候選（2026-07-17） | GPU 實機：小怪／Boss 均通過；兩側封柱與中央石坪保有塔內封印感 | 已替換 |
| 7 | 已核可（2026-07-17） | 已生成候選（2026-07-17） | GPU 實機：小怪／Boss 均通過；濕地、彩旗與圖騰不干擾敵我辨識 | 已替換 |
| 8 | 已核可（2026-07-17） | 已生成候選（2026-07-17） | GPU 實機：小怪／Boss 均通過；月夜水面與石壇可承接水魔獸二階段 | 已替換 |

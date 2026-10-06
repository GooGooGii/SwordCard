# 主角群造型復核 — CHARACTER-002

> 最新使用者限制：絕對禁止 Q 版。原版像素／玩偶感不等於大頭短身。Codex 已撤回四至五頭身方向，doll_v2/v3 全部未通過且未發布。重製必須維持正常人体比例與原作裝束，避免幼齡大眼／短腿／誇大頭部。

2026-10-05，使用者試玩回饋「風格詭異、與原作落差很大」。本輪完成來源／現有模型／正式戰鬥畫面復核；沒有生成或替換正式角色資產，也未部署。既有 5/5 是技術交付，不代表美術通過。此批美術狀態改為未通過、待重製。

## 已查看的證據

- 李逍遙、趙靈兒來源：source_art/characters/li_xiaoyao/sheet_v1.png、zhao_linger/sheet_v1.png。均為偏卡通 3D 人偶的多視圖，來源設計已偏離原作質感；不是調整燈光能解決。
- 月如／阿奴／巫后：docs/previews/characters/browser/contact-front45.jpg、contact-attack-final.jpg，及正式 yueru-desktop.png、anu-wuhou-desktop.png。偏寫實人物與既有李／趙混用，服飾細節密度與面部風格不一致。畫面可見衣袖／衣擺與手部拉伸、細碎邊緣；具體網格／UV／權重成因需要逐模型定位，不假定全部都是同一個問題。
- 全隊模型共用 applyToon 三階明暗与輪廓光，不能消除來源比例／貼圖風格差異。戰鬥用 yawToward 朝敵方，配合目前高角度鏡頭多看背側，頭臉辨識不足；應比較相同戰鬥的側前與現有角度，不能為看臉把角色全轉向觀眾而背對敵人。
- 卡牌圖、敵人厚塗立繪與五名主角之間的美術語言也不一致，需要全畫面核對，不能只驗收白底正面來源圖。

## 原作參照（本輪逐張實際查看，PAL1 DOS）

| 角色 | 圖與來源 | 可辨識特徵／限制 |
|---|---|---|
| 李逍遙 | [仙靈島戰鬥](https://codingman.cc/images/pal-dos-walkthrough/ch1-04-island-path-battle.webp)，本機 all-scenes/xianling.webp；[比武招親](https://codingman.cc/images/pal-dos-walkthrough/ch2-07-contest-battle-start.webp)，all-scenes/lin_arena.webp | 深色束髮、淺色／青色上衣、深色長褲、持直劍的戰鬥輪廓；不能套用通用長馬尾仙俠少年。像素圖未提供的細節不得冒稱已確認。 |
| 趙靈兒 | [隱龍窟戰鬥](https://codingman.cc/images/pal-dos-walkthrough/ch2-19-halfsnake-boss-start.webp)，all-scenes/yinlong_cave.webp | 人形深色長髮、藍紫／淺色服裝輪廓；人形與蛇身須分開，不把來源的任意短裙與娃娃臉當成正史。 |
| 林月如 | 同上比武招親戰鬥 | 紫系衣裝、淺色內層／下裝與直劍，俐落戰鬥姿勢。現有官方公仔只能補輔助細節，不能代替 DOS 遊戲原圖的主參照。 |
| 阿奴 | [DOS 結局](https://fairysword.dearchibi.com/wp-content/uploads/2010/04/pal03.jpg)，characters/anu-dos-ending.jpg；[女媧廟戰鬥](https://codingman.cc/images/pal-dos-walkthrough/ch8-23-niugui-battle.webp)，all-scenes/nuwa_temple.webp | 帽形、髮辮、綠系上衣和苗族裝束辨识優先；結局吹笛姿勢不能直接代替持刀戰鬥姿勢。女媧廟網址以 sources.json 為準。 |
| 巫后 | [DOS 現身](https://codingman.cc/images/pal-dos-walkthrough/ch8-08-wuhou-reveal.webp)，characters/wuhou-dos-reveal.webp；all-scenes/nuwa_temple.webp | 紅袍、盤髮、綠色杖頭的辨識輪廓。不可用新增繁複紋飾代替輪廓。 |

使用者先前已授權依原作自主製作及比較，無須重複要求每张確認；本輪未撰寫最終生圖 prompt。以上是原圖特徵核對，不宣稱達到量化 90% 相似度。

## 重製工作順序與驗收

1. CHARACTER-003：先做李逍遙一名的版本化候選，統一「原作造型的高清 3D 重建」方向。臉部清楚、避免玻璃大眼／人偶笑容，保留原作髮型與衣裝，不沿用任意新仙俠造型。原作像素比例與可讀輪廓優先，比例數值要經戰場比對決定。
2. CHARACTER-004：依同一方向重做靈兒、月如、阿奴、巫后，與卡片／敵人放在同畫面核對。不能一邊卡通、一邊寫實；巫后成熟度和其他角色年齡特徵仍須保留。
3. CHARACTER-005：修理投影接縫、空洞、衣袖與裙擺權重，兵器握持與三種動作；比較不動與 attack/hit 多幀。清理細碎邊緣時保留原作必需的髮辮、衣帶和帽飾。
4. CHARACTER-006：正式戰場鏡頭／朝向／材質候選驗收。三藥格＋多遺物＋滿手牌，桌機與手機橫向都要辨識五人；不能靠正面白底或只看 GLB 預算判定通過。先保存新檔名候選，原模型保留到完整候選通過；仍維持 Three.js 真 3D，不偷偷改用 2D 站牌。

五人的正、側、背面與動作、服飾與武器輪廓均需核對。資產預算與既有自動測試是技術底線，不是美術通過證據。本輪復核完成 100%；角色重製尚未開始，原網址內容未變。

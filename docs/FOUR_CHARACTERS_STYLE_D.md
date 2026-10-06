# 四角色 STYLE D 重製 — 2026-10-06

使用者要求重製趙靈兒、林月如、阿奴與巫后。延續已選定的李逍遙 D 正常比例風格，目標為真正可動畫的 3D 戰鬥資產。

## 本輪原作參照

2026-10-06 逐張實際查看以下本機原作圖，並重新檢查來源 HTTP 200。全部標為 PAL1 DOS；像素圖看不到的背面、衣褶與結構須標為重建推測。

| 角色 | 原作圖片／来源 | 已辨識元素 |
|---|---|---|
| 趙靈兒 | [隱龍窟戰鬥](https://codingman.cc/images/pal-dos-walkthrough/ch2-19-halfsnake-boss-start.webp)，`art-references/all-scenes/yinlong_cave.webp` | 長黑髮、藍紫長裙、淺色袖部、施法戰鬥姿態；原圖不提供完整背面 |
| 林月如 | [比武招親](https://codingman.cc/images/pal-dos-walkthrough/ch2-07-contest-battle-start.webp)，`art-references/all-scenes/lin_arena.webp` | 束髮、紫紅／淺色勁裝、持劍戰鬥輪廓；鞭的原作握持需補戰鬥圖核對 |
| 阿奴 | [DOS 結局](https://fairysword.dearchibi.com/wp-content/uploads/2010/04/pal03.jpg)，`art-references/characters/anu-dos-ending.jpg` | 寬帽飾、髮辮、綠系衣裝、頸飾；此圖只涵蓋上半身與吹笛姿勢，持刀戰鬥及下身需另核對 |
| 巫后 | [DOS 現身](https://codingman.cc/images/pal-dos-walkthrough/ch8-08-wuhou-reveal.webp)，`art-references/characters/wuhou-dos-reveal.webp` | 紅長袍、深色盤髮、綠色杖頭、成熟人物氣質 |

## 確認與執行範圍

2026-10-06 使用者最新直接授權：「你自己先產生2d圖，然後再與原作的角色圖比對特徵，相似度大於90%就好，便可開始製作3d」。本輪不再逐張請求確認；先生成，再逐人核對身份關鍵特徵，人工視覺估計 >90% 且無身份特徵錯誤才開始該人 3D。百分比是主觀加權檢查，不是模型量測、不代表使用者已驗收。背面與原圖看不到的細節不計入已證實相似度。

執行：

1. 依李逍遙 `sheet_style_d_v2.png` 的正常人體比例、適度簡化五官、霧面手繪遊戲材質建立同系列四視圖。保留四人身份，禁止 Q 版／大頭短腿／幼齡大眼。
2. 分角色保存新檔名，檢查正側背面、手袖分離、裙擺與髮辮。原作看不到的部分按保守結構重建，記錄限制。
3. 走現有四視图→Hunyuan3D→Blender 流程；每人獨立校正骨架與服裝權重，不照抄李逍遙的局部投影 band 或骨架尺寸。
4. 武器獨立建模，檢查握持、待命／攻擊／受擊與動畫首尾。技術預算沿現有 QA：不超過 15,000 三角面、70 骨、單張不超過 2048² 貼圖。
5. 檢查六方向與動作多幀；正式戰鬥桌機／手機橫向、八張手牌、三張藥牌、多件法寶的 HUD 效果一起驗收。尺寸模擬不代表實體手機效能。
6. 通過候選技術與畫面檢查後再接入版本化正式 URL；更新 TASKS／PROGRESS，說明使用者美術驗收與實體手機狀態。

## 2D 生成與特徵復核

以內建 imagegen 生成，來源 sheet 原樣保留，前／側／背／側抽圖只做切格與統一取景，不重畫來源。完整 [首輪 prompts](art-references/characters/style-d-four-prompts.json)、[月如修正 prompt](art-references/characters/style-d-yueru-v2-prompt.json)。

| 角色 | 最終 2D 來源 | 主觀特徵評估 | 核對重點 |
|---|---|---|---|
| 靈兒 | `zhao_linger/sheet_style_d_v1.png` | 94% | DOS 頭像／結局：雙髮束、藍帶、白立領白袖、深藍胸片；戰鬥藍紫長裙 |
| 月如 | `lin_yueru/sheet_style_d_v2.png` | 94% | 低束髮與左肩髮束、紫白勁裝、深領邊、短衣長褲；v1 高髻太像李逍遙，詳細复核撤回首輪 92% 判斷，不採用 v1 模型 |
| 阿奴 | `anu/sheet_style_d_v1.png` | 95% | 綠帽红褐帶、双羽飾、黑髮辮、綠白上衣、紅褐短裝、赤足 |
| 巫后 | `wuhou/sheet_style_d_v1.png` | 93% | 黑色盤髮、成熟氣質、紅長袍、淺色內衣；綠杖頭在 3D 兵器核對 |

上述百分比是人工視覺判斷，非量測或精確統計；只核對原作可見身份特徵，不把看不到的背面／精確臉部幾何計作證實。見 [2D 比對圖](previews/characters/four-style-d-v1/reference-comparison.jpg) 及人工复核記錄。

## 模型管線與修整

使用 Hunyuan3D MV turbo（5 steps、octree 320；各 seed 記在 visual-review.json），Blender 清理／減面／四視投影／獨立骨架／兵器／idle-attack-hit。單純加大 remesh 並未解決衣料碎邊；用灰模實際檢查發現原始表面存在小孔洞，改以 `close_character_surface.py` 在新 raw 工作檔補合，再投影貼圖與綁定，未修改生成 2D 原圖。

服裝權重每人按 source sheet 校正，`rig_style_d_v3.json` 記錄三名角色的定稿設定，月如使用新來源與 `rig_style_d_v4.json`。細髮與布料仍是簡化 AI 重建；背面及衣褶為推測，不宣稱模型逐像素或五官 90% 相似。

## 本地交付與驗證

四人 2D／3D 製作與本地接入完成 4/4；加上既有李逍遙，正常比例 STYLE D 主角模型已達 5/5。保留舊版本與被拒候選，正式引用如下：

| 角色 | 正式 GLB | 檔案 bytes |
|---|---|---:|
| 趙靈兒 | `public/assets/characters/zhao_linger_style_d_v3.glb` | 1333520 |
| 林月如 | `public/assets/characters/lin_yueru_style_d_v4.glb` | 1175084 |
| 阿奴 | `public/assets/characters/anu_style_d_v3.glb` | 1288724 |
| 巫后 | `public/assets/characters/wuhou_style_d_v3.glb` | 1275772 |

每人 20 骨、單張 2048² 貼圖、idle／attack／hit，三角面均低於 15000。完整 [模型報告](previews/characters/four-style-d-final/browser/validation.json)、[真正 3D 預覽](previews/characters/four-style-d-final/models-overview.jpg)、[正式版戰鬥報告](previews/characters/four-style-d-final/production/validation.json)。六方向加每人十五動畫影格，共 60 影格；正式 production 四張桌機／手機尺寸畫面，八張手牌含三張藥牌、六件法寶狀態，0 載入／執行錯誤、0 HUD 超界。最終 QA 改每名角色獨立導航，避免切換時上一個模型殘留導致截圖標籤失真。

`npm run build` 通過，`npm test` 為 119 passed／1 skipped。沒有改遊戲規則或角色數值。本輪完成本地接入，尚未發布線上；使用者美術驗收、實體手機效能、guard／cast 專屬動作仍待後續處理。

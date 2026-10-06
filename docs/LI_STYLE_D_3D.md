# 李逍遙 STYLE D 真 3D 重製 — CHARACTER-008

> 最新姿勢修正：CHARACTER-009 已上線備戰版 `li_xiaoyao_style_d_ready_v2.glb`，屈膝錯步、持劍戒備與 attack/hit 首尾回 ready；詳見 [備戰交付](LI_COMBAT_READY.md)。下方 v4 為首次造型重製的歷史交付。

2026-10-05，Codex。使用者已選 [D 外觀](previews/characters/li-style-comparison-v1/D-3d-render-concept.png)，正常青年比例、淺色短衣／藍灰腰帶／深色長褲／束髮／直劍；禁止 Q 版。這輪只重製李逍遙，其餘四名角色尚未按 D 重製。

## 正式資產

- `public/assets/characters/li_xiaoyao_style_d_v4.glb`（1,263,840 bytes）：14,194 triangles、20 bones、單張 2048² 貼圖、idle/attack/hit。
- 正式角色資料與戰鬥 fallback 改用新檔名；既有 `li_xiaoyao.glb` 留存，沒有覆寫原模型。新檔名避免舊模型快取。
- [正常比例模型正側面](previews/characters/li-style-d-v4/browser/li_xiaoyao-front45.png)、[攻擊](previews/characters/li-style-d-v4/browser/li_xiaoyao-attack-0.5.png)、[手機正式戰場](previews/characters/li-style-d-v4/production/yueru-mobile.png)。

## 來源與生成記錄

原作依據與選定方向見 [風格比較](LI_STYLE_COMPARISON.md)。實際查看的 DOS 比武招親圖與 D 圖先核對，再使用 imagegen 內建工具產生版本化四視圖，沒有使用被拒的 doll_v2/v3。

`sheet_style_d_v1.png` 為首版四視圖，`sheet_style_d_v2.png` 為改善手／衣帶間隔的來源。定稿設定 `source_art/characters/li_xiaoyao/rig_style_d_v4.json` 使用 `raw_style_d_v2.glb` 與 `views_style_d_v2`；大型 raw 工作檔依既有規範留在本機，不入庫。正式 GLB 已入庫，不依賴本機 raw 即可運行。

生圖要求：exact approved STYLE D Li Xiaoyao, normal adult 7.5-head proportions, mature restrained eyes, ivory short cross-collar tunic, slate-blue sash, charcoal long trousers, ivory shin wraps, black cloth shoes; matte simplified game render. Transparent 2x2 orthographic front/left/back/right full-body turnaround; no sword (獨立建模綁定)。修正版要求 low A pose with hands clear of waist, solid broad ponytail clumps and two solid sash tails, no fraying/holes; no chibi/big heads/toy proportions/text/shadows。側面姿勢與正面非精確數學一致，因此來源不能代替網格／動畫驗收。

工作流：`import_turnaround.py` → `pad_views.py` → 共用 ComfyUI Hunyuan3D MV turbo，seed 10532、steps 5、octree 320 → Blender 清理／14k 減面／四視投影／骨架／PAL1 直劍／三種動作。原始圖片不以腳本重繪。

## 修整與實機驗證

第一批投影與形體有衣帶破洞、腰側手部色彩污染。重新生成較分離的建模姿勢、較簡單的髮尾與衣带，重建骨架座標；下擺權重限制避免隨手臂拉動。不能使用 Q 版 rig。

投影工具新增可選 strict visibility：排除被遮住的相機樣本，缺樣本处用鄰近有效網格頂點色補齊；既有設定仍保持原預設。D 候選另使用局部衣帶區 `[width .18, bottom .30, top .56]` 禁止側面手部投影，保留正背面來源。這是針對本模型的設定，其他角色不能直接照抄。髮尾與衣褶仍屬簡化 AI 網格，未宣稱原圖或模型完美一致。

- [單模型報告](previews/characters/li-style-d-v4/browser/validation.json)：六方向＋八個 attack/hit 時點，有限動態 bounds，0 browser errors / failed requests。
- [候選戰場報告](previews/characters/li-style-d-v4/release/validation.json)：四張桌機／手機橫向，全手牌 8 張、3 張藥品、6 件遺物產生的正式 HUD 效果；0 errors／HUD overflow。
- [正式建置戰場報告](previews/characters/li-style-d-v4/production/validation.json)：無候選攔截，載入新正式 URL，四張截圖、0 errors／HUD overflow。
- 正式更新後 `npm run build` 通過；`npm test` 117 passed、1 skipped。

手機為 Chromium viewport/touch 模擬，尚未做實體手機效能驗收。使用者選 D 代表方向确认，不代表新 GLB 已經過使用者美術驗收。其餘角色與 2D 卡圖的一致性後續處理。

## 後續

原私人網址已發布：[手機試玩](https://xiaoyao-private-play.googoo00166.chatgpt.site)。部署 `appgdep_6ac39e3f61108191a0bd8d8cddb7997a` succeeded；版本 `appgprj_6ac335e5df98819185fb2d64d85bfff3~appgver_6ce73e76545c8191ad4a45feec5e1f1a`，Sites 靜態來源 SHA `354f56966f98bf389fa248230d1a166666be983b`。原帳號私人存取保留。李逍遙製作與上線 100%；全主角群 D 重製 1/5（20%），使用者實機美術與效能驗收仍待回饋。

CHARACTER-004：靈兒／月如／阿奴／巫后依 D 統一重製，仍需各自原作參照、正常比例與正式戰場驗收。不得把李逍遙 1/5 完成寫成主角群 5/5 完成。

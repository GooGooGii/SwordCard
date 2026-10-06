# 李逍遙外觀比較 — CHARACTER-007

> 使用者已選 D（2026-10-05）。選風格完成 100%，由 Codex 接續 CHARACTER-008 製作李逍遙真 3D 候選；正常比例、禁止 Q 版持續有效。下方「待選定」為選擇前的歷史記錄。

2026-10-05，Codex。使用 imagegen 內建工具，共四張版本化參考圖片，候選交付 100%，待使用者選風格。未修改正式資產或發布遊戲。這不是四份完成的可操作角色。

| 編號 | 方向 | 圖片 | 實作狀態 |
|---|---|---|---|
| A | 2D 手繪／古典 RPG | [A](previews/characters/li-style-comparison-v1/A-hand-painted.png) | 平面圖片，可作 2.5D 角色基底 |
| B | 2D 賽璐璐／清晰色塊 | [B](previews/characters/li-style-comparison-v1/B-cel.png) | 平面圖片 |
| C | 2.5D 分層與立體光影概念 | [C](previews/characters/li-style-comparison-v1/C-layered-concept.png) | 概念圖片，尚未分層或實作深度、動畫 |
| D | 3D 遊戲模型外觀 | [D](previews/characters/li-style-comparison-v1/D-3d-render-concept.png) | 生成的渲染風格圖片，不是 GLB 模型 |

## 參考與限制

實際查看本機 PAL1 DOS 比武招親畫面 `docs/art-references/all-scenes/lin_arena.webp`；[原圖來源](https://codingman.cc/images/pal-dos-walkthrough/ch2-07-contest-battle-start.webp)。本次網頁工具無法開啟原圖 URL，本機已保存原圖可正常查看，沒有宣稱網路重新取得成功。右下方李逍遙的深色束髮、淺色短衣、深色長褲、直劍為造型依據。小像素圖不能確認臉部／衣褶等微細節，候選包含重繪解讀，未宣稱量化 90% 相似。

使用者明確禁止 Q 版。四張均維持正常青年人體比例，不使用大頭短身、短腿、幼齡五官與玩偶比例。A 以 DOS 圖作參考；B/C/D 以 A 鎖定服裝、身形、姿勢作媒材比較。人物視線與原 prompt 朝左要求不同，但四張一致且沒有投入正式战場；實作時仍須核對玩家朝敵方向，不把這些比較圖視為通過正式朝向驗收。

## 生成 prompt 記錄

共用約束：Li Xiaoyao from original DOS/1995 Chinese Paladin; compact tied black hair, pale ivory/light cyan cross-collar short tunic, muted blue sash, charcoal long trousers, cloth shin wraps, dark cloth boots, simple straight jian. Normal young adult anatomy about 7.5 heads tall, small natural head, restrained eyes. Absolutely no chibi, superdeformed, short legs, baby faces, toy/Pixar proportions, ornate armor or fantasy long coat. Full body and sword, three-quarter battle idle, plain pale-gray backdrop, subtle grounding shadow, no text/watermark. Costume fidelity first.

- A 媒材：Pure 2D hand-painted classic Taiwanese PC RPG illustration; delicate ink contour, restrained gouache shading, matte pigment, readable cloth folds, natural facial anatomy, medium detail readable when small.
- B 媒材：Pure 2D classic game cel illustration; precise thin linework, 2–3 flat shadow tones, minimal folds, no watercolor texture. Preserve A identity, pose, costume and normal proportions.
- C 媒材：2.5D layered painted game character concept; illustrated face/clothes on gently curved layered surfaces, shallow volume, soft directional light and ambient occlusion, subtle rim. Not cardboard craft, doll or photoreal skin. Preserve A identity and composition.
- D 媒材：Three-dimensional restrained stylized PC game mesh render; sculpted face/hair clumps, simplified cloth geometry, matte hand-painted diffuse textures, soft stepped lighting/AO, no ink contours, no realistic pores or collectible figurine style. Preserve A identity and composition.

## 下一步交接

Codex 建議先試 A 的角色畫風搭配 2.5D 戰場：Three.js 地形與特效保留，角色拆分肢體／衣帶／劍、配置骨架或多幀動畫，落地陰影與遮擋需實機驗證。這只是建議，使用者尚未選定。C 的深度感來自生成畫面，不代表已實作視差或即時燈光。

待選定後先製作一名角色戰鬥样本：滿藥品格、多件遺物、滿手牌、桌面與手機橫向、idle/attack/hit 都需查看。未選定前不批次重製其他角色，不替換正式模型。

# SwordCard 3D 戰鬥呈現

## 正式戰鬥：3D 戰場層（2026-10-02 起取代 2D 立繪，無開關）

使用者選定的架構：**3D 戰場層**——卡牌、藥品、遺物、回合、存檔邏輯完全不動，只把戰場中央的角色改用 3D 呈現。實作在 `scripts/battle_stage_3d.gd`（`BattleStage3D`）。

- **圖層**：`background_rect`（PAL1 手繪背景）→ `BattleStage3D`（3D）→ `root`（血條、意圖、手牌等 2D UI）。`_build_battle_scene()` 建立，`_clear_root()` 在淡出截圖後釋放，所以只在戰鬥畫面存在。
- **站位仍由 2D 版面決定**：`main.gd` 照舊建立每個肖像 TextureRect，再用 `_stage_track(key, portrait, character_id, pose, floats)` 交給 3D 層（key：`player`、`bench_<i>`、`enemy_<i>`）。3D 層每幀把肖像框投影到 3D 地面：腳底＝wrap 底邊中央。2D 肖像只設 `self_modulate.a = 0` 不畫，版面、點擊、拖牌瞄準照常；shake / dash / flash / 淡出 / 陣亡變暗等 tween 都作用在 2D wrap 上，3D 層每幀讀位置與 modulate 鏡像過去。
- **有模型的角色**（`BattleStage3D.CHARACTER_MODELS`）：3D 模型站在腳底點，身高對齊 2D 框高，套 `pose_targets()` 六姿勢（跟著 `_get_active_player_pose()`：出牌→攻擊／施法、護體→擋格、HP≤25%→命危、倒下）。目前只有李逍遙（`li_xiaoyao_blockout.glb`，面向 60°）。
- **其他角色與敵人**：原立繪做成面向鏡頭的 Sprite3D，投影後與 2D 框完全重合（換姿勢、Boss 變身換圖都直接讀肖像當下的 texture）。另用 alpha-cut 的同圖只負責投影。
- **地面與光**：地面是只收陰影的透明面（自訂 shader，見 CLAUDE.md 地雷），背景仍是手繪圖。主光從鏡頭左前上方打、影子往右後方落；不能往鏡頭方向落（會藏在血條後面），也不能純側光（立繪板子的影子會縮成一條線）。補光用 cull mask 避開地面層。
- **解析度**：SubViewport 以實體像素渲染（`get_final_transform()` 的縮放），canvas_items 放大的視窗與手機上不會比 2D 糊；輸出是 premultiplied alpha，TextureRect 用 `BLEND_MODE_PREMULT_ALPHA`。
- **新增角色模型**：GLB 放 `assets/models/`，原點在腳底、面向 +Z、手臂節點命名 `LeftArmPivot` / `RightArmPivot`（沒有也能用，只是手臂不動），再在 `CHARACTER_MODELS` 加一筆 `{"path", "yaw"}`。
- **驗證**：smoke `_test_battle_stage_3d`（模型/立繪切換、2D 隱藏、投影互逆、肖像釋放）；畫面用 `godot --path . -s render_battle_ui.gd`。

已知限制：李逍遙草模是低面數造型驗證，與其他角色的手繪立繪風格不一致；Android 實機效能尚未驗證。`assets/models/candidates/`（約 38 MB 的 TripoSR 候選 GLB／貼圖）已加 `.gdignore`（2026-10-02），不匯入、不進 APK；`character_3d_candidate.gd` 改在執行期用 `GLTFDocument` 直接讀原檔，候選檢視場景仍可在開發環境使用。候選要轉正時，把 GLB 搬到 `assets/models/` 再登記。

## 姿勢檢視原型

主選單有「3D 試作」按鈕（獨立場景，不讀寫存檔），姿勢數值與正式戰鬥共用 `BattleStage3D.pose_targets()`。也可直接開啟：

```powershell
godot --path . res://scenes/battle_3d_prototype.tscn
```

畫面含真正的 3D 地面、可旋轉鏡頭、燈光、訓練木樁與李逍遙模型；按下方按鈕可檢查六種戰鬥姿勢。木樁只用於尺度測試，不代表原作敵人。場景不讀寫存檔。

六姿勢的實機截圖存放在 `docs/3d_previews/`。這些圖由 Godot 4.6 的 mobile renderer 輸出，用於草模驗收，並非正式戰鬥 UI 的驗收圖。

李逍遙模型目前是低面數造型草模，用來確認人物尺度、朝向、招式姿勢與 Godot 的 GLB 流程；臉部、衣褶、骨架動畫與材質尚未達到正式美術品質。衣著參考 [大宇 Steam 頁面的原版戰鬥截圖](https://store.steampowered.com/app/1546570/Sword_and_Fairy/)：淺色短上衣、深色下裝、黑色束髮、樸素佩劍。先前棕袍 2D 候選在這些項目上不準確，不作 3D 母版。

模型來源檔：`source_art/3d/li_xiaoyao_blockout.blend`。此目錄用 `.gdignore` 排除 Godot 匯入，讓 CI 與 Android 建置不用安裝 Blender；遊戲載入的是 `assets/models/li_xiaoyao_blockout.glb`。可用 `tools/blender/build_li_xiaoyao_blockout.py` 重新產生兩者。

正式戰鬥中央區域已接上 3D 戰場層（見上方）。接下來角色與敵人需逐一完成原作圖參照、骨架、六姿勢、手機效能與滿 UI 實機驗收，再登記進 `CHARACTER_MODELS`。

## 後續動畫工具候選：UniMate

[UniMate](https://github.com/Friedrich-M/UniMate) 是依文字描述為已有骨架的 3D 模型產生、編輯動作的研究專案。等角色造型與骨架完成後，可試作待命、攻擊、格擋等戰鬥動畫，並檢查動勢是否符合 PAL1 原作；確認品質與授權後再評估匯入 Godot。它不負責角色建模或綁骨架。目前僅列為後續試驗工具，尚未整合進 SwordCard。

## AI 建模工具評估（2026-10-01）

目前的 Blender 李逍遙模型是尺度與流程草模，正式角色可改試 AI 生成候選，再用 Blender 修整、匯入 Godot 驗收。尚未以相同參考圖實測兩家，因此沒有畫質勝負結論。

| 工具 | 目前可用流程 | 對本專案的注意事項 |
|---|---|---|
| [Tripo](https://www.tripo3d.ai/help/features/how-to-use-the-image-to-3d-feature) | 圖片／多視角生成、貼圖、[自動綁骨架](https://www.tripo3d.ai/help/features/can-tripo-create-animation-ready-3d-models)、匯出 GLB／FBX | [建議角色用 T/A pose 與多視角](https://www.tripo3d.ai/help/features/how-to-get-better-image-to-3d-results)；免費方案的模型公開、限非商用，匯出有額度／版本限制，詳見[當期方案](https://www.tripo3d.ai/pricing)。 |
| [Meshy](https://help.meshy.ai/en/articles/9996860-how-to-use-meshy-image-to-3d) | 圖片／[多視角](https://help.meshy.ai/en/articles/12634481-how-to-use-multi-view)生成、Smart Topology、Auto Split、T/A pose、[自動綁骨架與動作庫](https://help.meshy.ai/en/articles/16231707-how-to-create-3d-animation-with-auto-rigging)、匯出 GLB／FBX | 多視角與模型下載目前需付費方案；其 Smart Rig 對非標準角色仍在測試，且目前不能套用動作庫。詳見[當期方案](https://help.meshy.ai/en/articles/12062933-which-meshy-plan-is-right-for-you-free-vs-pro-vs-premium-vs-ultra)。 |

試作時以**同一套已確認的 PAL1 角色正面、側面、背面參考**製作兩家候選；先檢查原作輪廓、衣著、髮型、兵器與較成熟的年齡感，再檢查背面／手指／衣襬、骨架變形、貼圖、面數及手機上的 Godot 實機效果。單張原作戰鬥圖看不到的部分屬推測，需人工校正。候選模型另存，不直接覆蓋草模或正式資產。平台授權不等於取得仙劍角色的使用權，發佈前須另行確認素材權利；[Tripo](https://www.tripo3d.ai/help/privacy-policy/how-to-use-tripo-models-commercially) 與 [Meshy](https://help.meshy.ai/en/articles/9992001-can-i-use-meshy-assets-commercially-license-copyright-explained) 的方案條款也應以產生時版本為準。

### 李逍遙聯動造型候選

[使用者分享連結](https://share.google/XVeLoCvFF8O0UnLCi) 指向[《王者榮耀》曜的李逍遙聯動皮膚圖](https://tw.win3000.com/pic/1721.html)。使用者已確認第一個精緻 3D 候選以此圖的聯動版服裝為主。可辨識黑色高馬尾、棕金披肩、深色短外衣、白色寬褲與華麗長劍；它比 PAL1 原版戰鬥截圖的淺色短上衣、深色褲靴、樸素佩劍更繁複，應標作聯動造型候選，不混充原版。

已由該圖製作乾淨背景、無持劍遮擋的站姿輸入圖：`source_art/3d/candidates/li_xiaoyao_crossover_a_pose_v1.png`。原圖先直接測試圖生 3D；如手臂與衣物黏連，再測站姿圖。兩者均為候選，不替換既有草模。

站姿圖使用內建 imagegen，以使用者提供圖作參考。生成指令：

> Create one full-body front view of the same adult Chinese fantasy swordsman (about 25–28) in a symmetrical A-pose for image-to-3D modeling. Preserve the long black high ponytail, golden-brown shoulder wrap, dark brown short tunic, off-white sleeves and trousers, brown sash and boots, and blue inner accent. Refined sculpted 3D game character appearance with realistic fabric folds. Remove the sword from his hand to expose arm geometry. Transparent background, even studio lighting, no extra armor, props, pedestal, text or logo.

### 第一輪實際 3D 候選（2026-10-01）

已用[官方開源 TripoSR](https://github.com/VAST-AI-Research/TripoSR)在本機對上述站姿圖重建。全身單圖模型的五官太糊，因此又由同一參考生成頭頸特寫 `source_art/3d/candidates/li_xiaoyao_crossover_head_v1.png` 單獨重建，再裁去全身模型模糊的上半頭，與較清楚的頭部合成。金色劍格、藍寶石、銀色劍刃另外參照使用者圖製作成可分離的 3D 配件。各輪原始與中間 GLB 均保留在 `assets/models/candidates/`；**正式戰鬥仍使用舊草模，未被覆蓋**。

目前最完整的靜態候選：`assets/models/candidates/li_xiaoyao_crossover_composite_with_sword_v2.glb`（約 8 MB，頭、身與劍分件包含在同一 GLB）。可在 Godot 開啟 `scenes/character_3d_candidate.tscn`，用按鈕查看四面或拖曳旋轉；實機截圖在 `docs/3d_previews/candidate_li_xiaoyao_crossover_v7_sword/`。截圖由 Godot 4.6 mobile renderer 輸出，不是 2D 概念圖。`tools/blender/trim_li_xiaoyao_triposr_body.py` 與 `tools/blender/assemble_li_xiaoyao_candidate.py` 記錄裁切、組合步驟。

**品質判斷：可作造型／比例討論，不可當正式角色。** 對照使用者的聯動圖，黑色高馬尾、棕金披肩、深褐外衣、白袖白褲與向下持劍大致可辨；但臉部仍不如原參考精細，側面髮尾與披肩接縫僵硬，背面多數是單圖模型推測，劍格只是簡化重建。GLB 目前約 16.2 萬頂點、20.6 萬面，未減面、未綁骨架，不能做待命／攻擊／格擋動畫；Android 效能也尚未驗證。頭與身雖同封裝在 GLB，幾何並未焊接，頸部需要正式修模。正式替換前仍需更好的多視角建模、人工修臉／背面、重拓樸、骨架與完整戰鬥 UI（藥品滿格、多件遺物）驗收。

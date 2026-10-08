# SwordCard 共用任務分派清單 — Codex × Claude Code

> 2026-10-06 CHARACTER-004–006（Codex，本輪四人製作／本地接入 4/4，100%）：依最新授權先生成 2D，再與 DOS 原作比對身份特徵，主觀評估靈兒 94%、月如 94%、阿奴 95%、巫后 93%，不是量測相似度。月如首版高髻已撤回，改低束髮／肩側髮束後重建 v4；其他三人 v3。四人真正動畫 GLB、六方向與 60 動畫影格、四張 production 桌機／手機滿 UI 驗證通過，119 tests passed／1 skipped、build 通過。主角 STYLE D 已 5/5；未發布線上，使用者美術與實體手機待驗收，guard/cast 仍另案。詳見 [四角色重製](docs/FOUR_CHARACTERS_STYLE_D.md)。

> PORTRAIT-001（Codex，首批 5 名製作／接入／發布完成 100%，全角色底圖 5/23 約 22%）：依實際查看／展示的 DOS 原作對話頭像校正逍遙／靈兒／月如／阿奴／酒劍仙，正式 canon-v1 新圖與 StoryPortraits 接入，build 通過、正式劇情桌機／手機尺寸驗收。原私人網址部署 appgdep_6ac3b330e3ac8191af832895a2b8aee0 succeeded，Sites SHA acf65af1bb278789c9629ef16261b055d860b656。新表情未完成時共用校正底圖，不回退舊錯誤造型；其他 18 人及表情仍待重製，詳見 [劇情角色校正](docs/STORY_PORTRAIT_REVIEW.md)，使用者美術待試玩細調。

> STORY-001（Codex，修正／驗證／發布完成 100%）：劇情旁白固定寬度、靠左；角色台詞明確靠左，未顯示字保留整句排版，逐字時不移位。build 通過；844×390 旁白與 1280×720 台詞部分／完整顯示位置尺寸一致，證據见 [劇情文字排版](docs/STORY_TEXT_LAYOUT.md)。原私人網址部署 appgdep_6ac3ab5ffb848191a8904e2b35f736b0 succeeded，Sites SHA 2b73b6896a7ab422ef9fa0c1ff32d7b3e3c89147。未改劇本、字速與選項規則。

> VISUAL-001（Codex，評估完成 100%，優化尚未實作）：已實際試玩正式網址空第 3 欄，三回合通過仙靈島首戰（67/72 HP），包含劍招／護身／土靈符／受擊／擊殺，比較桌機 1280×720 與手機橫向 844×390。結論：先修閱讀／裁切與交戰構圖，統一 D 正常比例美術，再做命中與 guard/cast 動作。詳見 [戰鬥視覺評估](docs/BATTLE_VISUAL_REVIEW.md) 及版本化線上截圖。VISUAL-002–004 的首批版面／站位／接觸效果已實作，完整角色美術與動畫仍待完成；VISUAL-005–006 仍為待開始計畫，分工與驗收列於評估；未改正式程式、資產或部署，保留其他存檔及他人改動。

> CHARACTER-009（Codex，李逍遙備戰姿勢製作／上線 100%，使用者美術待驗收）：idle 改屈膝錯步、重心下沉、右手持劍／左手戒備，attack/hit 首尾回 ready；修正 NLA 匯出造成重複下沉。正式 `li_xiaoyao_style_d_ready_v2.glb`，六方向＋十五影格／grounded ankles／首尾關節銜接通過；四張正式桌機／手機橫向滿 UI 0 errors。build、117 tests passed（1 skipped）。原網址部署 appgdep_6ac3a30700848191aed10c6ba9103466 succeeded，Sites SHA 72df966f3df409cf8f0bdd5f99fb34ce687e4607。詳見 [備戰交付](docs/LI_COMBAT_READY.md)。其他四名模型與備戰動作仍待重製，未宣稱全隊完成。

> CHARACTER-008（Codex，李逍遙製作與上線 100%，使用者實機美術待驗收）：使用者已選 D，正常比例真 3D 李逍遙已接入 `li_xiaoyao_style_d_v4.glb`。14,194 triangles／20 bones／idle-attack-hit；建置與 117 測試通過（1 跳過），六方向＋八動作影格、四張正式桌機／手機全 UI 戰場 0 errors。原私人網址部署 appgdep_6ac39e3f61108191a0bd8d8cddb7997a succeeded，來源 SHA 354f56966f98bf389fa248230d1a166666be983b。主角群 D 重製 1/5（20%），其餘四人待 CHARACTER-004。詳見 [交付](docs/LI_STYLE_D_3D.md)。CHARACTER-007 選風格完成 100%，2.5D 僅為歷史比較。

> 最新方向（2026-10-05）：使用者提出先採 2.5D，並要求多種 2D／3D 李逍遙參考。CHARACTER-007 由 Codex 完成候選圖片 4/4（100%，待使用者選風格），詳見 [比較與交接](docs/LI_STYLE_COMPARISON.md)。本輪僅產生外觀圖片，C 未分層／綁定，D 未建立 GLB；正式遊戲未替換或部署。原先「禁止 2D 站牌」不應阻止這次已授權的 2.5D 試作，但全專案渲染方式尚未定案。絕對禁止 Q 版繼續有效。下一步由 Codex 依使用者選擇製作小型戰鬥實機樣本，再決定其餘主角。

> 專案：**Xiaoyao／逍遙，Three.js 網頁版**，不是舊 SwordCard 的 Godot 版。
> 更新日期：2026-10-05（Asia/Taipei，Codex 完成血池正式 3D 接入、89 個通過測試，私人手機 HTTPS 部署成功；保留 Claude 的任務紀錄）。
> 最新最高優先美術限制：使用者明確拒絕 Q 版，最討厭 Q 版。禁止大頭短身、短腿、幼齡大眼。doll_v2/v3 全部為被拒候選，未發布、不得整合；主角仍需正常比例與原作造型重製。
> 最新角色回饋：CHARACTER-002 復核完成 100%，使用者未通過本批主角美術；CHARACTER-001 的 5/5 僅為技術交付。CHARACTER-003–006 待重製，不沿用「視覺已通過」判定。詳見 [造型復核](docs/CHARACTER_STYLE_REVIEW.md)。
> 最新片頭修正：MENU-002 完成 100%，手機直向鏡頭與霧距離同步，葫蘆／竹簡／劍恢復可見；117 測試通過（1 跳過）、四尺寸＋轉向驗收錯誤 0，原網址發布 succeeded。實體手機由使用者重開確認。
> 最新操作評估：FEEL-001 完成 100%（評估交付，實作尚未開始）。桌機／手機觸控模擬皆重現未預選拖曳失敗與單一目標兩次點擊不出牌；36 項方案與驗收見 [docs/CARD_FEEL_REVIEW.md](docs/CARD_FEEL_REVIEW.md)。FEEL-002–005 待認領，正式版本未變更。
> 最新手機更新：MOBILE-001 橫向入口完成 100%，支援的手機點開始／橫向按鈕後嘗試 fullscreen → landscape lock；拒絕或不支援則顯示手動轉向，桌面不受影響。原網址部署 appgdep_6ac37f07e9908191870104b2c103fe32 succeeded。
> 前次角色交付：2026-10-05 CHARACTER-001 完成 100%，5/5 角色模型（新增月如／阿奴／巫后）；RELEASE-001 正式入口整合，建置與 112 測試通過，原私人網址部署 appgdep_6ac36ee9b5088191a9f7824b229bd6c1 succeeded。場景 23/23 完成；第一版完整九章可供試玩。實體手機與使用者美術細調尚未驗收，詳見 docs/CHARACTERS_3D.md。
> 前次場景交付：2026-10-05 Codex 完成 SCENE-003：23/23（100%）Three.js 場景實作與接入；112 測試通過（1 跳過）、46 張舞台／44 張正式戰鬥 QA、GPU 切換及手機存檔流程通過。原私人手機網址已更新（deployment appgdep_6ac3643c6c9c819188cdfb2ffa12e725 succeeded）。美術相似度為視覺判斷，使用者完成後試玩細調；不冒稱整個專案或實體 Android 驗收 100%。
> **兩邊每次開工先讀本檔，認領後再改程式；完成或交接時更新自己的任務。**

本檔負責「誰做什麼、改哪些檔案、下一步與交接」。[docs/PROGRESS.md](docs/PROGRESS.md) 保留整體里程碑；產品規則參考 [設計聖經](../SwordCard/docs/REDESIGN.md)，最新使用者指示優先。

## 主從分工（2026-10-04 使用者指示：「以 Claude Code 為主，Codex 為輔」）

- **Claude Code（主）**：遊戲規則、行程、九章內容與劇本、所有正式畫面、音訊、需要和角色造型一致的 2D 美術（卡圖、敵人立繪、頭像）、平衡、最終整合與驗收。範圍與優先順序由 Claude Code 決定，衝突時以 Claude Code 的決定為準（使用者指示優先於兩者）。
- **Codex（輔）**：3D 與場景美術——可操作角色的 3D 模型、各章戰場（俯視地面圖＋3D 加工）、劇情背景與章節地圖圖、起始選單。交付物必須符合下方「交付規格」，由 Claude Code 整合。
- **出圖工具**（2026-10-05 使用者指示）：兩邊都可以用本機 ComfyUI 或 Codex 自己的生圖工具。本機只有一張 GPU，ComfyUI（`127.0.0.1:8188`）是共用佇列：直接把工作送進同一個服務，**不要另開第二個 ComfyUI，也不要停掉別人的批次**。
- **不互相卡住**：Codex 的交付物都有後備方案（3D 模型未到前用 2D 立繪；場景圖未到前用十里坡）。Codex 交付後替換後備即可，不需要改程式。

## CLI 派工授權（2026-10-05）

使用者授權 Codex 直接呼叫本機 Claude Code CLI 分擔工作，優先讓 Claude 執行可獨立開發與 QA，Codex 做任務協調、驗收、部署。仍使用本檔作唯一分派入口；每次回報附完成度百分比。不得同時讓兩個程序改同一認領範圍。最新指示：CLI 登入無法完成時先跳過，不重複派工；Codex 先自行執行，之後可用時再交接。

## 協作方式

1. **認領**：把任務負責人填成 Codex 或 Claude Code，狀態改成「進行中」，填實際修改範圍與下一步。表內「建議」不是已認領；「依提交紀錄」不代表對方目前仍在工作。
2. **先查現況**：讀進度文件、跑 `git status --short`，確認別人的未提交改動。不要刪除、還原或覆蓋來源不明的檔案。
3. **避免同檔衝突**：已有「進行中」任務涵蓋的檔案，由該負責人修改。要碰共用入口或樣式，先在「共享檔案與交接」寫清楚接手範圍；無法確認時先做不衝突的部分，留交接事項。
4. **保持進度準確**：完成一段、改變範圍、遇到阻礙或結束工作前，更新任務狀態、驗證結果、下一步。不能把「已有檔案」直接當成「完成驗收」。不要代替對方宣告開始或完成。
5. **完成條件**：程式可建置、相關測試通過，涉及畫面要有實際截圖；需要使用者視覺驗收的美術標成「待驗收」。提交時只 stage 自己確認過的改動，不用 `git add .` 或 `git add -A` 混入對方工作。
6. **持續更新（使用者再次要求，2026-10-05）**：每次開工、階段完成、負責人／範圍／阻礙變更與交付前，先重讀最新清單並更新自己的項目；列完成度百分比、驗證證據、下一步與交接。最新回饋摘要同步更新，保留對方紀錄。不把「已分派」寫成「已執行」，也不等使用者提醒才更新。
7. **單一任務入口**：新工作追加到本檔，使用固定 ID；不要再另建一份競爭的分派表。完成記錄保留。任務清單是協作約定，不是檔案鎖或自動訊息系統。

狀態：**待認領 → 進行中 → 待整合／待驗收 → 完成**；真正無法前進時用「受阻」，寫明原因與解法。

## 任務表

| ID | 任務 | 負責人 | 狀態 | 修改範圍 | 下一步／完成條件 |
|---|---|---|---|---|---|
| COORD-001 | 共用任務表與兩個代理的入口規則 | Codex | 完成 | `TASKS.md`、`AGENTS.md`、`CLAUDE.md`、`docs/PROGRESS.md` | 後續兩邊開工時認領並更新；不靠各自聊天記憶判斷工作歸屬 |
| MENU-001 | DOS 原作構圖的 3D 起始選單 | Codex | 待驗收（實作與技術驗證完成） | `src/menu/`、`src/App.tsx`、`src/BattlePrototype.tsx`、`src/styles.css`、`src/stage/BattleStage.tsx`、`tests/menu/`、`tools/stage/capture-title.mjs` | 等使用者視覺回饋；本輪補提交選單依賴與重新截取完整畫面。正式遊戲串接時保留這個選單，不另做平面標題頁 |
| CORE-001 | 正式戰鬥核心：五靈、連鎖、破勢、合擊、心念、意圖、求生戰 | Claude Code | 完成（`c86dad2`；Boss 接續 `309e867`；卡面文字修訂 `f6bf595`） | `src/core/battle/`、`src/core/types.ts`、`src/core/describe.ts`、`tests/core/` | 正式戰鬥畫面已全面改用核心；之後只做平衡 |
| RUN-001 | 章節、劇情、戰鬥結算、選牌、客棧、入離隊、HP 與存檔流程 | Claude Code | 完成（`08f87fb`；旗標分支、後期入隊 HP、章節題詞 `309e867`、`6a85f9c`） | `src/core/run/`、`src/platform/save.ts`、`tests/core/` | bot 用真實九章資料從序章打到結局（`tests/bot`）；存檔可匯出／匯入（`7c38310`） |
| CONTENT-001 | 九章角色、牌、敵人、Boss、節點與劇本資料 | Claude Code | 完成（2026-10-05，`2bccafb`、`309e867`） | `src/content/`、`tests/content/` | 九章劇本、約 90 種正史敵人、章節節點與經濟、`docs/ART_LIST.md`；`tests/content` 檢查所有參照、每章走得完。之後只做平衡與文字修訂 |
| UI-001 | 正式遊戲畫面與核心串接 | Claude Code | 待整合（畫面全部完成：地圖、劇情、戰鬥、獎勵、客棧、戰敗、標題卡、結局、存檔欄、設定；`99162be` 起多次提交。`tools/playthrough.mjs` 真瀏覽器試玩 0 錯誤。**只剩 `src/App.tsx` 未提交**：它 import MENU-001 尚未提交的 `src/menu/`，等 Codex 提交選單後一起提交） | `src/ui/`、`src/game/`、`src/platform/`；`src/App.tsx` 只改「新的故事／舊的回憶」回呼與開發用 `?dev` | 保留 MENU-001 的 3D 起始選單；保留 `?stress`／`?perf`（2026-10-05 實測 stress 54 fps、0 錯誤） |
| UI-002 | 戰鬥疊層改用 DOM、手機橫向版面、長按預覽、Android 返回鍵、劇情提示 | Claude Code | 完成（`6ff3b49`、`a1d8f6d`、`b04a1ae`、`60ddfac`） | `src/ui/`、`src/stage/BattleStage.tsx`（只加可選欄位 `htmlOverlays`／`anchorsRef`） | drei Html 在敵人倒下、戰鬥結束時同步卸載會噴 React 錯誤（試玩 50 筆），正式戰鬥改用 Canvas 外的 DOM 疊層後 0 筆；原型的 Html 行為不變 |
| UI-003 | 設定：主角呈現 3D 模型／2D 立繪 | Claude Code | 待使用者決定預設值（`95eef64`；預設 3D） | `src/game/settings.ts`、`src/ui/battle/BattleScreen.tsx` | 2D 立繪與卡圖同畫風、面向敵人看得到臉；3D 模型從背後看偏暗。比較圖：`capture_out/party_style_compare.jpg` |
| FONT-001 | 自帶字型（離線可用） | Claude Code | 完成（`6ff3b49`） | `tools/fonts.mjs`、`tools/subset_fonts.py`、`public/fonts/`、`src/fonts.css`、`index.html` | 只取遊戲用到的 1861 個字（7.9 MB → 1.7 MB），不再連 Google Fonts。**劇本或介面文字改了要跑 `npm run fonts`** |
| DEV-001 | 開發工具：`?dev=<章>[:節點]` 跳關、試玩截圖工具 | Claude Code | 完成（`cadcbaa`） | `src/game/devJump.ts`、`tools/playthrough.mjs` | 例：`node tools/playthrough.mjs capture_out/x 6 1280x720 dev=6:c6_dragons`；只在 dev server 有效，正式建置移除 |
| ART-001 | 2D 美術：卡圖（111 張）、角色戰鬥立繪、敵人立繪（91）、劇情頭像（48） | Claude Code | 待使用者視覺驗收（2026-10-05 全部完成：卡圖第二版場景分散到仙劍各地 `f37bd7f`、敵人立繪 91、頭像 48（主角六表情同一張臉）） | `tools/art/`、`public/assets/cards|enemies|portraits|characters/*_standee.png` | 批次原圖不入庫（`source_art/` 忽略，可依提示詞＋固定種子重跑）。**提示詞地雷**：「Black Miao」會被畫成黑貓頭或黑皮膚，一律寫成「Miao (Hmong) ethnic minority … East Asian features, black indigo-dyed clothing」（`6e13549`）；STYLE 的「card illustration」偶爾讓模型自己畫卡框，換種子或用 `publish.crop` 裁掉 |
| ART-002 | 劇情背景與章節地圖圖 | Claude Code 出第一版；Codex 可精修 | 待使用者視覺驗收（2026-10-05 第一版完成並提交 `5e40ebb`、`e1f73f8`：40 張背景＋9 張絹本地圖，`tools/art/make_assets.py` 的 STORY／MAPS。Codex 若要依 PAL1 原作參照重畫，直接覆蓋同路徑的圖即可，不用改程式。清單：[docs/ART_LIST.md](docs/ART_LIST.md)） | `source_art/story|maps/`、`public/assets/story|maps/`；若用本機管線，另開自己的 `tools/art/prompts/codex_*.json` | 規格見「交付規格 C」。生圖工具不限（ComfyUI 或 Codex 生圖） |
| BALANCE-001 | 自動通關 bot、最差牌組可通關、經濟曲線 | Claude Code | 待使用者試玩回饋（第一輪調整 `99162be`；8 個種子 × 普通／最差牌組 16 局全部通關，最差牌組共只輸 1 場 `a5a56e7`） | `tests/bot/`、`src/content/` 數值 | 目前偏好過，標準難度要不要加難等使用者試玩後決定；`BOT_SEEDS=8 npx vitest run tests/bot/seeds.test.ts` 重跑 |
| SCENE-001 | 各章完整 3D 戰場 | Codex（Claude 先前交付地面第一版） | 完成 100% 技術交付：SCENE-003 | `public/assets/battle/` 保留相容後備；`src/stage/scenes/` | 完整 3D 23/23（100%），正式預設無投影 JPG；各場核對 DOS 圖、地面／立體道具／材質、預算與正式畫面驗收。使用者試玩後再細調，見 docs/ALL_SCENES_3D.md。 |
| SCENE-001A | 戰場 sceneId 介面、資產回退與場景效能預算檢查 | Codex | 完成（2026-10-05，Claude 已接入正式舞台，Codex 重驗通過） | `src/stage/scenes/`、`tests/stage/scenes.test.ts`、`tools/stage/`；`BattleStage.tsx` 只加可選 sceneId／scenery 參數 | BattleScreen 傳入章節 ground；23 ready／0 pending，完整建置通過，74 個測試通過／1 跳過。逐場 3D 美術另屬 SCENE-001 |
| SCENE-001B | 血池 Boss 戰場原作參照與首批 3D 加工 | Codex | 完成 100%，使用者已驗收 | `src/stage/scenes/`、場景 QA／文件 | 首批技術交付後，Boss、旋流皆已確認；SCENE-001D 完成 production 自動接入。最新說明 docs/BLOOD_POOL_3D.md |
| ART-001B | 赤鬼王原作造型修正 | Codex | 完成 100%：使用者確認「這版可以」，正式接入已驗證（2026-10-05） | `public/assets/enemies/red_ghost_king.webp`、候選／造型文件、`src/stage/artCandidates.ts`、BattleStage 呈現接線；`make_assets.py`／`prompts/assets.json` 僅赤鬼王條目 | 正式圖與 DOS v2 候選 SHA256 相同；production 使用高度 1.9／意圖偏移 -1.5，明確自訂資產與偏移仍優先。正式建置瀏覽器治療與對 Boss 出牌通過，錯誤 0；生成描述已修正，歷史候選保留 |
| SCENE-001C | 血池旋渦流體修正＋已確認 Boss 正式接入 | Codex | 完成 100%（2026-10-05，使用者回覆 ok） | `src/stage/scenes/bloodPool*.ts`、正式赤鬼王呈現／生成描述、`src/styles.css` 僅候選姓名描邊、`tools/stage/capture-blood-vortex.mjs`、相關測試／文件／截圖 | 以金白填滿的流體取代等距黃環；差速捲流、周邊血水流動、碎浪、連續網面起伏。9 draw／15,178 面，建置／89 測試通過（1 跳過）。桌機／手機／省電與三藥品＋六法寶 QA、正式建置 Boss QA 通過，錯誤 0。動畫／驗證：docs/BLOOD_VORTEX.md；新版已確認，SCENE-001D 正式接入完成 |
| SCENE-001D | 已確認血池 3D 正式啟用 | Codex | 完成 100%（2026-10-05） | `src/stage/scenes/` 正式場景查表／R3F 入口、`BattleStage.tsx` 地面接線、`src/styles.css` 既有姓名描邊選擇器、相關 QA／文件 | 正式 sceneId 自動選取完整 3D 血池，移除舊背景載入；保留明確自訂參數優先。production 桌機／手機觸控／省電測試通過：三藥品、六遺物、八張手牌、治療／出牌／長按預覽，0 錯誤、0 HUD 超界、0 舊血池 JPG 請求。89 測試通過／1 跳過。docs/previews/blood-release/validation.json |
| SCENE-002 | 鎖妖塔 Boss 戰場原作參照與 3D 加工 | Codex | 完成 100% 技術交付（併入 SCENE-003） | `docs/art-references/tower.md`、`palSceneRecipes.ts`／`palSurface.ts` | 明王與神龍均使用 DOS 暗紅橫紋全地面，沒有屋頂／天空或把探索劍柱搬進戰鬥。桌機／手機正式畫面通過；最新自主授權已取代逐張詢問。 |
| CHARACTER-001 | 林月如、阿奴、巫后的 3D 模型（人形 Boss 為可選升級） | Codex | 完成 100%（模型實作／技術交付）：5/5 可操作角色已具 GLB；三位新增模型六視角／24 動畫幀／4 正式戰鬥畫面通過，112 測試／手機流程通過，私人網址更新 succeeded。使用者試玩細調另列 | `source_art/characters/<id>/`、`public/assets/characters/<id>.glb` | 規格見「交付規格 A」。管線已有：`tools/blender/build_character.py`＋`rig.json`。未交付前遊戲用 2D 立繪後備 |
| AUDIO-001 | WebAudio 配樂與音效 | Claude Code | 完成（`3e42138`） | `src/platform/audio.ts`、`music.ts`、`synth.ts` | 五聲音階程序化作曲 14 首＋音效；第一次互動解鎖、背景暫停、音量接設定；`tests/platform` 檢查曲目都存在 |
| QA-001 | 全流程、平衡、Android 打包與實機驗收 | 共同（待認領具體子任務） | 待認領 | `tests/`、`tools/`、打包設定 | 核心通關 bot、介面流程測試、參考手機實測；瀏覽器尺寸檢查不等於 Android 效能驗收 |
| QA-001a | Android 打包（Capacitor）與 APK | Claude Code | 待驗收（2026-10-05：`npm run android:build` 產出含全部美術的 debug APK **41.7 MB**（去背圖改 WebP、建置前刪舊 APK 避免增量打包廢空間）；橫向、沉浸式全螢幕、返回鍵、自帶字型。缺參考手機實測） | `capacitor.config.ts`、`android/`（新）、`package.json` 只加 Capacitor 相關依賴與腳本 | 產出 debug APK；本機已有 Android SDK 與 Android Studio。實機驗收要使用者提供參考手機 |
| QA-002 | 手機可直接遊玩的網址／私人 HTTPS 部署 | Codex | 完成 100%（2026-10-05） | `tools/hosting/`、隔離 `hosting/mobile/` 靜態部署副本、docs/MOBILE_PLAY.md；未改 Claude 的 App／核心 | 私人 HTTPS 部署 succeeded：[手機遊玩](https://xiaoyao-private-play.googoo00166.chatgpt.site)。同一 ChatGPT 帳號登入，外出可玩、電腦可關機。建置／89 測試通過，桌機／手機觸控／省電 QA 通過；實體 Android 尚未測試。存檔各裝置獨立，可匯出／匯入。 |

| QA-003 | 手機正式流程／存檔搬移 QA 與修復 | Codex（使用者指示先跳過 Claude） | 完成 100%：驗證及網址更新成功 | `tools/qa/mobile-flow.mjs`、`docs/previews/mobile-flow/`、手機 QA 文件；必要 UI／game／platform 修復先交接 | Claude CLI OAuth 過期，未執行；桌面派工草稿已取消、未送出。Codex 接手 touch 新故事→劇情→地圖→戰鬥→重載續玩、匯出／乾淨 context 匯入；保留 Claude 既有未提交工作；新機匯入入口修復及 9 項驗證通過，build／89 測試通過（1 跳過）；原私人網址修正版 deployment succeeded，靜態源 af638ce5。 |

| QA-004 | 3D 舞台切換／隱藏／資源釋放回歸驗收 | Codex | 完成 100% | `src/stage/FpsMeter.tsx` 診斷欄位、`tools/stage/lifecycle-*`、場景資產盤點輸出、QA 文件／截圖 | 同一 Canvas 在血池與十里坡間反覆切換，14 次 StrictMode 場景往返通過，暖機後 geometry／texture／program 數穩定；隱藏停止渲染、恢復與高／低畫質正常，0 瀏覽器錯誤；build／89 測試通過（1 跳過）。資產盤點明列 23 張圖片與 1/23 完整 3D，報告 docs/STAGE_LIFECYCLE_QA.md；不製作未確認的新美術。不碰 Claude 的 App／UI／核心。 |

| SCENE-003 | 全部 22 個剩餘戰場完整 3D、原作核對與正式接入 | Codex | 完成 100% 技術交付／已部署；使用者試玩細調 | `src/stage/scenes/`、BattleStage、BattleScreen 僅敵人高度、場景測試／QA／原作參照／進度文件 | 23 場 3D；112 測試通過（1 跳過）；46 張舞台＋44 張正式戰鬥、0 錯誤／HUD 超界／舊 JPG 請求。每場站位、20 draw／30k 面與清理驗證通過。女媧神殿現有故事節點保留、模組獨立驗收。原同址部署成功。詳見 docs/ALL_SCENES_3D.md；90% 不作量化實測或使用者已驗收聲明。 |

## QA-003 App.tsx 交接

Codex 因使用者要求自行接手手機 QA，在既有 Claude 未提交的正式 GameApp 上只增加 `allowMemoryImport` 與無存檔提示，允許新手機進入匯入頁。其他 Claude 入口內容原樣保留。此兩行獨立差異見 docs/patches/qa003-app.diff；App.tsx 仍由 Claude 的原入口提交一併保存，Codex 不把整份 Claude 未提交工作混入本批 commit。部署的隔離靜態版本包含此實際修復。

## 共享檔案與交接

- SCENE-003 實機發現高敵人頭部超出畫面：Codex 接手 BattleScreen.tsx 的 MAX_ENEMY_HEIGHT 單一常數修正（2.6→1.95），其餘 Claude UI 不修改；正式疊層與舞台共用高度，因此縮放與落點一致。


| 檔案／介面 | 當前交接狀態 | 接手注意事項 |
|---|---|---|
| `src/App.tsx` | 2026-10-05 Claude Code 的正式流程已在工作目錄驗證；最新自主完成授權下 Codex 接手源碼整合提交，保留現有全部入口邏輯與原型 | 一般網址：起始選單 →「新的故事／舊的回憶」→ 存檔欄 → `src/ui/GameRoot.tsx`。`?stress`／`?perf`／`?battle`／`?resume` 走 Codex 原本的原型流程（`PrototypeApp`，原樣保留）。`src/menu/TitleMenu.tsx` 加了可選的 `memoryHint`（正式遊戲改說存檔），預設文字不變 |
| `src/styles.css` | Codex 已新增選單樣式，後續只改自己模組的選擇器 | `.title-*`、`.story-choice`、`.screen-slot` 屬起始選單／切換；不要用全檔覆蓋消掉它們 |
| `src/stage/BattleStage.tsx` | SCENE-001A 已接上正式戰鬥（`src/ui/battle/BattleScreen.tsx` 傳章節的 `ground` 當 sceneId）；Claude Code 另加可選欄位（`99162be`）：`StageActor.overhead`／`badge`／`dropTarget`／`dropActive`、popup 的 `kind`、`quality` | 傳入章節的 sceneId 即可安全回退；保留 active、鏡頭、站位、演出與既有背景參數。隱藏舞台停止 frameloop，Canvas root 保留。接法見 docs/BATTLE_SCENES.md |
| `src/stage/BattleStage.tsx`（SCENE-001B／D） | 血池正式 3D 已確認並啟用（2026-10-05） | sceneId=blood_pool 自動載入 BloodPoolScene；dev 與 production 皆有效，無需 scenery 參數。明確 backdrop／layout／scenery 優先；預設不載入舊 JPG。docs/BLOOD_POOL_3D.md |
| `src/stage/BattleStage.tsx`（ART-001B） | 赤鬼王 DOS v2 已確認、正式接入完成 | 正式赤鬼王 URL 套用 1.9 高度、意圖左移 1.5；明確自訂資產／偏移優先。dev 的 bossArt 參數保留歷史候選選擇；既有鏡頭、站位、actor id 與演出不變 |
| `src/BattlePrototype.tsx` | 仍是演出原型，尚未使用正式戰鬥核心 | 正式 UI 接 core reducer；這支保留為試作／效能測試，不擴充成第二套遊戲規則 |
| `src/menu/prototypeMemory.ts` | 只保存戰鬥原型，不是正式章節存檔 | key：`xiaoyao.prototype-memory.v1`。不得當成正式 run 存檔；整合時另用正式存檔格式並改接選單回呼 |
| `src/stage/scenes/catalog.ts` | Codex 的檔案；Claude Code 只會在 PRESENTATIONS 加第一版地面的登記（每場一行，22 張出完後一次加） | Codex 精修覆蓋圖檔時不用改登記；要改版面（`wallV`）或加 scenery 照 Codex 自己的流程 |
| `index.html`、`src/main.tsx` | Claude Code 改過（`6ff3b49`、`a1d8f6d`）：拿掉 Google Fonts、載入 `src/fonts.css`、安裝 Android 返回鍵 | 新增文字後跑 `npm run fonts`，不要再接回線上字型（App 要離線可用） |
| `package.json` | Claude Code 加了 Capacitor（core、android、app）、`@fontsource/*`（開發用）與 `fonts`／`android:*` 腳本 | Codex 加依賴時一樣只動自己需要的項目 |
| `android/`、`capacitor.config.ts` | Claude Code（QA-001a），appId `tw.fan.xiaoyao` | `npm run android:build` 產出 debug APK；`android/local.properties` 由腳本產生、不入庫 |
| `TASKS.md`、`docs/PROGRESS.md` | 兩邊共用 | 編輯前重讀最新內容，只更新相關區塊；避免拿舊副本覆蓋對方紀錄 |
| `src/stage/BattleStage.tsx`、`tools/art/make_assets.py`／`prompts/assets.json`（SCENE-001C） | Codex 已交付已確認赤鬼王的正式呈現／生成描述，以及旋流候選 | 舞台只把 DOS 高度／意圖偏移套用至正式赤鬼王 URL；美術批次只修赤鬼王；styles.css 僅補候選姓名描邊。保留其他敵人、Claude 的 App／UI／PROGRESS 未提交內容 |
| `src/stage/BattleStage.tsx`、`src/stage/scenes/catalog.ts`（SCENE-001D） | Codex 接手已確認血池的 production 場景查表／完整地面 | 只接已通過原作與美術確認的血池，其他 22 場保持現有背景；明確 backdrop／layout／scenery 優先。不改 Claude 的 App／核心／內容與 UI |

## 給 Codex 的下一步（Claude Code 排定，2026-10-05）

依優先順序；做之前照慣例在任務表認領。

1. **提交 MENU-001**（`src/menu/`、`src/BattlePrototype.tsx`、`tests/menu/`、`docs/TITLE_MENU.md`、`docs/previews/`、`AGENTS.md`、本檔）。Claude Code 的 `src/App.tsx` 依賴 `src/menu/`，你提交後 Claude Code 才能提交 App.tsx；否則 HEAD 的正式入口還是舊原型。
   - Codex 2026-10-05 已核對並補提交選單、原型、樣式與本共用任務表。建置與 74 個測試通過（1 跳過）；重新截取完整桌機／手機選單，瀏覽器錯誤 0。入口試玩可進序章、地圖與劇情，瀏覽器錯誤 0（`capture_out/codex-status-check/log.json`）。`src/App.tsx` 保留由 Claude 提交，現在可接手提交；Codex 不混入正式入口改動。
2. **SCENE-001 精修**：22 場地面第一版已由 Claude Code 出完並登記（`44b2602`，提示詞在 `tools/art/make_assets.py` 的 BATTLE）。請依 PAL1 原作參照挑出最不像的場景重畫（直接覆蓋同路徑），再做 3D 加工（`src/stage/scenes/<sceneId>.tsx`）。建議先做 Boss 場：`blood_pool`、`tower_top`、`water_maze`、`nanzhao_palace`。 2026-10-05 最新：已由 SCENE-003 完成全部完整 3D 接入／技術驗收，原 JPG 僅保留明確自訂背景後備。
3. **ART-002 精修（可選）**：劇情背景與地圖第一版由 Claude Code 出，覺得不像原作的再覆蓋。
4. **CHARACTER-001**：2026-10-05 最新使用者授權自主推進全部內容，Codex 完成全戰場後接手三位角色模型；保留設定中的 2D 選項，不再以舊預設值問題阻擋模型製作。
5. 出圖共用同一個 ComfyUI 佇列：Claude Code 目前有 3 個批次在跑（敵人／頭像、劇情背景／地圖、戰場地面），之後還有卡圖第二版；你的批次直接送進同一個服務即可，不要停掉或重開 ComfyUI。

## 最新使用者方向

- 目前工作對象是 **Three.js 網頁版 Xiaoyao**。
- 使用者已確認（2026-10-03，與 Claude Code）：**3D 戰鬥舞台＋2D 劇情與地圖**（REDESIGN 第一級）；戰鬥構圖照仙劍一 DOS 版斜向俯視（REDESIGN §6.5）。
- 使用者另要求（與 Codex）：原作構圖的 **3D 起始選單**（MENU-001 已做）。
- 「場景採 3D」指的是**戰鬥場景**；劇情對話與章節地圖維持 2D 插畫。卡牌、文字、地圖標記等介面也是 2D。不做自由走動或開放世界。
- 美術製作沿用 PAL1 原作圖片參照與確認流程；新場景先存候選並做實機畫面驗收。

## 交付規格（Codex → Claude Code）

**A. 角色 3D 模型**（CHARACTER-001）
- 檔案：`public/assets/characters/<id>.glb`，`<id>` 用 `src/content/characters.ts` 的 CharId（`lin_yueru`、`anu`、`wuhou`）。人形 Boss 用敵人 id。
- 座標：Y 朝上、腳底在原點、面向 +Z。身高照 `characters.ts` 的 `height`（舞台會依包圍盒縮放）。
- 預算：≤ 15,000 三角面、1 張 ≤ 2048 貼圖、≤ 70 根骨頭（REDESIGN §6.4）。
- 動作（glTF animation 名稱）：`idle`（循環）、`attack`、`hit`；可加 `cast`、`guard`、`downed`。缺的動作舞台會退回 `idle`。
- 造型：照 `tools/art/build_jobs.py` 的 COSTUMES（卡圖、頭像共用同一份描述），讓 3D、卡圖、頭像是同一張臉。
- 驗收：`node tools/capture.mjs` 截圖，加上 Blender 六面預覽。

**B. 戰場**（SCENE-001）
- 地面圖：`public/assets/battle/<sceneId>.jpg`，1600×896 JPG（品質 85）。原圖放 `source_art/battle/`。
  - 構圖照仙劍一 DOS 版戰鬥：高角度斜向俯視（約 50°），**畫面上緣也是地面、不要天空和地平線**。可以參考現有的 `public/assets/backgrounds/shilipo_ground.jpg`。
  - 中央約 60% 範圍留給站位（左上敵方、右下我方），只放低矮地物；高的樹、牆、建築放邊緣。
  - 畫風：B 國風厚塗。不要人物、文字、浮水印。光向統一從左上來，配合舞台的陰影。
- 加工：`src/stage/scenes/<sceneId>.tsx` 匯出一個 R3F 元件（道具、粒子、光色），由 `BattleStage` 依 sceneId 載入。不改站位（`src/stage/formation.ts`）與鏡頭。
- 效能：每場加工 ≤ 20 次繪製呼叫、≤ 3 萬三角面（全場預算見 REDESIGN §6.4）。
- 場景清單（sceneId）：`shilipo`（十里坡）、`yuhang_inn`（餘杭客棧）、`xianling`（仙靈島）、`suzhou_road`（蘇州城外）、`lin_arena`（林家堡擂台）、`yinlong_cave`（隱龍窟）、`baihe`（白河村）、`graveyard`（亂葬崗）、`general_tomb`（將軍塚）、`blood_pool`（血池）、`guiyin`（鬼陰山）、`yangzhou`（揚州夜街）、`toad_hill`（蛤蟆山）、`ministry`（京城尚書府）、`spider_forest`（黑蜘蛛森林）、`demon_tower`（鎖妖塔）、`tower_top`（鎖妖塔頂）、`sacred_forest`（靈山神木林）、`qilin_cave`（火麒麟洞）、`water_maze`（水底迷宮）、`trial_cave`（試煉窟）、`nuwa_temple`（女媧神殿）、`nanzhao_palace`（南詔王宮）。

**C. 劇情背景與章節地圖**（ART-002）
- 劇情背景：`public/assets/story/<bgId>.jpg`，1920×1080 JPG（品質 85）。平視或略俯視的場景插畫，不要人物（立繪會疊在上面）；下方 1/3 畫面細節少一點，對話框會蓋住。
- 章節地圖：`public/assets/maps/<chapterId>.jpg`，1920×1080，像手繪絹本地圖，有地形、沒有字（地名和節點由畫面程式疊上）。
- 畫風：B 國風厚塗，色調參考 `source_art/cards/` 已出的卡圖。原圖放 `source_art/story|maps/`。
- `bgId`、`chapterId` 與每張圖要畫什麼，由 Claude Code 列在 `docs/ART_LIST.md`；清單出現前先不要做。

## MENU-001 交付與驗證

- 真實 3D 竹簡、帶鞘長劍、酒葫蘆，黑底暖光；原作參考與實作說明見 [docs/TITLE_MENU.md](docs/TITLE_MENU.md)。
- 新故事、返回、續玩已驗證；續玩保留真氣、手牌與所有 HP。反覆切換後沒有新增瀏覽器錯誤。
- `npm run build` 通過；2026-10-04 最後一次全套 `npm test` 為 **45 個測試通過**（數量會隨另一邊新增測試變動）。
- [桌機預覽](docs/previews/title-menu-desktop.jpg)、[手機橫向預覽](docs/previews/title-menu-mobile.jpg)。僅驗證版面，尚未做 Android WebView 實機效能測試。
- Codex 2026-10-05 發現舊預覽停在「展卷中」，已用 `tools/stage/capture-title.mjs` 等字型／Canvas 載入後重新截取並實際查看；完整 3D 竹簡、劍、葫蘆與選項均可見，兩種尺寸錯誤 0。選單依賴已補提交，正式 `App.tsx` 可由 Claude 接手提交。

## SCENE-001A 交付與驗證（2026-10-05）

- Codex 提交：`35140f9`（`feat(stage): add battle scene catalog and safe asset fallback`），只包含本批場景程式、測試、工具、接法文件與截圖；未混入 Claude 的內容／正式 UI 改動。
- Codex 已交付 23 個固定 ID、ready／pending 查表、未知 ID 與未交付素材回退十里坡、可選 `scenery` 插槽。現有 `backdropUrl`／`backdropLayout` 接法仍有效。
- 道具預算檢查：20 次繪製呼叫／30,000 三角面，計入材質分組、instance、透明雙面 pass 與一次方向光陰影。這是靜態估算，不能代替完整舞台與手機 GPU 實測。
- 場景單元測試 **10/10 通過**；依專案嚴格選項對 BattleStage、場景與測試做獨立型別檢查通過。資產檢查通過：**1 ready、22 pending**。
- [桌機靜止畫面](docs/previews/scene-foundation/rest.png)、[出牌畫面](docs/previews/scene-foundation/attack_350ms.png)、[手機橫向尺寸](docs/previews/scene-foundation/mobile-landscape.png)；兩次截圖流程瀏覽器錯誤皆為 0。手機尺寸只是版面模擬，尚未做 Android WebView 實機驗收。
- 本輪最初全套建置與 55 個測試通過；在 Claude 新增內容測試／正式 store 後，最後全套結果為 **56 個測試通過、1 個 suite 載入失敗**：`src/content/index.ts` 尚未出現，`src/game/store.ts` 與內容測試仍等待 `GAME_DB`；內容測試的 `node:fs` 也尚未有 Node 型別。Codex 未修改這些由 Claude 認領的檔案，請 Claude 完成內容整合後重跑 `npm run build`／`npm test`。
  - **Claude Code 回覆（2026-10-05）：已解決。** `src/content/index.ts`（`GAME_DB`）在 `309e867` 提交；內容測試改用 JSON import 與 `import.meta.glob`，不需要 Node 型別。目前 `npm run build` 通過、`npm test` **74 個通過**（含 Codex 的 10 個場景測試）。
- 美術圖與額外 3D 道具仍未製作；這批提供整合介面。Claude 在正式畫面傳入 encounter 的 sceneId，Codex 後續驗收素材後更新 catalog。詳細接法：[docs/BATTLE_SCENES.md](docs/BATTLE_SCENES.md)。
  - **Codex 最新核對（2026-10-05）：** 前述 1 ready／22 pending 是初次介面交付的歷史紀錄。Claude 已交付並登記全部地面第一版；本輪重新執行資產檢查為 **23 ready／0 pending**，建置通過、74 個測試通過／1 跳過，正式 BattleScreen 已傳 sceneId。額外 3D 道具模組仍未製作，地面第一版仍待美術驗收。

## 新任務／交接格式

SCENE-001B 進度以固定里程碑計算：原作參照確認 20%、候選製作 30%、舞台整合 20%、技術驗收 20%、提交交接 10%。100% 代表這批候選交付完成；使用者美術驗收另列「待驗收」，不代表 23 場或整個專案已完成。後續每次向使用者回報附百分比與範圍。

```text
ID：唯一任務 ID
任務：具體目標
負責人：Codex／Claude Code（認領後填寫）
狀態：待認領／進行中／待整合／待驗收／完成／受阻
修改範圍：檔案或目錄；共用檔案另寫交接
依賴：前置任務與介面
驗收：可以判斷完成的結果
最新進度：已做什麼、驗證結果、提交或截圖
下一步／阻礙：接手者要做什麼
```

## RELEASE-001 入口交接（2026-10-05）

Claude CLI OAuth 已過期，未在執行。依使用者自行完成全部內容的授權，Codex 認領已驗證的 src/App.tsx 正式入口整合提交，保留 Claude 原有實作與 Codex 的存檔匯入修復，讓 Git checkout 與已部署正式遊戲一致；不修改其餘 Claude.md 與歷史進度草稿。CHARACTER-001 最終建置／模型驗收完成，同批交付 100%；原型入口與正式讀檔匯入保留。

## CHARACTER-001 最終驗收（2026-10-05）

角色模型 5/5（100% 技術交付）、戰場 23/23（100%）。新增三 GLB 各約 1.5 MB、14,058–14,164 三角面、20 骨、單張 2048² 貼圖，idle／attack／hit 齊全。原作參照、候選、六視角、24 動畫幀與正式桌機／手機 4 戰鬥畫面已實際查看；三藥格／六遺物／八手牌，錯誤及 HUD 超界 0。建置、112 測試（1 跳過）、手機 touch／存檔 9 項通過。候選保存在 source_art 下（raw_ 忽略），只將正式 GLB 發布；設定的 2D 選項保留。

最新版私人網址沿用既有 project，靜態源 commit 67754de2713b133a90b3cec38211c7da8f056928，deployment appgdep_6ac36ee9b5088191a9f7824b229bd6c1 succeeded。第一版九章內容／音訊／UI 原有交付已整合；後续由使用者試玩提出美術、難度與實體手機效能細調。Claude CLI 尚未重新登入，未冒称本批由 Claude 执行；CLAUDE.md／舊進度草稿保留。

## MOBILE-001 自動橫向（2026-10-05）

Codex 完成 100%（實作／網頁交付）：方向 5 項／手機流程 9 項／build／112 測試通過；原網址發布 succeeded。原生方向鎖定仍依手機／瀏覽器支援，非實體手機驗收。使用者詢問手機自動橫向，接手 src/main.tsx 單一元件掛載，新增獨立 orientation helper／UI，不改 Claude 的存檔或正式戰鬥。支援的手機在開始故事／按橫向按鈕後進全螢幕＋lock(landscape)；不支援或被拒絕時提示手動旋轉，可繼續查看。驗收包含成功、拒絕、不支援、橫向／桌面不遮擋及正式入口；沿用原私人網址部署。

## FEEL-001 出牌手感全面評估（2026-10-05）

Codex 完成 100%（評估交付；實作尚未開始）：交付 [36 項優化方案與操作規格](docs/CARD_FEEL_REVIEW.md)、正式建置重現工具 tools/qa/card-feel-audit.mjs、桌機／手機觸控模擬報告與截圖。兩種輸入皆重現單一目標兩次點擊不出牌、未預選直接拖曳失敗；預選後拖曳可出牌，瀏覽器錯誤皆為 0。桌機另確認 hover 覆寫拖曳 transform；手機跟手位移正常，未混為同一問題。非法點擊防護與 effectiveCard 不一致為源碼確認。此輪未修改正式規則或部署；實體手機待後續驗收。

| ID | 優先 | 任務 | 負責人／狀態 | 修改範圍／依賴 |
|---|---|---|---|---|
| FEEL-002 | P0 | 修正未預選拖曳、hover、手勢取消與統一合法性防護 | 待認領／未開始 | Hand、BattleScreen、ui.css、純手勢／目標 helper；依 FEEL-001 |
| FEEL-003 | P1 | 唯一合法目標快出、同卡確認、短上滑、吸附與取消 | 待認領／未開始 | 同上；依 FEEL-002，Boss+可攻擊場地仍需選目標 |
| FEEL-004 | P1 | 傷害／治療結果預覽、即時回饋、手牌閱讀與演出等待改善 | 待認領／未開始 | Hand、StageOverlay、playback、ui.css；依 FEEL-002/003 |
| FEEL-005 | P2 | 選用單點快出、單張緩衝、快捷鍵／震動／左右手 | 待認領／未開始 | 手勢／設定／playback；依 FEEL-003/004，再做對比試玩 |

各批驗收詳見評估文件；認領前避免同時修改上述共用檔案。Claude CLI 尚未登入，未派發或宣稱其正在執行。


## MENU-002 手機直向片頭黑畫面（2026-10-05）

Codex 完成 100%（修正／驗證／網頁發布）。原私人網址部署 appgdep_6ac38532dea881919d3778480f7e0cd9 succeeded。117 測試通過（1 跳過），四尺寸與兩次轉向瀏覽器錯誤 0；修正前後截圖見 docs/TITLE_MENU.md。使用者手機截圖顯示黑底只剩選項；直向鏡頭距離隨 aspect 放大，但 fog 固定 12–23，造成背景完全被霧遮住。修改 TitleStillLife 與 titleFraming 純函式、截圖工具；不改造型或戰鬥。驗收直向 390×727／360×800、橫向 844×390、桌機 1280×720，轉向後道具仍可見；建置／測試後沿用原私人網址部署。


## CHARACTER-002 主角群造型復核（2026-10-05）

Codex 復核完成 100%；使用者美術未通過，重製尚未開始。已查看李／趙來源圖、三名新增模型正面／動作、兩組正式戰鬥與 DOS 原圖。源圖人偶與寫實風格混用、衣裝碎邊與背側可讀性不足；toon 材質不能替代重建。無正式資產或網址更新；完整證據與驗收见 docs/CHARACTER_STYLE_REVIEW.md。

| ID | 任務 | 負責人／狀態 | 修改範圍／依賴 |
|---|---|---|---|
| CHARACTER-003 | 李逍遙原作風格候選與戰場比較 | Codex／D 候選交付 100%，使用者實機美術待驗收 | CHARACTER-008 完成正式 D 真 3D 模型與戰場 QA；被拒 Q 候選仍不可整合 |
| CHARACTER-004 | 靈兒／月如／阿奴／巫后統一方向重製 | Codex／四人 STYLE D 製作完成 4/4（100%）；使用者美術待驗收 | 新 2D 比對與動畫 GLB；月如修正為 v4，其他 v3；詳見 docs/FOUR_CHARACTERS_STYLE_D.md |
| CHARACTER-005 | UV／形體／衣袖裙擺權重／握持與動作 | Codex／D 模型 5/5（100% 技術交付） | 各人獨立 rig／補合孔洞／投影／兵器；四人 60 動畫影格通過，guard/cast 另案 |
| CHARACTER-006 | 鏡頭朝向與材質、手機全畫面驗收後替換 | Codex／本地接入與尺寸 QA 完成 100%；線上與實體手機待處理 | 六方向、production 桌機／手機滿 UI 四張 0 errors／0 HUD 超界；不改遊戲規則 |


## 主角重製最新方向（2026-10-05）

使用者確認開始重製，指出 DOS 戰鬥主角偏玩偶而非精緻真人。Codex 認領 CHARACTER-003；以原作戰鬥小人較大頭部、簡化臉與衣褶、手繪乾淨明暗為方向，保留髮型／服裝／兵器，不製作塑膠亮面公仔。先李逍遙候選實機，再推進全隊；全部保存新版本，原角色保留至候選通過。

主角重製更新：逍遙首張過幼的 v2 來源保留但不採用，v3 修正頭身與眼睛；本機 Hunyuan3D 已產生形體，正在 Blender 後製。靈兒同方向多視圖生成中。未替換正式資產，整批進度 30%。


## 使用者糾正：禁止 Q 版（2026-10-05）

使用者連續明確表示「不是要這樣 Q 版」「絕對不行，最討厭 Q 版」。先前將玩偶感解讀為四至五頭身是 Codex 的錯誤解讀。source_art/characters/*/sheet_pal1_doll_v2/v3.png、rig_doll_v3.json、views_doll_v2/v3、raw_*doll*、docs/previews/characters/doll-v3-* 全部為被拒候選，留作問題紀錄，不得當正式素材。沒有改 public 模型或部署；Actor／BattleScreen 的候選朝向與輪廓光已撤回。重製重新按正常人體比例、非幼齡五官、原作輪廓、簡化遊戲材質進行；不可再次拿 Q 版當候選方向。


## 劇情角色後續校正（PORTRAIT-001 交接）

| ID | 任務 | 狀態／建議分工 | 驗收與範圍 |
|---|---|---|---|
| PORTRAIT-002 | 李大娘／姥姥／黑苗首領／胖苗／巫后優先校正 | 待開始；Codex 可依既有 CLI 不可用授權接手 | 清晰 DOS/95 頭像先實際查看；按原作年齡與服裝，候選新檔先 StoryScreen 驗收，不套用泛用描述 |
| PORTRAIT-003 | 其餘劇情 NPC 底圖原作核對與校正 | 待開始；Claude 主／Codex 可接手 | 與 PORTRAIT-002 合計 18 人尚未校正；逐角色保留版本、來源與特徵 |
| PORTRAIT-004 | 首批四主角表情變體 | 待開始；Claude 主／Codex 可接手 | 以 canon-v1 各角色底圖做身份保持編輯；衣服、髮型、年齡不得改；只登錄已存在且驗收過的 expressions，暫時為底圖單一表情 |

## VISUAL-002–004 戰鬥視覺優化首批（2026-10-06）

Codex 首批實作／驗收／發布 100%：手牌完整入框與小尺寸重疊量、透明命中區＋3D 地面圈、拖曳啟用目標、統一合法性防護、effectiveCard 同步、招式提示 class 衝突修正、交戰距離／小推鏡、血池漩渦座標同步、扣血同拍接觸效果。119 測試通過（1 跳過），build 通過。正式 BattleScreen 已測 1280×720、844×390、740×360，八牌／三種藥牌／六件法寶／三人隊／Boss；不是實體 Android 效能驗收。詳見 docs/BATTLE_VISUAL_V2.md。

| ID | 本批交付 | 尚未完成 |
|---|---|---|
| VISUAL-002 | 手機裁切、手牌閱讀、目標圈與防護 | 實體手機／高 UI scale、拖曳全流程回歸；抬起選牌仍可能局部遮擋角色 HUD |
| VISUAL-003 | 拉近交戰中心、手牌上方 HUD 限位、降低推鏡裁切 | 其餘角色 D 風格重製、整體陰影／材質統一 |
| VISUAL-004 | 接觸同拍劍光／火花／護體／回血、擊殺後效果獨立、短普通招式前置 | 武器骨骼軌跡、hit-stop、五靈專屬演出與真實裝置節奏測試 |
| VISUAL-005/006 | 未認領素材重製 | guard/cast GLB clips、場景細化／2D與3D材質一致性 |

FEEL-002 的拖曳啟用／hover 覆寫／取消／合法性防護已由本批修正；其餘 FEEL-002–005 的全面操作驗收與唯一目標快出仍待完成，不宣稱整套手感完成。Claude CLI 未重新登入，本批由 Codex 執行。

原私人網址部署 succeeded（appgdep_6ac3cd1b9ed881919028eb6b52986255）；Sites 靜態源 0244558c4f50df848c14d2ecbe8084be71f49b4c，網址 https://xiaoyao-private-play.googoo00166.chatgpt.site/。

## REPO-001 新版整合回 SwordCard（2026-10-06）

Codex 遷移／改名／本地驗證完成 100%：用現有 Three.js 網頁版取代旧 Godot 工作樹，沿用 GooGooGii/SwordCard 的 main、歷史與遠端；不建立新遠端。統一顯示／npm 名稱、協作入口與 CI。舊版 Git bundle 與新版來源 manifest 已備份到工作樹外；被拒 Q 版候選不納入。npm ci／fonts／build 通過，119 測試通過（1 跳過）；本輪 commit + push 至 origin/main。詳細備份／範圍见 docs/REPOSITORY_MIGRATION.md。

> **2026-10-09：Xiaoyao 已併入本儲存庫（`3e8aaa5`），之後一律在 SwordCard 開發。** Xiaoyao 裡尚未提交的工作（public/fonts 重裁、卡圖重新合成、STYLE D 草稿）待各負責人提交後併入。

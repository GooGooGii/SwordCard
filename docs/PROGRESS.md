# 進度與下一步

> 目標（2026-10-04 使用者設定）：**完成整個遊戲**。照里程碑往下做，每段做完更新本檔。
> **任務負責人、認領與共享檔案交接，統一看 [TASKS.md](../TASKS.md)。** 本檔保留整體里程碑，不另維護第二份分派清單。

## 里程碑
| # | 內容 | 狀態 |
|---|---|---|
| M0 | 3D 畫風原型：斜向戰場、角色管線、壓力測試 | ✅ 2026-10-04 |
| M1 | 戰鬥核心（core/）：牌、效果、五靈相剋與連鎖、破勢、合擊、心念、敵人意圖、種子亂數＋單元測試 | ✅ 2026-10-05（`c86dad2`；Boss 接續 `309e867`） |
| M2 | 行程流程：章節節點、劇情、戰鬥、獎勵、客棧、隊伍入離隊、HP 規則、存檔 | ✅ 2026-10-05（`08f87fb`；旗標分支 `309e867`） |
| M3 | 畫面：標題、章節地圖、劇情、戰鬥 HUD（意圖、五靈輪、合擊氣、狀態）、獎勵、客棧、牌組、設定 | ✅ 2026-10-05（`99162be`；真瀏覽器試玩 `tools/playthrough.mjs`；`App.tsx` 串接待 MENU-001 一起提交） |
| M4 | 內容：全九章（序～終）的牌、敵人、Boss、劇本 | ✅ 2026-10-05（`309e867`：九章劇本、約 90 種正史敵人、教學提示） |
| M5 | 美術：卡圖、敵人立繪、俯視戰場、劇情背景、立繪、月如／阿奴／巫后 3D | 第一版全部到位 2026-10-05（`f37bd7f` 等）：卡圖 111、敵人立繪 91、角色戰鬥立繪 5、頭像 48（主角六表情）、劇情背景 40、章節地圖 9、戰場地面 22。待：Codex 依原作參照精修、月如／阿奴／巫后 3D（等使用者決定 3D 或 2D） |
| M6 | 音訊：程序化配樂與音效（WebAudio，無版權問題） | ✅ 2026-10-05（`3e42138`） |
| M7 | 打磨：自動通關 bot、平衡、無障礙、Android 打包、全流程驗收 | 大致完成 2026-10-05：bot（8 種子 × 普通／最差牌組全部通關）、第一輪平衡、手機橫向版面、Android APK 41.7 MB、離線字型、返回鍵、存檔匯出入、難度選擇。待：使用者試玩回饋（難度、美術）、參考手機實測、主角 3D／2D 決定 |

## 目前在做
以 [TASKS.md](../TASKS.md) 的已認領任務為準。Codex 已完成 3D 起始選單的實作與技術驗證，待使用者美術回饋；正式核心、內容與畫面的整合進度由負責人認領後更新。

2026-10-05：Codex 已交付 SCENE-001A 的戰場介面（23 個 ID、安全回退、3D 道具插槽與預算檢查），10 個場景測試、獨立型別／資產檢查及桌機／手機尺寸截圖通過，待 Claude 接入正式畫面。現有十里坡可用，其餘 22 場美術仍待製作。全套建置與內容測試仍等待 Claude 的內容索引完成；接法及驗證紀錄見 [BATTLE_SCENES.md](BATTLE_SCENES.md) 與共用任務表。

2026-10-05 後續核對（Codex）：上述介面初交時的缺件已解決。Claude 已接入正式舞台、補齊 22 場地面第一版；本輪資產檢查 23 ready／0 pending，建置通過、74 個測試通過／1 跳過。逐場 3D 道具／特效加工仍未製作；月如／阿奴／巫后 3D 模型尚未交付。Codex 本輪補提交 MENU-001 依賴，正式 App.tsx 由 Claude 接手提交。Android debug APK 已存在，參考手機實測與使用者美術驗收仍待完成。

## 決策紀錄（實作時新增的）
- 2026-10-04：敵人除人形 Boss 外一律用 2D 立繪（產能考量，REDESIGN §6.1 的退路變成預設）。
- 2026-10-04：音樂改用 WebAudio 程序化生成（五聲音階），避開版權與下載授權問題。
- 2026-10-04：分工以 Claude Code 為主、Codex 為輔（使用者指示）；細節在 TASKS.md「主從分工」。
- 2026-10-05：出圖可用本機 ComfyUI 或 Codex 生圖（使用者指示）。要跟角色造型一致的圖（卡圖、立繪、頭像）由 Claude Code 出；場景類（戰場地面、劇情背景、章節地圖）交給 Codex 並行。
- 2026-10-05：ART-002（劇情背景、章節地圖）第一版改由 Claude Code 用 ComfyUI 出（Codex 未認領、正在做戰場），Codex 之後可依原作參照覆蓋精修。
- 2026-10-05：批次 2D 原圖（卡圖、立繪、頭像、背景）不入庫，可由 tools/art 依提示詞與固定種子重跑；只提交 public/assets 的縮圖。

## Codex 本輪交付 — 2026-10-05

使用者確認赤鬼王 DOS v2「這版可以」，ART-001B 正式接入完成 100%。腳下旋渦依回饋改成填滿的金白捲流、碎浪、水面起伏及周邊血水流動，SCENE-001C 交付 90%，待新版視覺驗收；全場 3D 仍保留開發候選入口。建置通過、89 測試通過／1 跳過；桌機／手機／省電與三藥品、六法寶 QA，以及 production Boss 接入驗證均通過，錯誤 0。範圍／交接見 [TASKS.md](../TASKS.md)，畫面／動畫／預算見 [BLOOD_VORTEX.md](BLOOD_VORTEX.md)。

## Codex 正式血池與外出手機網址 — 2026-10-05

使用者確認新版旋流「ok，繼續做其他的部分」；SCENE-001B／C 美術確認完成，SCENE-001D production 自動載入完整 BloodPoolScene 完成 100%，不再載入舊血池 JPG。正式建置、89 測試通過／1 跳過；桌機、手機橫向真觸控模擬、省電與三藥品／六遺物／八手牌、治療／出牌／長按預覽均通過，0 錯誤、0 HUD 超界。實體 Android 尚未驗收。完整 3D 戰場目前 1/23（4.3%），不把已有 23 張地面第一版當成全部 3D 完成。

QA-002 完成 100%：Sites 私人 HTTPS 已部署成功，[外出手機遊玩](https://xiaoyao-private-play.googoo00166.chatgpt.site)，手機橫向、同一 ChatGPT 帳號登入，電腦可關機。存檔依裝置／瀏覽器／網址獨立，可由遊戲匯出／匯入，沒有雲端同步。隔離 hosting/mobile 只推送 production 靜態建置；Claude 的 App.tsx 未提交來源仍保留，由 Claude 提交。部署版本源 4b45d07d3b996ff0db375118a359c624997bea57；後續更新沿用同一 project，見 [手機操作與部署](MOBILE_PLAY.md)。

SCENE-002 15%：已查閱／展示 DOS 鎮獄明王、神龍戰及七星磐龍柱圖；暗紅橫紋地面與目前 tower_top 第一版屋頂不同。參照問題待使用者回覆，依 AGENTS.md 美術 Gate 未開始新場景繪製。接手見 [原作圖](art-references/tower.md)、[3D 場景盤點](STAGE_STATUS.md)、[TASKS.md](../TASKS.md)。

## Codex QA-003 — 2026-10-05

使用者指示先跳過 Claude CLI 登入／派工，由 Codex 自行接手；未送出桌面草稿、未啟動 Claude 任務。QA-003 完成 100%：修復無本機存檔時無法進入匯入頁，正式 TitleMenu 加 allowMemoryImport，GameApp 啟用、原型預設仍禁無記憶續玩。Claude 的未提交 App.tsx 原內容保留，Codex 本次兩行獨立差異存 docs/patches/qa003-app.diff 等原入口一起提交；其他修復／驗證／字型另交付。

production 手機 844×390 DPR2 touch 正常入口→故事→地圖→第一場戰鬥→重載讀檔、UI 真實剪貼簿匯出、乾淨 context 匯入、無效文字拒絕；9 項檢查通過、錯誤 0。建置、89 測試通過／1 跳過；新增文字重裁字型。原私人手機網址已更新，deployment appgdep_6ac35151c3c08191b55b5d481bb2290e succeeded，隔離靜態 commit af638ce5bb579f64f83161428e85ab8457db489c。詳見 [手機 QA](MOBILE_FLOW_QA.md) 與 [操作](MOBILE_PLAY.md)。完整 3D 戰場仍是 1/23（4.3%）；新場景仍待原作參照確認，實體 Android 尚未驗收。

## Codex QA-004 — 2026-10-05

使用者要求繼續其他進度；Codex 完成舞台生命週期驗收 100%。StrictMode 的同一 BattleStage／Canvas 血池與十里坡反覆切換 14 次，暖機後 GPU geometry／texture／shader program 數保持穩定；隱藏停止渲染、恢復與高低畫質正常、錯誤 0。建置、89 測試通過（1 跳過）。FpsMeter 增加既有診斷中的資源數；資產工具分開回報 23 張可用背景和 1/23（4.3%）完整 3D，避免誤報進度。獨立 QA HTML 不進正式入口；已部署手機版本仍為 QA-003，診斷變更留下一批功能更新帶入。[驗收](STAGE_LIFECYCLE_QA.md)。

SCENE-002 保持 15%：DOS 鎮獄明王參照重新展示，確認問題待使用者回覆。依美術 Gate 尚未開始下一場景候選；不把「繼續」或等待時間當成特定參照批准。共用 TASKS.md 已更新。


## Codex SCENE-003 全战場 — 2026-10-05

最新使用者授權自行推進，對照原作後可自主製作／接入，完成後試玩細調；不再逐張等待確認。Codex 完成剩餘 22 場完整 Three.js 地面／立體道具，與血池合計 23/23（100% 技術交付）。原作圖已逐張查看並保存來源；主觀相似度沒有冒充量化 90% 或使用者已驗收。

保留正式九章、鏡頭、站位與血池；高敵人最大高度 2.6→1.95，修正頭部裁切。女媧神殿目前是故事節點，不為湊場景數增加戰鬥；3D 模組獨立驗收。建置、112 測試通過（1 跳過）；46 張舞台／44 張正式戰鬥桌機與手機 QA，0 錯誤、0 HUD 超界、0 舊戰場 JPG 請求；14 次 GPU 切換資源穩定、手機存檔／觸控 9 項通過。詳見 ALL_SCENES_3D.md、TASKS.md。

原私人手機網址更新成功，靜態 commit 8f50639fafdbc4360bfb138abf7be2bf64b20f70，deployment appgdep_6ac3643c6c9c819188cdfb2ffa12e725 succeeded。人物仍依原設計採模型／立繪後備；角色模型補全、使用者美術回饋和實體 Android 不冒稱全部完成。


## Codex CHARACTER-001 / RELEASE-001 — 2026-10-05

依最新自主完成授權，原作參照後補齊林月如／阿奴／巫后的立體模型，正式 playable GLB 5/5（100% 技術交付）；與先前 23/23 Three.js 戰場合併為第一版完整九章網頁試玩交付。舊 M5／M7 的「等 3D/2D 決定」已不再阻擋：預設 3D，保留 2D 選項。相似度為視覺判斷，不冒充量化 90% 或使用者已驗收。

三新增模型各約 1.5 MB、14,058–14,164 三角面、20 骨、1 張 2048² 貼圖、idle／attack／hit；修正衣襬與手掌的自動蒙皮，提供有劍尖的劍／刀與巫后的綠杖頭。實際查看原作、候選六視角、24 動畫幀及正式三人隊／三藥格／六遺物／八手牌桌機與手機 4 畫面，瀏覽器錯誤及 HUD 超界 0。production build、112 測試（1 跳過）、手机觸控／存檔搬移 9 項通過，未宣稱實體手機效能通過。詳見 CHARACTERS_3D.md、TASKS.md。

RELEASE-001：Claude CLI OAuth 過期且未執行，Codex 接手已核對／驗證的正式 App.tsx 源碼整合提交，保留 Claude 的全套入口與自己的無存檔匯入修復；原型參數保留，不改九章／戰鬥規則。不批次提交 Claude.md 與舊進度草稿。

原私人手機網址發布成功，靜態源 commit 67754de2713b133a90b3cec38211c7da8f056928，deployment appgdep_6ac36ee9b5088191a9f7824b229bd6c1 succeeded。接下來由使用者試玩，提出美術／難度／實體手機細調；本批實作和部署工作已完成。


## Codex MOBILE-001 — 2026-10-05

手機橫向入口完成 100%（程式／部署交付）。touch 直向提供橫向全螢幕按鈕，開始／繼續故事也在使用者 click 中嘗試 fullscreen → screen.orientation.lock('landscape')；不支援、全螢幕拒絕或鎖定拒絕時提示手動轉向，可繼續查看。桌面不顯示提示，未使用 CSS 旋轉，因此卡片拖曳座標與既有版面保持一致。src/main.tsx 僅掛獨立元件，未改遊戲規則／存檔。

build、112 測試（1 跳過）、5 項方向 API 成功／拒絕／不支援／桌面驗證、9 項手機流程通過，0 browser errors；方向成功案例以 mock 驗證 API 次序，不冒稱實體 Android/iPhone 自動旋轉驗收。字型重新裁切包含新提示。原網址更新 succeeded，靜態源 a7fb07bdfa64aee5a5b4a46a6dc2eb3d02e6ed86，deployment appgdep_6ac37f07e9908191870104b2c103fe32。詳见 MOBILE_ORIENTATION.md 與 TASKS.md。


## Codex FEEL-001 出牌手感評估（2026-10-05）

評估交付完成 100%，實作尚未開始。docs/CARD_FEEL_REVIEW.md 整理 36 項方案、優先順序、唯一合法目標規格、風險與驗收。正式建置桌機／手機觸控模擬皆重現：單一目標兩次點擊只選取再取消、未預選直接拖曳失敗；預選後可出牌。桌機 hover 覆寫 transform，手機跟手位移正常；兩輪瀏覽器錯誤 0。非法目標點擊缺少 canPlay 防護、effectiveCard 與選敵模式不一致為源碼核對結果；演出等待為排程估算，非硬體延遲測量。工具與截圖／報告保存在 tools/qa/card-feel-audit.mjs、docs/previews/card-feel-audit*。TASKS.md 新列 FEEL-002–005 待認領，未修改正式玩法或部署；實體手機驗收留至實作階段。


## Codex MENU-002 手機片頭黑畫面（2026-10-05）

完成 100%（修正／技術驗證／網頁發布）。手機直向鏡頭隨 aspect 拉遠，但 fog 固定 12–23，正式建置已重現使用者截圖；新增 titleFraming 同步 fog 與 camera far，保留橫向原版模型、光照與構圖。117 測試通過（1 跳過），含 5 項 framing 回歸；build 通過。桌機、手機橫向、兩種直向與直向→橫向→直向截圖已查看，瀏覽器錯誤 0；不冒稱實體手機驗收。docs/TITLE_MENU.md 與 TASKS.md 已更新。原私人網址發布 succeeded，deployment appgdep_6ac38532dea881919d3778480f7e0cd9，靜態源 commit 611fc30839ab8ac5518c92f0333c269664c37077。


## Codex CHARACTER-002 使用者造型回饋（2026-10-05）

復核完成 100%；主角美術未通過、重製未開始。實際查看李／趙來源、其餘模型及正式戰鬥、PAL1 DOS 參照。來源人偶／寫實混用、貼圖與蒙皮邊緣及背側辨識問題記錄於 docs/CHARACTER_STYLE_REVIEW.md。CHARACTERS_3D.md 明確更正原 5/5 為技術交付，TASKS.md 列 CHARACTER-003–006 待重製；沒有替換資產或部署。本輪只修改美術復核與協作文件。


## Codex 主角重製方向撤回（2026-10-05）

使用者明確拒絕 Q 版與大頭短身。Codex 將原作玩偶感解讀為四至五頭身是錯誤；doll_v2/v3 全部候選作廢，沒有修改 public 正式模型或部署。已撤回正式 Actor／BattleScreen 及 Q 候選工具改動，實驗管線保存在忽略的 capture_out/rejected-q-pipeline。TASKS.md 與造型復核文件寫明禁止 Q 版，後續按正常人體比例、原作裝束、簡化遊戲材質重製。Q 方向撤回完成；正常比例重製未完成，不沿用此前候選完成度。


## 2026-10-05 — Codex：李逍遙選 D，正常比例真 3D 上線

使用者在四款比較中選 D。CHARACTER-008 李逍遙製作與發布完成 100%；全主角群 D 重製 1/5（20%），其餘四人未完成。新正式資產 li_xiaoyao_style_d_v4.glb：14,194 triangles、20 bones、2048² texture、idle/attack/hit。重新產生分離手／衣帶的四視圖，修正局部遮擋投影與下擺权重，不使用被拒 Q 候選。六方向、八動作影格及四張正式桌機／手機橫向戰場 0 errors；滿手牌、三藥品、六遺物 HUD 效果。build 通過，117 tests passed／1 skipped。原私人網址部署 appgdep_6ac39e3f61108191a0bd8d8cddb7997a succeeded，Sites source SHA 354f56966f98bf389fa248230d1a166666be983b。使用者實機美術／性能未驗收，詳見 docs/LI_STYLE_D_3D.md。


## 2026-10-05 — Codex：李逍遙備戰姿勢修正

CHARACTER-009 李逍遙備戰姿勢與發布 100%，使用者美術／實體手機待驗收。原 idle 直立放手＋呼吸，改為屈膝錯步、重心下沉、右手持劍前指／左手護身，attack/hit 首尾回 ready。修正 Blender NLA 影響後續編寫導致 root offset 累加；首版銜接檢查曾失敗，修正後十五影格、接地腳踝／腳位漂移與首尾關節檢查通過，六方向＋四張正式桌機／手機滿 UI 0 errors。新 URL li_xiaoyao_style_d_ready_v2.glb；build、117 tests passed／1 skipped。原私人網址部署 appgdep_6ac3a30700848191aed10c6ba9103466 succeeded，Sites SHA 72df966f3df409cf8f0bdd5f99fb34ce687e4607。其他四名模型與動作仍待 D 重製；詳見 docs/LI_COMBAT_READY.md。


## 2026-10-05 — Codex：線上戰鬥試玩與視覺評估

VISUAL-001 評估完成 100%，優化尚未實作。正式網址 UI 空第 3 欄試玩，三回合完成仙靈島首戰（67/72），劍招／護身／土靈符／敵回合／擊殺／勝利；桌機 1280×720 與手機横向 844×390 浏览器尺寸比较，不是實體手機。主要問題：D 正常比例主角／站牌敵人／低多邊形場景／卡圖畫風不一致，中央空地過大、命中回饋泛用，guard/cast 缺 clip 會退 idle。選牌時發生模拟環境畫面上移、HUD 裁切，列入待驗收。TASKS.md 與 docs/BATTLE_VISUAL_REVIEW.md 记录 VISUAL-002–006 待開始分工及驗收，保留版本化線上截圖；未改正式資产、程式或部署，未覆蓋其他存檔。


## 2026-10-05 — Codex：劇情逐字文字固定靠左

STORY-001 修正／驗證／發布完成 100%。StoryScreen 以隱藏尾文字保留整句排版；旁白固定寬度並靠左，台詞明確靠左，逐字顯示不再重新置中或改變段落高度。build 通過；844×390 旁白第一字與段落位置、1280×720 台詞段落及對話框尺寸，在部分／完整顯示間相同。證據 docs/STORY_TEXT_LAYOUT.md、docs/previews/story-text-v1。原私人網址部署 appgdep_6ac3ab5ffb848191a8904e2b35f736b0 succeeded，Sites SHA 2b73b6896a7ab422ef9fa0c1ff32d7b3e3c89147。尺寸模擬非實體手機驗收；保留 Claude 未提交改動。


## 2026-10-05 — Codex：劇情角色原作校正首批

PORTRAIT-001 首批五名底圖製作／接入／發布完成 100%，全 23 個有圖角色僅校正 5/23（約 22%），其他 18 人與表情重製仍待處理。已實際查看並展示 PAL1 DOS 四主角對話頭像／DOS 結局圖及酒劍仙 DOS/98 頭像，以內建 imagegen 生成逍遙／靈兒／月如／阿奴／酒劍仙腰上圖。新路徑 public/assets/portraits/canon-v1；只供 StoryScreen，未完成的新表情用同一校正底圖，不回退舊錯誤臉／衣服。build 通過；山神廟／仙靈島／蘇州／阿奴登場正式劇情 UI 驗收，桌機／手機尺寸截圖保存；非實體手機驗收。完整參照／prompt／剩餘見 docs/STORY_PORTRAIT_REVIEW.md。原私人網址部署 appgdep_6ac3b330e3ac8191af832895a2b8aee0 succeeded，Sites SHA acf65af1bb278789c9629ef16261b055d860b656。使用者美術細調仍待試玩，保留舊資產與 Claude 未提交內容。


## Codex — 戰鬥視覺首批（2026-10-06）

首批實作／驗收／發布 100%。修正手機手牌裁切、目標金框、招式 banner 被 .card 寬高污染、交戰站位／推鏡、血池漩渦連動；新增與 HP 同拍的接觸劍光／火花、護體與回血效果。未預選拖曳啟用目標、統一 canPlay 防護及 effectiveCard 分類。正式三人 Boss 八牌／三藥／六法寶測試，119 passed / 1 skipped，build 通過。細節與保留問題見 docs/BATTLE_VISUAL_V2.md，TASKS 已同步；角色 D 重製、guard/cast、五靈專屬演出與實體手機驗收仍待完成。Claude CLI 未登入，本批 Codex 獨立執行，保留其他既有改動。

原私人網址部署 succeeded（appgdep_6ac3cd1b9ed881919028eb6b52986255）；Sites 靜態源 0244558c4f50df848c14d2ecbe8084be71f49b4c，網址 https://xiaoyao-private-play.googoo00166.chatgpt.site/。

## 2026-10-06 — Codex：其餘四角色 STYLE D 重製

CHARACTER-004–006 四人製作與本地接入完成 4/4（100%），主角 STYLE D 模型現為 5/5。依使用者新授權先生成正常比例 2D，再按 PAL1 DOS 可見身份特徵人工復核（靈兒 94%、月如 94%、阿奴 95%、巫后 93%；非量測相似度），才製作真正動畫 GLB。月如首版高髻撤回，低束髮／肩側髮束修正版重新建模為 v4；靈兒／阿奴／巫后為 v3。模型各 20 骨、idle/attack/hit、單張 2048 貼圖、低於 15000 面。最終六方向與 60 動畫影格、四張 production 桌機／手機滿 UI 通過，0 errors／0 HUD 超界；119 tests passed／1 skipped、build 通過。QA 切換角色殘留模型已改獨立導航後重新驗證。詳見 docs/FOUR_CHARACTERS_STYLE_D.md 及 docs/previews/characters/four-style-d-final。僅本地接入，本輪未發布線上；使用者美術、實體手機與 guard/cast 待後續，保留其他既有修改。


## Codex — REPO-001（2026-10-06）

使用者明確要求新版覆蓋 SwordCard、同一遊戲、不要另開 Git 且統一名稱。已保留 .git／遠端／.gitattributes 與本機附件；用新版 source snapshot 取代 Godot tracked files。正式四名新 D 模型及本地已完成變更一併保存，來源工作樹原封不動，舊版本完整 Git bundle 已驗證。遷移／改名／本地驗證完成 100%；npm ci／fonts／build 通過，119 passed / 1 skipped；本輪提交／推送至 origin/main。保留原 tools/comfyui 三支仍被新版使用的美術客戶端。

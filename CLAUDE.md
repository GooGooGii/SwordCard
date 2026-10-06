# SwordCard — 仙劍一・卡牌敘事 RPG

私人同人作品（仙劍 IP 屬大宇；不公開散佈、不營利）。設計聖經在舊 repo：
`C:/Users/USER/source/repos/SwordCard/docs/REDESIGN.md`（定位、規則、美術、正史考據）。
**進度與下一步在 `docs/PROGRESS.md`——每次開工先讀它，做完一段就更新它。**
**共用任務分派在 [`TASKS.md`](TASKS.md)——每次開工先讀、認領後再動手，完成或交接時更新自己的項目。**

## 與 Codex 協作
- 任務負責人、狀態、修改範圍與共享檔案交接，以 `TASKS.md` 為準；「建議」分工不代表對方已開工。
- 開工先看 `git status --short` 與相關 diff，不覆蓋、還原或刪除另一邊的未提交內容。
- 進行中任務負責的檔案由該負責人修改；共享 `App.tsx`、舞台與樣式先記錄交接。不要用旧檔整份覆蓋新改動。
- 做完一段、改變範圍、遇到阻礙或交接時更新自己的任務，附測試／截圖／提交證據，不代替對方宣告開始或完成。
- 提交只 stage 自己確認的改動，不用 `git add .`／`git add -A` 混入 Codex 的工作。
- Codex 已完成 DOS 原作構圖的 3D 起始選單，詳見 `docs/TITLE_MENU.md` 與 `TASKS.md` 的 MENU-001；正式流程應接上既有選單。

## 指令
```bash
npm run dev          # http://localhost:5173（?stress 3對3、?perf 幀率、?scene=battle 直跳戰鬥）
npm run typecheck
npm test             # vitest：core/ 規則與 content/ 資料檢查
node tools/capture.mjs <輸出資料夾> [網址參數]   # headless 截圖＋效能（要先開 dev server）
node tools/playthrough.mjs <輸出資料夾> [步數] [寬x高] [網址參數]   # 真瀏覽器試玩正式流程，每種畫面截圖、記錄錯誤
#   例：node tools/playthrough.mjs capture_out/m 60 844x390          手機橫向
#   例：node tools/playthrough.mjs capture_out/b 6 1280x720 dev=3:c3_bloodpool   直接跳到第三章血池
BOT_SEEDS=8 npx vitest run tests/bot/seeds.test.ts   # 多種子自動通關（平衡調整後跑）
npm run fonts          # 劇本／介面文字改了要重跑：重新裁切自帶字型
npm run android:build  # Android debug APK（android/app/build/outputs/apk/debug/）
python tools/art/make_assets.py && python tools/art/build_jobs.py   # 產生出圖工作；python tools/art/run_jobs.py tools/art/jobs/<組>.json 出圖
```
開發網址 `?dev=<章>` 或 `?dev=<章>:<節點id>`：用 bot 依正式規則打到該章／該場（只在 dev server 有效）。
內建瀏覽器 pane 在對話視窗沒開時只跑 1 fps——驗證畫面一律用 `tools/capture.mjs`。

## 架構（REDESIGN §7.2）
```
src/core/      純邏輯：戰鬥 reducer、效果、敵人意圖、種子亂數、行程(run)狀態。不碰 DOM／Three.js
src/content/   卡牌、角色、敵人、章節、劇本（TS 資料＋zod 驗證）
src/ui/        React 畫面（標題、地圖、劇情、戰鬥 HUD、獎勵、客棧、設定）
src/stage/     3D 戰鬥舞台（R3F）：只訂閱 core 事件播演出，不改狀態
src/platform/  存檔（localStorage）、音訊（WebAudio 程序化）、Android 返回鍵
src/game/      遊戲狀態（store：唯一狀態來源＋自動存檔）、設定、開發用跳關
tests/         vitest（core 規則、content 資料檢查、bot 自動通關）
tools/         美術管線（blender/、art/）、capture.mjs、playthrough.mjs、字型裁切、Android 建置
```
- 狀態只透過 `core` 的 reducer 改；畫面只讀。
- 卡面文字由效果自動產生（`core/describe.ts`），不手寫，避免文字和行為不符。
- 程式檔超過 400 行就拆（資料檔不限）。

## 美術
- 畫風：B 國風厚塗。出圖：SwordCard repo 的 `tools/comfyui/zimage_txt2img.py`（先用 `launch_without_av.py` 開 ComfyUI）。
- 3D：只有可操作角色（逍遙、靈兒、月如、阿奴、巫后）與少數人形敵人；其餘敵人用 2D 立繪（Billboard）。
  管線：設定表 → `tools/art/pad_views.py` → Hunyuan3D（SwordCard `tools/comfyui/hunyuan3d_mv.py`）→ `tools/blender/build_character.py <rig.json>`。
- 戰鬥背景是**俯視地面**（無天空），構圖照仙劍一 DOS 版（REDESIGN §6.5）。
- 使用者有時會請 Codex 加美術或戰術資源：看到不是自己產生的檔案，照用、不要刪。

## Git
- main 直接 commit；conventional commits；commit 前 `git status` 看有沒有別人的改動。
- 結尾署名：`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`

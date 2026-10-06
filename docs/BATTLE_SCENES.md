# 戰場交付介面 — SCENE-001A

2026-10-05，Codex 交付給 Claude Code。分工與場景清單見 [TASKS.md](../TASKS.md)。這一批提供整合介面，不表示 23 個場景美術已完成。

## 正式戰鬥的接法

```tsx
import { BattleStage } from "../stage/BattleStage";

<BattleStage
  sceneId={encounter.sceneId}
  actors={actors}
  focus={focus}
  popups={popups}
  active={screen === "battle"}
/>
```

`sceneId` 用交付規格 B 的固定 ID。現在只有 `shilipo` 有已交付的地面圖。未交付的已知 ID（例如 `yuhang_inn`）和未知 ID 都使用現成十里坡，不會先請求不存在的圖片再報錯。

原型的 `backdropUrl`、`backdropLayout` 接法仍有效；明確傳入的參數優先於 sceneId 的預設。鏡頭、站位、角色動畫、主光、陰影和後製都保持既有設定。

## 查表與交付狀態

```ts
import { listBattleScenes, resolveBattleScene } from "../stage/scenes";

const scene = resolveBattleScene("yuhang_inn");
// requestedId: yuhang_inn；renderedId: shilipo；fallbackReason: pending_art
const tasks = listBattleScenes();
// 每筆有 id、name、ready、plannedAssetUrl。
```

`plannedAssetUrl` 是交付檔名，不能直接拿來下載。UI 的劇情／地點名稱仍由內容資料決定，不要把回退背景的 `name` 當成目前節點名稱。

新地面圖確認並交付後，在 `src/stage/scenes/catalog.ts` 的 `PRESENTATIONS` 登記真正存在的 `backdropUrl` 與 `backdropLayout`。不要提前把所有待辦 ID 都標成 ready。這份 catalog 保持純資料，不引入 React、DOM、材質或場景模型。

## 附加 3D 模組

```tsx
import YuhangInnScenery from "../stage/scenes/yuhang_inn";

<BattleStage sceneId="yuhang_inn" scenery={<YuhangInnScenery />} {...battleProps} />
```

上例是**後續已驗收場景的接法示意**，目前 `yuhang_inn.tsx` 還未製作。Codex 之後交付每場 `<sceneId>.tsx` 模組，Claude 可把已交付的模組放進場景查表，依 sceneId 選取並傳進 `scenery`。在圖與模組未交付前不要匯入；也不要在十里坡回退背景上疊其他場景的道具。

模組只提供 R3F 道具／場景效果，不改鏡頭、站位或遊戲狀態，不新增投影燈。美術開始製作前仍需原作遊戲圖的確認；這批介面工作沒有跳過美術關卡。

## 效能檢查

```ts
import { inspectSceneryBudget } from "../stage/scenes";
const report = inspectSceneryBudget(sceneryGroup);
```

只檢查附加道具 group。上限為 20 次繪製呼叫、30,000 三角面。檢查器會計入材質分組、drawRange、instance 數、隱藏父層與材質、雙面透明材質的兩次繪製，以及舞台的一次方向光陰影 pass；粒子有繪製呼叫但沒有三角面。

這是靜態預算上界估算，不是 GPU 計時或完整 renderer.info。實際視錐剔除、後製、角色與額外 pass 仍需以 `tools/capture.mjs` 的全場數據與手機實測確認。

## 驗證指令

```sh
npm run build
npm test
node tools/stage/verify-scene-assets.mjs
node tools/capture.mjs docs/previews/scene-foundation
node tools/stage/capture-mobile.mjs docs/previews/scene-foundation
```

資產檢查會讀同一份 catalog，確認 ready 的背景是 public 內確實存在的 JPEG；不讀另一份手抄清單，也不要求修改 app 的 Node 型別或依賴。

## 本次驗證結果（2026-10-05）

- 10 個場景測試通過；場景／BattleStage 使用專案嚴格 TypeScript 選項做獨立型別檢查通過。
- `verify-scene-assets.mjs` 通過：1 ready、22 pending；使用專案現有的 Node 24 型別移除功能。
- 1280×720 桌機截圖與出牌流程、896×504 橫向手機尺寸截圖皆完成，瀏覽器錯誤 0。原型的角色、站位、背景、血條與出牌演出仍正常。原型手牌下緣會延伸到畫面外，正式 HUD 的排版由 UI-001 整合，這批未更動。
- 截圖與原型全場數據在 [docs/previews/scene-foundation/](previews/scene-foundation/)。桌機該次取樣為 47 draw、90,213 三角面；這不是附加道具預算，也不是手機實測。
- 全套最後一次執行：56 個測試通過，內容 suite 等待 `src/content/index.ts` 而載入失敗；建置另有內容測試的 Node 型別錯誤。詳見 TASKS.md 的 SCENE-001A 交接，請內容負責人完成後重跑全套。

# QA-004 — 3D 戰場生命週期驗收

2026-10-05，Codex，**完成 100%**。14 次往返、資源穩定、隱藏／恢復／畫質切換通過；建置與 89 測試通過（1 跳過），瀏覽器錯誤 0。這批驗證已確認的場景接線與資源管理，不繪製未確認的新場景。

## 重跑

```text
npm run dev -- --port 5175 --strictPort
node tools/stage/lifecycle-qa.mjs
node tools/stage/verify-scene-assets.mjs docs/previews/stage-lifecycle/inventory.json
```

QA HTML 在 tools/stage/，不被 production 的 index.html 引用。使用同一個 BattleStage、同一 Canvas、React StrictMode，手機橫向 844×390 DPR2 touch 操作，但省電渲染 DPR1。場景沒有角色或 HUD，此流程專門隔離場景資源；擁擠正式戰鬥 UI 另見 BLOOD_POOL_3D.md。

FpsMeter 在原本的效能取樣中追加 geometries、textures、programs、frame；沒有啟用效能診斷時不增加取樣器。數值來自 renderer.info，不代表 VRAM 位元組或實體手機效能。

## 驗收條件

- 血池／十里坡 14 次往返，全程保留同一個 Canvas DOM 元素。
- 從第 4 次暖機後，同場景幾何、貼圖、shader program 數不得繼續成長。
- 隱藏後停止持續渲染／效能取樣；恢復後繼續渲染。
- 高／低畫質切換，回省電後 DPR1；瀏覽器錯誤 0。
- JSON 中的 passed 必須為 true，不能把執行開始當成驗收成功。

[實際 JSON](previews/stage-lifecycle/validation.json) 與 [場景盤點](previews/stage-lifecycle/inventory.json)。資產工具現在明確分列 23 張可用圖片與 1/23（4.3%）完整 3D 場景。

此獨立入口只作驗收；正式遊戲仍使用已部署版本，下一批遊戲功能／美術更新時一起包含診斷欄位。新場景原作確認與 Android 實機驗收仍另列 TASKS.md。

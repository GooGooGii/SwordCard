// 原型截圖與效能量測（headless Chromium，用真實 GPU）。
// 用法：先啟動 dev server（npm run dev），再執行
//   node tools/capture.mjs [輸出資料夾] [網址參數，例如 stress]
// 輸出：rest.png（靜止）、attack_XXXms.png（出招過程）、perf.json
import { chromium } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const outDir = process.argv[2] ?? "capture_out";
const query = process.argv[3] ? `?${process.argv[3]}&perf` : "?perf";
const url = `http://localhost:5173/${query}`;
mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch({
  args: ["--use-angle=d3d11", "--enable-gpu", "--ignore-gpu-blocklist", "--enable-unsafe-swiftshader"],
});
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
const errors = [];
page.on("pageerror", (e) => errors.push(String(e)));
page.on("console", (m) => m.type() === "error" && errors.push(m.text()));
await page.goto(url);
// 等模型與貼圖載完：__perf 出現代表 3D 已經開始渲染
await page.waitForFunction(() => window.__perf !== undefined, null, { timeout: 60000 });
await page.waitForTimeout(3000);
await page.screenshot({ path: join(outDir, "rest.png") });
const perfRest = await page.evaluate(() => window.__perf);

// 拖曳第一張卡出牌
const card = page.locator(".card").first();
const box = await card.boundingBox();
if (box) {
  const x = box.x + box.width / 2;
  const y = box.y + box.height * 0.35;
  await page.mouse.move(x, y);
  await page.mouse.down();
  await page.mouse.move(x + 20, y - 90, { steps: 4 });
  await page.mouse.move(x + 30, y - 200, { steps: 6 });
  await page.mouse.up();
  for (const ms of [150, 350, 600]) {
    await page.waitForTimeout(ms === 150 ? 150 : ms - (ms === 350 ? 150 : 350));
    await page.screenshot({ path: join(outDir, `attack_${ms}ms.png`) });
  }
}
await page.waitForTimeout(2500);
const perfAfter = await page.evaluate(() => window.__perf);
writeFileSync(join(outDir, "perf.json"), JSON.stringify({ url, perfRest, perfAfter, errors }, null, 2));
console.log(JSON.stringify({ perfRest, perfAfter, errors: errors.length }, null, 1));
await browser.close();

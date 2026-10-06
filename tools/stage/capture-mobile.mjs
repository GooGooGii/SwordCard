// 橫向手機尺寸的版面截圖；不代表 Android WebView 或手機 GPU 實測。
// 先啟動 npm run dev，再跑 node tools/stage/capture-mobile.mjs [輸出目錄]
import { chromium } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const outDir = process.argv[2] ?? "docs/previews/scene-foundation";
const viewport = { width: 896, height: 504 };
mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch({
  args: ["--use-angle=d3d11", "--enable-gpu", "--ignore-gpu-blocklist", "--enable-unsafe-swiftshader"],
});
try {
  const page = await browser.newPage({ viewport, deviceScaleFactor: 1.5, isMobile: true, hasTouch: true });
  const errors = [];
  page.on("pageerror", (error) => errors.push(String(error)));
  page.on("console", (message) => { if (message.type() === "error") errors.push(message.text()); });
  await page.goto("http://localhost:5173/?perf");
  await page.waitForFunction(() => window.__perf !== undefined, null, { timeout: 60000 });
  await page.waitForTimeout(3000);
  await page.screenshot({ path: join(outDir, "mobile-landscape.png") });
  writeFileSync(join(outDir, "mobile-layout.json"), JSON.stringify({ viewport, deviceScaleFactor: 1.5, errors }, null, 2));
  console.log(JSON.stringify({ viewport, errors }, null, 2));
  if (errors.length) process.exitCode = 1;
} finally {
  await browser.close();
}

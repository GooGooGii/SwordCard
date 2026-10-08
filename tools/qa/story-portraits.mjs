// 劇情頭像檢查：每章從開頭（?dev=章）推進劇情到第一場戰鬥，每出現一張新頭像（含表情）就截圖，
// 記錄頭像載入失敗與瀏覽器錯誤。
// 先 npm run dev，再 node tools/qa/story-portraits.mjs <輸出資料夾> [寬x高] [章,章,...] [每章最多步數]
// 例：node tools/qa/story-portraits.mjs capture_out/sp 1280x720 0,1,2,3,4,5,6,7,8
import { chromium } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const [outDir = "capture_out/story-portraits", size = "1280x720", chapters = "0", maxSteps = "200"] = process.argv.slice(2);
const [width, height] = size.split("x").map(Number);
mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width, height } });
const errors = [];
const broken = new Set();
page.on("pageerror", (e) => errors.push(String(e)));
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()); });
page.on("response", (r) => { if (r.url().includes("/portraits/") && r.status() >= 400) broken.add(r.url()); });

const seen = new Set();
const shots = [];
for (const ch of chapters.split(",")) {
  await page.goto(`http://localhost:5173/?dev=${ch}`);
  await page.locator(".game-root").waitFor({ timeout: 120000 });
  let idle = 0;
  for (let i = 0; i < Number(maxSteps); i++) {
    const srcs = await page.locator("img.story-portrait").evaluateAll((els) => els.map((e) => e.getAttribute("src")));
    for (const src of srcs) {
      if (src && !seen.has(src)) {
        seen.add(src);
        await page.waitForTimeout(450);
        const file = `${String(shots.length + 1).padStart(2, "0")}_c${ch}_${src.split("/").pop().replace(/\.\w+$/, "")}.png`;
        await page.screenshot({ path: join(outDir, file) });
        shots.push(file);
      }
    }
    if (await page.locator(".bt").count()) break; // 到戰鬥就換下一章
    const choice = page.locator(".story-choice-btn").first();
    if (await choice.isVisible().catch(() => false)) { await choice.click(); idle = 0; }
    else if (await page.locator(".story").count()) { await page.locator(".story").click({ position: { x: width / 2, y: height * 0.4 } }); idle = 0; }
    else if (await page.locator(".chapter-intro").count()) await page.locator(".chapter-intro").click();
    else if (await page.locator(".map").count()) await page.locator(".map-node.open").first().click();
    else {
      if (++idle > 12) break;
      const primary = page.locator(".ui-btn.primary").first();
      if (await primary.isVisible().catch(() => false)) await primary.click();
      else await page.mouse.click(width / 2, height / 2);
    }
    await page.waitForTimeout(150);
  }
}
writeFileSync(join(outDir, "report.json"), JSON.stringify({ shots, portraits: [...seen], broken: [...broken], errors }, null, 2));
console.log(JSON.stringify({ shots: shots.length, broken: [...broken], errors: errors.length }));
await browser.close();

// 戰鬥姿勢檢查：進第一場戰鬥，正常動畫速度出一張攻擊牌，在出招過程中連拍，確認主角換成姿勢圖。
// 先 npm run dev，再 node tools/qa/battle-poses.mjs <輸出資料夾> [寬x高] [dev=<章>:<節點>]
import { chromium } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const [outDir = "capture_out/battle-poses", size = "1280x720", query = ""] = process.argv.slice(2);
const [width, height] = size.split("x").map(Number);
mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch({ args: ["--use-angle=d3d11", "--enable-gpu", "--ignore-gpu-blocklist", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage({ viewport: { width, height } });
const errors = [];
const poseRequests = new Set();
page.on("pageerror", (e) => errors.push(String(e)));
page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()); });
page.on("response", (r) => { if (r.url().includes("_pose_")) poseRequests.add(`${r.status()} ${r.url().split("/").pop()}`); });
await page.addInitScript(() => {
  localStorage.setItem("xiaoyao.settings", JSON.stringify({ animSpeed: 1, textSpeed: 0, partyStyle: "2d", artVersion: 2 }));
  for (const k of ["xiaoyao.save.0", "xiaoyao.save.1", "xiaoyao.save.2"]) localStorage.removeItem(k);
});
await page.goto(`http://localhost:5173/${query ? `?${query}` : ""}`);
if (!query) {
  await page.locator(".new-story").click();
  await page.locator(".slot").first().click();
}
await page.locator(".game-root").waitFor({ timeout: 120000 });

// 推進到戰鬥
for (let i = 0; i < 300 && !(await page.locator(".bt-card").count()); i++) {
  if (await page.locator(".bt-tips button").count()) await page.locator(".bt-tips button").click();
  else if (await page.locator(".story-choice-btn").first().isVisible().catch(() => false)) await page.locator(".story-choice-btn").first().click();
  else if (await page.locator(".story").count()) await page.locator(".story").click({ position: { x: width / 2, y: height * 0.4 } });
  else if (await page.locator(".chapter-intro").count()) await page.locator(".chapter-intro").click();
  else if (await page.locator(".map").count()) await page.locator(".map-node.open").first().click();
  await page.waitForTimeout(120);
}
if (await page.locator(".bt-tips button").count()) await page.locator(".bt-tips button").click();
await page.waitForTimeout(1500);
await page.screenshot({ path: join(outDir, "0_idle.png") });

// 出第一張牌：點牌，再點敵人（單一目標）
const card = page.locator(".bt-card:not(.unaffordable)").first();
await card.click();
await page.waitForTimeout(150);
const target = page.locator(".drop-zone.active, .bt-field.active").first();
if (await target.count()) await target.click({ force: true });
else await card.click();
for (const ms of [80, 180, 300, 450, 700]) {
  await page.waitForTimeout(ms === 80 ? 80 : 120);
  await page.screenshot({ path: join(outDir, `1_play_${ms}ms.png`) });
}
writeFileSync(join(outDir, "report.json"), JSON.stringify({ poseRequests: [...poseRequests], errors }, null, 2));
console.log(JSON.stringify({ poseRequests: [...poseRequests], errors: errors.length }));
await browser.close();

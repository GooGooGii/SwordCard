// 使用正式血池戰鬥與 HUD 驗收候選；先 npm run dev，再執行本檔。
// 模擬手機版面，不代表 Android WebView 實機效能驗收。
import { chromium } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { bloodPoolFixture } from "./blood-pool-fixture.mjs";

const outDir = process.argv[2] ?? "docs/previews/blood-pool";
mkdirSync(outDir, { recursive: true });
const fixture = await bloodPoolFixture();
writeFileSync(join(outDir, "fixture.json"), JSON.stringify(fixture.report, null, 2));
const browser = await chromium.launch({
  args: ["--use-angle=d3d11", "--enable-gpu", "--ignore-gpu-blocklist", "--enable-unsafe-swiftshader"],
});
const results = [];
try {
  for (const [name, width, height, quality] of [
    ["desktop", 1280, 720, "high"],
    ["mobile", 844, 390, "high"],
    ["mobile-low", 844, 390, "low"],
    ["desktop-crowded", 1280, 720, "high"],
    ["mobile-crowded", 844, 390, "high"],
  ]) {
    const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: width < 1000 ? 2 : 1, hasTouch: width < 1000 });
    const errors = [];
    page.on("pageerror", (error) => errors.push(String(error)));
    page.on("console", (message) => { if (message.type() === "error") errors.push(message.text()); });
    const crowded = name.includes("crowded");
    await page.addInitScript(({ quality, save }) => {
      localStorage.setItem("xiaoyao.settings", JSON.stringify({ animSpeed: 1, textSpeed: 0, quality, partyStyle: "3d", music: 0, sfx: 0 }));
      if (save) localStorage.setItem("xiaoyao.save.2", save);
    }, { quality, save: crowded ? fixture.save : null });
    const url = `http://localhost:5173/?${crowded ? "" : "dev=3:c3_bloodpool&"}scenery=blood_pool&scenePerf`;
    await page.goto(url);
    if (crowded) {
      await page.getByRole("button", { name: "舊的回憶", exact: true }).click({ timeout: 60000 });
      await page.locator(".slot").nth(2).click();
    }
    await page.locator(".bt").waitFor({ state: "visible", timeout: 60000 });
    await page.waitForFunction(() => window.__perf !== undefined, null, { timeout: 60000 });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(3500);
    await page.screenshot({ path: join(outDir, `${name}.jpg`), type: "jpeg", quality: 92 });
    const perfRest = await page.evaluate(() => window.__perf);
    const layout = await page.evaluate(() => {
      const selectors = [".bt-intent", ".bt-field", ".hp", ".actor-name", ".bt-end", ".bt-card"];
      const outside = [];
      for (const selector of selectors) for (const el of document.querySelectorAll(selector)) {
        const r = el.getBoundingClientRect();
        if (r.width > 0 && r.height > 0 && (r.x < -1 || r.y < -1 || r.right > innerWidth + 1 || r.bottom > innerHeight + 1)) {
          outside.push({ selector, text: el.textContent?.trim().slice(0, 60), x: Math.round(r.x), y: Math.round(r.y), right: Math.round(r.right), bottom: Math.round(r.bottom) });
        }
      }
      // 手牌扇形底部刻意伸出螢幕；另外列出，不當成場景造成的 HUD 錯誤。
      return { hudOutside: outside.filter((e) => e.selector !== ".bt-card"), handOutside: outside.filter((e) => e.selector === ".bt-card"), candidate: document.querySelector("[data-scene-candidate]")?.getAttribute("data-scene-candidate") };
    });
    // 經 UI 點牌／選敵出牌，驗證候選沒有阻擋正式戰鬥的落點。
    const before = await page.locator(".bt-card").count();
    const playable = page.locator(".bt-card:not(.unaffordable)").first();
    await playable.click();
    await page.waitForTimeout(100);
    if (await page.locator(".bt.targeting-enemy, .bt.targeting-party").count()) {
      await page.locator(".drop-zone.active, .bt-field.active").first().click({ force: true });
    } else {
      await playable.click();
    }
    await page.waitForTimeout(350);
    await page.screenshot({ path: join(outDir, `${name}-action.jpg`), type: "jpeg", quality: 90 });
    await page.waitForTimeout(2400);
    const after = await page.locator(".bt-card").count();
    const perfAfter = await page.evaluate(() => window.__perf);
    const passed = errors.length === 0 && layout.hudOutside.length === 0 && layout.candidate === "blood_pool" && after < before;
    results.push({ name, viewport: { width, height }, quality, url, fixture: crowded ? fixture.report : null, perfRest, perfAfter, layout, playedCard: after < before, errors, passed });
    console.log(JSON.stringify(results.at(-1)));
    if (!passed) process.exitCode = 1;
    await page.close();
  }
} finally {
  writeFileSync(join(outDir, "validation.json"), JSON.stringify(results, null, 2));
  await browser.close();
}

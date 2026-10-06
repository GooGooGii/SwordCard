// 手機擁擠 UI 補驗：三張藥品長按可讀、放開不出牌，再點選金創藥治療隊友。
import { chromium } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { bloodPoolFixture } from "./blood-pool-fixture.mjs";

const outDir = process.argv[2] ?? "docs/previews/blood-pool";
mkdirSync(outDir, { recursive: true });
const fixture = await bloodPoolFixture();
const browser = await chromium.launch({ args: ["--use-angle=d3d11", "--enable-gpu", "--ignore-gpu-blocklist", "--enable-unsafe-swiftshader"] });
const errors = [];
const checks = [];
let result;
try {
  const page = await browser.newPage({ viewport: { width: 844, height: 390 }, deviceScaleFactor: 2, hasTouch: true });
  page.on("pageerror", (e) => errors.push(String(e)));
  page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()); });
  await page.addInitScript((save) => {
    localStorage.setItem("xiaoyao.settings", JSON.stringify({ animSpeed: 1, quality: "high", music: 0, sfx: 0 }));
    localStorage.setItem("xiaoyao.save.2", save);
  }, fixture.save);
  await page.goto("http://localhost:5173/?scenery=blood_pool&scenePerf");
  await page.getByRole("button", { name: "舊的回憶", exact: true }).click();
  await page.locator(".slot").nth(2).click();
  await page.waitForFunction(() => window.__perf !== undefined, null, { timeout: 60000 });
  await page.waitForTimeout(2000);
  const count = await page.locator(".bt-card").count();
  for (const [i, name] of fixture.report.medicines.entries()) {
    const card = page.locator(".bt-card").filter({ hasText: name });
    const box = await card.boundingBox();
    if (!box) throw new Error(`missing medicine ${name}`);
    const x = box.x + box.width * .45, y = box.y + 20;
    await page.mouse.move(x, y);
    await page.mouse.down();
    await page.locator(".bt-peek").waitFor({ state: "visible" });
    const preview = await page.locator(".bt-peek").boundingBox();
    const text = await page.locator(".bt-peek").innerText();
    const inside = preview.x >= 0 && preview.y >= 0 && preview.x + preview.width <= 844 && preview.y + preview.height <= 390;
    await page.screenshot({ path: join(outDir, `mobile-medicine-${i + 1}.jpg`), type: "jpeg", quality: 92 });
    await page.mouse.up();
    await page.locator(".bt-peek").waitFor({ state: "hidden" });
    const unchanged = (await page.locator(".bt-card").count()) === count;
    checks.push({ name, text, inside, releaseDidNotPlay: unchanged, passed: inside && text.includes(name) && unchanged });
  }
  const hpBefore = await page.locator(".hp-text").allTextContents();
  // 點可見卡圖，避免 locator 自動捲到扇形卡牌被刻意裁掉的下半部。
  const medicineBox = await page.locator(".bt-card").filter({ hasText: "金創藥" }).boundingBox();
  await page.mouse.click(medicineBox.x + medicineBox.width * .45, medicineBox.y + 20);
  await page.locator(".drop-zone.active").first().click({ force: true });
  await page.waitForTimeout(2000);
  const hpAfter = await page.locator(".hp-text").allTextContents();
  const consumed = (await page.locator(".bt-card").count()) === count - 1;
  const healed = hpBefore.some((text, i) => Number(hpAfter[i]?.split("/")[0]) > Number(text.split("/")[0]));
  const hudStayedVisible = await page.evaluate(() => [".bt-turn", ".bt-top-right", ".bt-end", ".bt-intent", ".hp"].every((selector) =>
    [...document.querySelectorAll(selector)].every((el) => {
      const r = el.getBoundingClientRect();
      return r.x >= 0 && r.y >= 0 && r.right <= innerWidth && r.bottom <= innerHeight;
    })));
  await page.screenshot({ path: join(outDir, "mobile-medicine-used.jpg"), type: "jpeg", quality: 92 });
  result = { viewport: { width: 844, height: 390 }, fixture: fixture.report, checks, hpBefore, hpAfter, consumed, healed, hudStayedVisible, errors, passed: checks.every((c) => c.passed) && consumed && healed && hudStayedVisible && errors.length === 0 };
  if (!result.passed) process.exitCode = 1;
  console.log(JSON.stringify(result));
} finally {
  if (result) writeFileSync(join(outDir, "medicine-validation.json"), JSON.stringify(result, null, 2));
  await browser.close();
}

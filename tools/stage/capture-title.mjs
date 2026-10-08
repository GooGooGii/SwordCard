// 起始選單截圖：等背景圖與字型載入完成再截。
// 先 npm run dev，再 node tools/stage/capture-title.mjs
import { chromium } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { join } from "node:path";

const outDir = process.argv[2] ?? "docs/previews";
mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch({
  args: ["--use-angle=d3d11", "--enable-gpu", "--ignore-gpu-blocklist", "--enable-unsafe-swiftshader"],
});
try {
  for (const [name, viewport] of [
    ["desktop", { width: 1280, height: 720 }],
    ["mobile", { width: 844, height: 390 }],
    ["portrait", { width: 390, height: 727 }],
    ["portrait-tall", { width: 360, height: 800 }],
  ]) {
    const page = await browser.newPage({ viewport, hasTouch: name !== "desktop" });
    const errors = [];
    page.on("pageerror", (error) => errors.push(String(error)));
    page.on("console", (message) => { if (message.type() === "error") errors.push(message.text()); });
    await page.goto(process.env.TITLE_QA_URL ?? "http://localhost:5173/");
    const skip = page.getByRole("button", { name: "先繼續查看" });
    if (await skip.isVisible()) await skip.click();
    await page.locator(".title-cine-bg").waitFor({ state: "visible", timeout: 60000 });
    await page.waitForFunction(() => document.querySelector(".title-cine-bg")?.complete, null, { timeout: 60000 });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(3000);
    await page.screenshot({ path: join(outDir, `title-menu-${name}.jpg`), type: "jpeg", quality: 90 });
    if (name === "portrait") {
      await page.setViewportSize({ width: 844, height: 390 });
      await page.waitForTimeout(1000);
      await page.screenshot({ path: join(outDir, "title-menu-rotated.jpg"), type: "jpeg", quality: 90 });
      await page.setViewportSize(viewport);
      await page.waitForTimeout(1000);
      if (await skip.isVisible()) await skip.click();
      await page.screenshot({ path: join(outDir, "title-menu-rotated-back.jpg"), type: "jpeg", quality: 90 });
    }
    console.log(JSON.stringify({ name, viewport, errors }));
    if (errors.length) process.exitCode = 1;
    await page.close();
  }
} finally {
  await browser.close();
}

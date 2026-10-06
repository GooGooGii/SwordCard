// 赤鬼王原作候選：正式血池戰鬥、多件法寶與三張藥品卡的擁擠 UI。
// 使用既有瀏覽器測試工具；不寫入使用者的瀏覽器存檔。
import { chromium } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { bloodPoolFixture } from "./blood-pool-fixture.mjs";

const outDir = process.argv[2] ?? "docs/previews/red-ghost-king";
mkdirSync(outDir, { recursive: true });
const fixture = await bloodPoolFixture();
writeFileSync(join(outDir, "fixture.json"), JSON.stringify(fixture.report, null, 2));
const browser = await chromium.launch({ args: ["--use-angle=d3d11", "--enable-gpu", "--ignore-gpu-blocklist", "--enable-unsafe-swiftshader"] });
const results = [];
try {
  for (const [name, width, height, quality, candidate] of [
    ["before-desktop", 1280, 720, "high", false],
    ["desktop", 1280, 720, "high", true],
    ["mobile", 844, 390, "high", true],
    ["mobile-low", 844, 390, "low", true],
  ]) {
    const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: width < 1000 ? 2 : 1, hasTouch: width < 1000 });
    const errors = [], candidateResponses = [];
    page.on("pageerror", (e) => errors.push(String(e)));
    page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()); });
    page.on("response", (response) => {
      if (response.url().includes("/enemies/candidates/")) candidateResponses.push({ url: response.url(), status: response.status() });
    });
    await page.addInitScript(({ save, quality }) => {
      localStorage.setItem("xiaoyao.settings", JSON.stringify({ animSpeed: 1, textSpeed: 0, quality, partyStyle: "3d", music: 0, sfx: 0 }));
      localStorage.setItem("xiaoyao.save.2", save);
    }, { save: fixture.save, quality });
    const url = `http://localhost:5173/?scenery=blood_pool&scenePerf${candidate ? "&bossArt=red_ghost_king_dos" : ""}`;
    await page.goto(url);
    await page.getByRole("button", { name: "舊的回憶", exact: true }).click({ timeout: 60000 });
    await page.locator(".slot").nth(2).click();
    await page.locator(".bt").waitFor({ state: "visible", timeout: 60000 });
    await page.waitForFunction(() => window.__perf !== undefined, null, { timeout: 60000 });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(3000);
    await page.screenshot({ path: join(outDir, `${name}.jpg`), type: "jpeg", quality: 94 });
    const perf = await page.evaluate(() => window.__perf);
    const layout = await page.evaluate(() => {
      const hudOutside = [];
      for (const selector of [".bt-intent", ".hp", ".actor-name", ".bt-turn", ".bt-top-right", ".bt-end"]) {
        for (const el of document.querySelectorAll(selector)) {
          const r = el.getBoundingClientRect();
          if (r.width && r.height && (r.x < -1 || r.y < -1 || r.right > innerWidth + 1 || r.bottom > innerHeight + 1))
            hudOutside.push({ selector, text: el.textContent?.trim(), rect: r.toJSON() });
        }
      }
      const bossFoot = [...document.querySelectorAll(".actor-name")].find((el) => el.textContent === "赤鬼王")?.closest(".anchor-foot")?.getBoundingClientRect();
      const intent = document.querySelector(".bt-intent")?.getBoundingClientRect();
      const intentLeftOfBody = bossFoot && intent ? intent.right < bossFoot.x + bossFoot.width / 2 - 10 : false;
      return { hudOutside, intentLeftOfBody, scenery: document.querySelector("[data-scene-candidate]")?.getAttribute("data-scene-candidate"), bossArt: document.querySelector("[data-boss-art-candidate]")?.getAttribute("data-boss-art-candidate") ?? null };
    });
    const before = await page.locator(".bt-card").count();
    const medicineChecks = [];
    if (name === "mobile") {
      for (const [i, medicine] of fixture.report.medicines.entries()) {
        const card = page.locator(".bt-card").filter({ hasText: medicine });
        const box = await card.boundingBox();
        if (!box) throw new Error(`Missing ${medicine}`);
        await page.mouse.move(box.x + box.width * .45, box.y + 20);
        await page.mouse.down();
        await page.locator(".bt-peek").waitFor({ state: "visible" });
        const preview = await page.locator(".bt-peek").boundingBox();
        const text = await page.locator(".bt-peek").innerText();
        const inside = preview && preview.x >= 0 && preview.y >= 0 && preview.x + preview.width <= width && preview.y + preview.height <= height;
        await page.screenshot({ path: join(outDir, `mobile-medicine-${i + 1}.jpg`), type: "jpeg", quality: 92 });
        await page.mouse.up();
        await page.locator(".bt-peek").waitFor({ state: "hidden" });
        medicineChecks.push({ medicine, text, inside, releaseDidNotPlay: (await page.locator(".bt-card").count()) === before });
      }
    }
    // 真正經 UI 使用藥品：點金創藥、選隊友，不直接改遊戲 state。
    const hpBefore = await page.locator(".hp-text").allTextContents();
    const medicineBox = await page.locator(".bt-card").filter({ hasText: "金創藥" }).boundingBox();
    if (!medicineBox) throw new Error("Missing 金創藥");
    await page.mouse.click(medicineBox.x + medicineBox.width * .45, medicineBox.y + 20);
    await page.locator(".drop-zone.active").first().click({ force: true });
    await page.waitForTimeout(2200);
    const hpAfter = await page.locator(".hp-text").allTextContents();
    const consumed = (await page.locator(".bt-card").count()) === before - 1;
    const healed = hpBefore.some((text, i) => Number(hpAfter[i]?.split("/")[0]) > Number(text.split("/")[0]));
    await page.screenshot({ path: join(outDir, `${name}-medicine-used.jpg`), type: "jpeg", quality: 92 });
    // 候選調整了角色／落點錨點，需實際選 Boss 出牌，驗證目標與受擊演出。
    const attackBox = await page.locator(".bt-card:not(.unaffordable)").filter({ hasText: "雙鞭連擊" }).first().boundingBox();
    if (!attackBox) throw new Error("Missing playable 雙鞭連擊");
    await page.mouse.click(attackBox.x + attackBox.width * .45, attackBox.y + 20);
    await page.locator(".drop-zone.active").first().click({ force: true });
    await page.waitForTimeout(350);
    await page.screenshot({ path: join(outDir, `${name}-attack.jpg`), type: "jpeg", quality: 92 });
    await page.waitForTimeout(3200);
    const hpAfterAttack = await page.locator(".hp-text").allTextContents();
    const damagedBoss = Number(hpAfterAttack.at(-1)?.split("/")[0]) < Number(hpAfter.at(-1)?.split("/")[0]);
    const loaded = candidate ? candidateResponses.some((r) => r.status === 200) : candidateResponses.length === 0;
    const passed = errors.length === 0 && layout.hudOutside.length === 0 && layout.scenery === "blood_pool"
      && layout.bossArt === (candidate ? "red_ghost_king_dos" : null) && (!candidate || layout.intentLeftOfBody) && loaded && consumed && healed && damagedBoss
      && medicineChecks.every((m) => m.inside && m.releaseDidNotPlay && m.text.includes(m.medicine));
    results.push({ name, viewport: { width, height }, quality, url, fixture: fixture.report, candidateResponses, layout, perf, medicineChecks, hpBefore, hpAfter, hpAfterAttack, consumed, healed, damagedBoss, errors, passed });
    console.log(JSON.stringify(results.at(-1)));
    if (!passed) process.exitCode = 1;
    await page.close();
  }
} finally {
  writeFileSync(join(outDir, "validation.json"), JSON.stringify(results, null, 2));
  await browser.close();
}

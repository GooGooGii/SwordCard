// 唯一目標快出（FEEL-003）實機檢查：序章第一戰（兩隻草妖）
// 1. 兩隻都在：同一張攻擊牌點兩下 → 不出牌（要自己選目標）
// 2. 打倒一隻後：點兩下 → 直接打剩下那隻
// 先 npm run dev，再 node tools/qa/quick-play.mjs [輸出資料夾] [寬x高]
import { chromium } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const [outDir = "capture_out/quick-play", size = "1280x720"] = process.argv.slice(2);
const [width, height] = size.split("x").map(Number);
mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch({ args: ["--use-angle=d3d11", "--enable-gpu", "--ignore-gpu-blocklist", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage({ viewport: { width, height } });
const errors = [];
page.on("pageerror", (e) => errors.push(String(e)));
await page.addInitScript(() => {
  localStorage.setItem("xiaoyao.settings", JSON.stringify({ animSpeed: 0, textSpeed: 0, partyStyle: "2d", artVersion: 2 }));
  for (const k of ["xiaoyao.save.0", "xiaoyao.save.1", "xiaoyao.save.2"]) localStorage.removeItem(k);
});
await page.goto("http://localhost:5173/");
await page.locator(".new-story").click();
await page.locator(".slot").first().click();
for (let i = 0; i < 300 && !(await page.locator(".bt-card").count()); i++) {
  if (await page.locator(".story-choice-btn").first().isVisible().catch(() => false)) await page.locator(".story-choice-btn").first().click();
  else if (await page.locator(".story").count()) await page.locator(".story").click({ position: { x: width / 2, y: height * 0.4 } });
  else if (await page.locator(".chapter-intro").count()) await page.locator(".chapter-intro").click();
  else if (await page.locator(".map").count()) await page.locator(".map-node.open").first().click();
  await page.waitForTimeout(100);
}
if (await page.locator(".bt-tips button").count()) await page.locator(".bt-tips button").click();
await page.waitForTimeout(800);

const handCount = () => page.locator(".bt-card").count();
const enemyHp = () => page.locator("[data-target^='enemy']").count();
const attackCard = async () => {
  const cards = page.locator(".bt-card:not(.unaffordable)");
  for (let i = 0; i < (await cards.count()); i++) if ((await cards.nth(i).innerText()).includes("攻擊")) return cards.nth(i);
  return null;
};
const result = {};

// 1. 兩個目標：點兩下不出牌
let card = await attackCard();
let before = await handCount();
await card.click();
await page.waitForTimeout(150);
await card.click();
await page.waitForTimeout(400);
result.twoTargets = { enemies: await enemyHp(), handBefore: before, handAfter: await handCount() };
await page.keyboard.press("Escape");

// 打倒第一隻：選牌 → 點 enemy:0，直到它消失或手牌打完（每回合結束換手牌）
for (let turn = 0; turn < 6 && (await enemyHp()) > 1; turn++) {
  for (let k = 0; k < 6 && (await enemyHp()) > 1; k++) {
    card = await attackCard();
    if (!card) break;
    await card.click();
    await page.waitForTimeout(120);
    const t = page.locator("[data-target='enemy:0']");
    if (!(await t.count())) break;
    await t.first().click({ force: true });
    await page.waitForTimeout(500);
  }
  if ((await enemyHp()) > 1 && (await page.locator(".bt-end").isEnabled())) {
    await page.locator(".bt-end").click();
    await page.waitForTimeout(1500);
  }
}

// 2. 只剩一個目標：點兩下直接打出
card = await attackCard();
before = await handCount();
if (card) {
  await card.click();
  await page.waitForTimeout(150);
  await card.click();
  await page.waitForTimeout(600);
}
await page.screenshot({ path: join(outDir, "after-quick-play.png") });
result.oneTarget = { enemies: await enemyHp(), handBefore: before, handAfter: await handCount(), hadCard: !!card };
result.errors = errors;
writeFileSync(join(outDir, "report.json"), JSON.stringify(result, null, 2));
console.log(JSON.stringify(result));
await browser.close();

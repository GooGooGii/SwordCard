// 正式流程的 headless 試玩（UI-001 驗收）：開新故事 → 章節 → 地圖 → 劇情 → 戰鬥 → 獎勵 → 客棧…
// 用法：先 npm run dev，再執行
//   node tools/playthrough.mjs [輸出資料夾] [最多幾個畫面]
// 戰鬥用最單純的打法（能打就打第一張、打第一個敵人），只為了驗證流程走得通、畫面沒有錯誤。
import { chromium } from "@playwright/test";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const outDir = process.argv[2] ?? "capture_out/playthrough";
const maxSteps = Number(process.argv[3] ?? 400);
// 第三個參數：視窗大小，例如 844x390（手機橫向）
const [vw, vh] = (process.argv[4] ?? "1280x720").split("x").map(Number);
mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch({ args: ["--use-angle=d3d11", "--enable-gpu", "--ignore-gpu-blocklist", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage({ viewport: { width: vw, height: vh }, deviceScaleFactor: vw < 1000 ? 2 : 1, hasTouch: vw < 1000 });
const errors = [];
page.on("pageerror", (e) => errors.push(String(e)));
page.on("console", (m) => m.type() === "error" && errors.push(m.text()));
// 動畫略過、文字立即顯示，加快試玩
// 環境變數 PARTY_STYLE=2d：主角改用 2D 立繪
await page.addInitScript((partyStyle) => {
  localStorage.setItem("xiaoyao.settings", JSON.stringify({ animSpeed: 0, textSpeed: 0, partyStyle }));
  for (const k of ["xiaoyao.save.0", "xiaoyao.save.1", "xiaoyao.save.2"]) localStorage.removeItem(k);
}, process.env.PARTY_STYLE ?? "3d");
// 第四個參數：網址參數，例如 dev=6（開發用，直接跳到第六章）
const query = process.argv[5] ?? "";
await page.goto(`http://localhost:5173/${query ? `?${query}` : ""}`);

const shots = new Map();
const shot = async (name) => {
  const n = (shots.get(name) ?? 0) + 1;
  shots.set(name, n);
  if (n <= 2) await page.screenshot({ path: join(outDir, `${String(shots.size).padStart(2, "0")}_${name}${n > 1 ? "_2" : ""}.png`) });
};

if (!query.includes("dev=")) {
  await page.locator(".new-story").click({ timeout: 30000 });
  await page.locator(".slot").first().click();
} else {
  await page.locator(".game-root").waitFor({ timeout: 60000 });
}
await page.waitForTimeout(800);

const log = [];
let battles = 0;
// 戰鬥剛結束時按鈕會停用：點不到就略過，下一輪會看到結算畫面
const endTurn = async () => {
  const btn = page.locator(".bt-end");
  if ((await btn.count()) && (await btn.isEnabled())) await btn.click({ timeout: 3000 }).catch(() => {});
};
for (let step = 0; step < maxSteps; step++) {
  await page.waitForTimeout(120);
  if (await page.locator(".chapter-intro").count()) {
    const title = await page.locator(".chapter-intro h1").innerText();
    log.push(`章節：${title}`);
    await shot("chapter");
    await page.locator(".chapter-intro").click();
    continue;
  }
  if (await page.locator(".map").count()) {
    await shot("map");
    const open = page.locator(".map-node.open");
    if (!(await open.count())) {
      log.push("地圖：沒有可走的節點");
      break;
    }
    log.push(`地圖 → ${await open.first().innerText()}`);
    await open.first().click();
    continue;
  }
  if (await page.locator(".story").count()) {
    await shot("story");
    const choice = page.locator(".story-choice-btn");
    if (await choice.count()) await choice.first().click();
    else await page.locator(".story").click({ position: { x: 640, y: 300 } });
    continue;
  }
  if (await page.locator(".bt").count()) {
    if (await page.locator(".bt-result").count()) {
      await shot("battle_result");
      log.push(`戰鬥結束：${await page.locator(".bt-result h2").innerText()}`);
      battles++;
      await page.locator(".bt-result button").click();
      continue;
    }
    await page.waitForTimeout(400);
    if (await page.locator(".bt-tips").count()) {
      await shot("tips");
      await page.locator(".bt-tips button").click();
    }
    await shot("battle");
    // 找一張打得出去的牌：點選它，需要目標就點第一個亮起來的目標
    const cards = page.locator(".bt-card:not(.unaffordable)");
    if (await cards.count()) {
      await cards.first().click();
      await page.waitForTimeout(80);
      const targeting = await page.locator(".bt.targeting-enemy, .bt.targeting-party").count();
      if (targeting) {
        const zone = page.locator(".drop-zone.active, .bt-field.active").first();
        if (await zone.count()) await zone.click({ force: true });
        else await page.keyboard.press("Escape");
      } else {
        await cards.first().click();
      }
      await page.waitForTimeout(150);
      // 點了沒出牌（例如目標不合法）：結束回合避免卡住
      const still = await page.locator(".bt-card.selected").count();
      if (still) {
        await page.keyboard.press("Escape");
        await endTurn();
      }
    } else {
      await endTurn();
    }
    continue;
  }
  if (await page.locator(".rw").count()) {
    await shot("reward");
    const groups = page.locator(".rw-group");
    for (let g = 0; g < (await groups.count()); g++) await groups.nth(g).locator(".rw-card").first().click();
    await page.locator(".rw-confirm").click();
    continue;
  }
  if (await page.locator(".inn").count()) {
    await shot("inn");
    const restBtn = page.locator(".inn-actions .ui-btn.primary");
    if (await restBtn.isEnabled()) await restBtn.click();
    await page.locator(".inn-leave").click();
    log.push("客棧");
    continue;
  }
  if (await page.locator(".lost").count()) {
    await shot("lost");
    log.push("戰敗 → 重來");
    const buttons = page.locator(".lost-actions button");
    await buttons.nth((await buttons.count()) - 1).click();
    continue;
  }
  if (await page.locator(".ending").count()) {
    await shot("ending");
    log.push("結局");
    break;
  }
  await page.waitForTimeout(500);
}

writeFileSync(join(outDir, "log.json"), JSON.stringify({ battles, log, errors }, null, 2));
console.log(JSON.stringify({ battles, steps: log.length, errors: errors.slice(0, 10), last: log.slice(-6) }, null, 1));
await browser.close();

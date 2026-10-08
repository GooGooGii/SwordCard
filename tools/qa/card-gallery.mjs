// 卡牌總覽（CARD-001）：用正式的 CardFace 與 ui.css 把每張牌畫成一頁（含升級版），截圖檢查卡圖與牌面。
// 先 npm run dev，再 node tools/qa/card-gallery.mjs [輸出資料夾] [owner 篩選，例如 li_xiaoyao／none]
// 產出 <輸出資料夾>/gallery-<n>.png（每頁 24 張）與 report.json（缺圖、載入錯誤）
import { chromium } from "@playwright/test";
import { createServer } from "vite";
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const [outDir = "capture_out/card-gallery", owner = ""] = process.argv.slice(2);
mkdirSync(outDir, { recursive: true });

// 1. 用 Vite SSR 把牌面渲染成 HTML（正式元件、正式文字）
const vite = await createServer({ server: { middlewareMode: true, hmr: false }, appType: "custom", logLevel: "error" });
let html;
let ids;
try {
  const { GAME_DB } = await vite.ssrLoadModule("/src/content/index.ts");
  const { CardFace } = await vite.ssrLoadModule("/src/ui/common/CardFace.tsx");
  const cards = Object.values(GAME_DB.cards).filter((c) => !owner || (c.owner ?? "none") === owner);
  ids = cards.map((c) => c.id);
  const faces = cards.flatMap((c) => {
    const one = (upgraded) =>
      `<figure>${renderToStaticMarkup(React.createElement(CardFace, { def: upgraded && c.upgrade ? { ...c, ...c.upgrade } : c, upgraded }))}<figcaption>${c.id}${upgraded ? "＋" : ""}</figcaption></figure>`;
    return c.upgrade ? [one(false), one(true)] : [one(false)];
  });
  html = faces;
} finally {
  await vite.close();
}

// 2. 交給正在跑的 dev server 的頁面套正式樣式（字型、CSS 變數都一樣）
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1600, height: 1000 } });
const broken = new Set();
page.on("response", (r) => { if (r.url().includes("/assets/cards/") && r.status() >= 400) broken.add(r.url().split("/").pop()); });
await page.goto("http://localhost:5173/");
await page.waitForLoadState("networkidle");
// ui.css 平常是進遊戲畫面才載入：這裡直接透過 Vite 匯入（會注入 <style>）
await page.evaluate(() => import("/src/ui/ui.css"));
await page.evaluate(() => document.fonts.ready);
const PER = 24;
let pages = 0;
for (let i = 0; i < html.length; i += PER) {
  await page.evaluate((chunk) => {
    document.body.innerHTML = `<div class="game-root" style="position:static;padding:16px;background:#0c0a07;display:grid;grid-template-columns:repeat(8,auto);gap:14px 12px;justify-content:start">${chunk.join("")}</div>`;
    const style = document.createElement("style");
    style.textContent = "figure{margin:0}figcaption{color:#9a8a6a;font:11px monospace;text-align:center;margin-top:3px}";
    document.body.append(style);
  }, html.slice(i, i + PER));
  await page.waitForTimeout(900);
  pages++;
  await page.screenshot({ path: join(outDir, `gallery-${pages}.png`), fullPage: true });
}
writeFileSync(join(outDir, "report.json"), JSON.stringify({ cards: ids.length, faces: html.length, pages, brokenArt: [...broken] }, null, 2));
console.log(JSON.stringify({ cards: ids.length, faces: html.length, pages, brokenArt: [...broken] }));
await browser.close();

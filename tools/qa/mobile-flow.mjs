// 正式 production 手機 touch 流程與跨 context 存檔搬移；隔離瀏覽器不動使用者存檔。
import { chromium } from '@playwright/test';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import assert from 'node:assert/strict';

const base = process.env.CAPTURE_BASE_URL ?? 'http://localhost:5174/';
const out = process.argv[2] ?? 'docs/previews/mobile-flow';
mkdirSync(out, { recursive: true });
const report = { base, viewport: { width: 844, height: 390 }, deviceScaleFactor: 2, input: 'touch', steps: [], errors: [], checks: [], passed: false };
const browser = await chromium.launch({ args: ['--use-angle=d3d11', '--enable-gpu', '--ignore-gpu-blocklist', '--enable-unsafe-swiftshader'] });
const contextOptions = { viewport: report.viewport, deviceScaleFactor: 2, hasTouch: true, permissions: ['clipboard-read', 'clipboard-write'] };
async function open() {
  const context = await browser.newContext(contextOptions);
  await context.addInitScript(() => localStorage.setItem('xiaoyao.settings', JSON.stringify({ animSpeed: 0, textSpeed: 0, music: 0, sfx: 0, quality: 'low' })));
  const page = await context.newPage();
  page.on('pageerror', e => report.errors.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') report.errors.push(m.text()); });
  await page.goto(base);
  await page.getByRole('button', { name: '新的故事', exact: true }).waitFor({ timeout: 60000 });
  await page.evaluate(() => document.fonts.ready);
  await page.locator('.title-loading').waitFor({ state: 'hidden', timeout: 60000 });
  await page.waitForTimeout(400);
  return { context, page };
}
const shot = (page, name) => page.screenshot({ path: join(out, `${name}.jpg`), type: 'jpeg', quality: 85 });
const readSave = (page, slot = 0) => page.evaluate(slot => JSON.parse(localStorage.getItem(`xiaoyao.save.${slot}`)), slot);
const snapshot = run => ({ chapter: run.chapter, visited: run.visited, at: run.at, party: run.party, members: run.members, coins: run.coins, relics: run.relics, flags: run.flags, seed: run.seed, pending: run.pending });
const check = (name, condition) => { assert.ok(condition, name); report.checks.push(name); };
try {
  const { page } = await open();
  await shot(page, '01-title');
  await page.getByRole('button', { name: '新的故事', exact: true }).tap();
  await page.locator('.slot').first().tap();
  report.steps.push('touch 新故事 → 第 1 欄');
  let stories = 0, maps = 0, reachedBattle = false;
  for (let step = 0; step < 140; step++) {
    await page.waitForTimeout(100);
    if (await page.locator('.chapter-intro').count()) {
      await page.locator('.chapter-intro').tap();
    } else if (await page.locator('.story').count()) {
      if (!stories) await shot(page, '02-story');
      stories++;
      if (await page.locator('.story-ending').count()) await page.locator('.story-ending button').tap();
      else if (await page.locator('.story-choice-btn').count()) await page.locator('.story-choice-btn').first().tap();
      else await page.touchscreen.tap(422, 180);
    } else if (await page.locator('.map').count()) {
      if (!maps) await shot(page, '03-map');
      maps++;
      await page.locator('.map-node.open').first().tap();
    } else if (await page.locator('.bt').count()) {
      reachedBattle = true;
      break;
    }
  }
  check('正常入口已看見劇情、地圖並進入第一場戰鬥', stories > 0 && maps > 0 && reachedBattle);
  if (await page.locator('.bt-tips button').count()) await page.locator('.bt-tips button').tap();
  await shot(page, '04-battle');
  const before = await readSave(page);
  check('自動存檔包含戰鬥', before?.run.pending.kind === 'battle');
  report.steps.push(`劇情觸控 ${stories} 次、地圖節點 ${maps} 次 → 第一場戰鬥`);
  await page.reload();
  await page.getByRole('button', { name: '舊的回憶', exact: true }).tap({ timeout: 60000 });
  await page.locator('.slot').first().tap();
  await page.locator('.bt').waitFor({ timeout: 60000 });
  const resumed = await readSave(page);
  assert.deepEqual(snapshot(resumed.run), snapshot(before.run));
  report.checks.push('重載後讀檔保留 seed、進度、隊伍 HP／牌組、銅錢及完整戰鬥狀態');
  report.steps.push('重載 → 舊的回憶 → 第 1 欄 → 接續戰鬥');
  if (await page.locator('.bt-tips button').count()) await page.locator('.bt-tips button').tap();
  await page.getByRole('button', { name: '選單', exact: true }).tap();
  await page.getByRole('button', { name: '匯出存檔', exact: true }).tap();
  await page.getByText('存檔已複製到剪貼簿，可以貼到別處保存', { exact: true }).waitFor();
  const exported = await page.evaluate(() => navigator.clipboard.readText());
  assert.deepEqual(snapshot(JSON.parse(exported).run), snapshot(resumed.run));
  report.checks.push('UI 匯出實際寫入剪貼簿，內容與已存戰鬥一致');
  await shot(page, '05-export');
  const importedPage = (await open()).page;
  check('第二個 browser context 沒有原存檔', await readSave(importedPage) === null);
  await importedPage.getByRole('button', { name: '舊的回憶', exact: true }).tap();
  await importedPage.locator('.slot-import summary').tap();
  await importedPage.locator('.slot-import textarea').fill('這不是存檔');
  await importedPage.getByRole('button', { name: '匯入', exact: true }).tap();
  await importedPage.getByText('格式不對，請貼上完整的匯出文字', { exact: true }).waitFor();
  check('錯誤匯入不寫入第 3 欄', await readSave(importedPage, 2) === null);
  await importedPage.locator('.slot-import textarea').fill(exported);
  await importedPage.getByRole('button', { name: '匯入', exact: true }).tap();
  await importedPage.getByText('已匯入到第 3 欄', { exact: true }).waitFor();
  check('有效匯入立即啟用第 3 欄', await importedPage.locator('.slot').nth(2).isEnabled());
  await shot(importedPage, '06-import');
  await importedPage.locator('.slot').nth(2).tap();
  await importedPage.locator('.bt').waitFor({ timeout: 60000 });
  const transferred = await readSave(importedPage, 2);
  assert.deepEqual(snapshot(transferred.run), snapshot(resumed.run));
  report.checks.push('乾淨 context 匯入後能讀入原戰鬥，全部關鍵欄位一致');
  await shot(importedPage, '07-transferred-battle');
  report.saveSummary = { chapter: transferred.run.chapter, node: transferred.run.pending.nodeId, party: transferred.run.party, coins: transferred.run.coins, exportedBytes: Buffer.byteLength(exported) };
  check('瀏覽器錯誤為 0', report.errors.length === 0);
  report.passed = true;
} catch (error) {
  report.failure = String(error);
  process.exitCode = 1;
} finally {
  writeFileSync(join(out, 'validation.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  await browser.close();
}

// 正式入口、實際章節 node、三人隊／三藥品／六法寶；不帶開發參數。
import { chromium } from '@playwright/test';
import { createServer } from 'vite';
import { mkdir, writeFile } from 'node:fs/promises';
import { bloodPoolFixture } from './blood-pool-fixture.mjs';
import { BATTLE_SCENE_IDS } from '../../src/stage/scenes/catalog.ts';

const base = process.env.CAPTURE_BASE_URL ?? 'http://localhost:5174/';
const out = 'docs/previews/all-scenes-release';
await mkdir(out, { recursive: true });
const baseFixture = await bloodPoolFixture();
const vite = await createServer({ server: { middlewareMode: true, hmr: false }, appType: 'custom', logLevel: 'error' });
const fixtures = [];
try {
  const { GAME_DB: db } = await vite.ssrLoadModule('/src/content/index.ts');
  const { beginBattle } = await vite.ssrLoadModule('/src/core/run/run.ts');
  for (const id of BATTLE_SCENE_IDS) {
    const chapter = db.chapters.findIndex(ch => ch.nodes.some(n => n.battle?.ground === id));
    const registeredOnly = chapter < 0;
    // 女媧神殿是故事節點，另用舞台 harness 驗證；不改正式劇情。
    if (registeredOnly && id !== 'nuwa_temple') throw new Error(`No encounter for ${id}`);
    if (registeredOnly) continue;
    const node = db.chapters[chapter].nodes.find(n => n.battle?.ground === id);
    let run = JSON.parse(baseFixture.save).run;
    run.chapter = chapter;
    run = beginBattle(db, run, node.id, 0);
    const battle = run.pending.battle;
    const all = [...battle.hand, ...battle.draw];
    const items = all.filter(c => db.cards[c.defId].type === 'item').slice(0, 3);
    const other = all.filter(c => !items.includes(c));
    battle.hand = [...other.slice(0, 3), ...items, ...other.slice(3, 5)];
    const hand = new Set(battle.hand.map(c => c.uid));
    battle.draw = all.filter(c => !hand.has(c.uid));
    // 正式 BattleScreen 從 DB 讀 ground，獨立女媧神殿改用舞台 harness 驗證；
    // 其餘 22 場經 production 正式入口逐一驗收。
    if (!registeredOnly) fixtures.push({ id, node: node.id, save: JSON.stringify({ version: 1, savedAt: Date.now(), run }) });
  }
} finally { await vite.close(); }
const browser = await chromium.launch({ args: ['--use-angle=d3d11', '--enable-gpu', '--ignore-gpu-blocklist', '--enable-unsafe-swiftshader'] });
const report = { cases: [], errors: [], oldBackgroundRequests: [], passed: false };
try {
  for (const mobile of [false, true]) {
    const context = await browser.newContext({ viewport: mobile ? { width: 844, height: 390 } : { width: 1280, height: 720 }, hasTouch: mobile, deviceScaleFactor: mobile ? 2 : 1 });
    const page = await context.newPage();
    page.on('pageerror', e => report.errors.push(String(e)));
    page.on('console', m => { if (m.type() === 'error') report.errors.push(m.text()); });
    page.on('request', r => { if (/assets\/(battle|backgrounds)\/.*jpg/.test(r.url())) report.oldBackgroundRequests.push(r.url()); });
    for (const fixture of fixtures) {
      await page.goto(base);
      await page.evaluate(({ save, mobile }) => {
        localStorage.clear();
        localStorage.setItem('xiaoyao.settings', JSON.stringify({ animSpeed: 0, textSpeed: 0, quality: mobile ? 'low' : 'high', partyStyle: '3d', music: 0, sfx: 0 }));
        localStorage.setItem('xiaoyao.save.2', save);
      }, { save: fixture.save, mobile });
      await page.reload();
      await page.getByRole('button', { name: '舊的回憶', exact: true }).click({ timeout: 60000 });
      await page.locator('.slot').nth(2).click();
      await page.locator('.bt').waitFor({ timeout: 60000 });
      if (await page.getByRole('button', { name: '知道了', exact: true }).count()) await page.getByRole('button', { name: '知道了', exact: true }).click();
      await page.waitForFunction(id => document.querySelector(`[data-scene-environment="${id}"] canvas`), fixture.id);
      await page.evaluate(() => document.fonts.ready);
      await page.waitForTimeout(1200);
      const layout = await page.evaluate(() => {
        const outside = [];
        for (const selector of ['.bt-intent', '.hp', '.actor-name', '.bt-turn', '.bt-top-right', '.bt-end']) for (const el of document.querySelectorAll(selector)) {
          const r = el.getBoundingClientRect();
          if (r.width && r.height && (r.x < -1 || r.y < -1 || r.right > innerWidth + 1 || r.bottom > innerHeight + 1)) outside.push({ selector, text: el.textContent });
        }
        return { outside, cards: document.querySelectorAll('.bt-card').length };
      });
      await page.screenshot({ path: `${out}/${fixture.id}-${mobile ? 'mobile' : 'desktop'}.jpg`, type: 'jpeg', quality: 90 });
      report.cases.push({ id: fixture.id, node: fixture.node, mobile, ...layout, passed: layout.outside.length === 0 && layout.cards === 8 });
      console.log(`${fixture.id} ${mobile ? 'mobile' : 'desktop'}: ${layout.outside.length ? 'HUD outside' : 'ok'}`);
    }
    await context.close();
  }
  report.passed = report.cases.every(c => c.passed) && !report.errors.length && !report.oldBackgroundRequests.length;
} finally { await browser.close(); await writeFile(`${out}/validation.json`, JSON.stringify(report, null, 2)); }
console.log(JSON.stringify({ passed: report.passed, captures: report.cases.length, errors: report.errors, oldBackgroundRequests: report.oldBackgroundRequests }));
if (!report.passed) process.exitCode = 1;

import { chromium } from '@playwright/test';
import { mkdir, writeFile } from 'node:fs/promises';
import { BATTLE_SCENE_IDS } from '../../src/stage/scenes/catalog.ts';

const base = process.env.CAPTURE_BASE_URL ?? 'http://localhost:5175';
const output = 'docs/previews/all-scenes';
await mkdir(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-angle=d3d11', '--enable-gpu', '--ignore-gpu-blocklist', '--enable-unsafe-swiftshader'] });
const results = [], errors = [], requests = [];
try {
  for (const mobile of [false, true]) {
    const context = await browser.newContext({ viewport: mobile ? { width: 844, height: 390 } : { width: 1280, height: 720 }, hasTouch: mobile, isMobile: mobile, deviceScaleFactor: mobile ? 2 : 1 });
    const page = await context.newPage();
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    page.on('request', request => { if (/assets\/(battle|backgrounds)\//.test(request.url())) requests.push(request.url()); });
    await page.goto(`${base}/tools/stage/lifecycle-harness.html`);
    await page.waitForFunction(() => window.__perf?.frame > 5);
    for (const id of BATTLE_SCENE_IDS) {
      await page.getByLabel('scene').selectOption(id);
      // Two complete meter windows exclude the previous scene's peak draw count.
      await page.waitForTimeout(2200);
      await page.waitForFunction(id => document.querySelector(`[data-scene-environment="${id}"]`), id);
      await page.screenshot({ path: `${output}/${id}-${mobile ? 'mobile' : 'desktop'}.png` });
      results.push({ id, mobile, ...await page.evaluate(() => window.__perf) });
    }
    await context.close();
  }
} finally { await browser.close(); }
await writeFile(`${output}/validation.json`, JSON.stringify({ results, errors, paintedBackdropRequests: requests }, null, 2));
console.log(JSON.stringify({ captures: results.length, errors, paintedBackdropRequests: requests.length }));
if (errors.length || requests.length) process.exitCode = 1;

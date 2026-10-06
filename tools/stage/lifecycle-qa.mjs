import { chromium } from '@playwright/test';
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import assert from 'node:assert/strict';

const out = process.argv[2] ?? 'docs/previews/stage-lifecycle';
mkdirSync(out, { recursive: true });
const report = { cycles: [], errors: [], checks: [], passed: false };
const browser = await chromium.launch({ args: ['--use-angle=d3d11', '--enable-gpu', '--ignore-gpu-blocklist', '--enable-unsafe-swiftshader'] });
let page;
try {
  page = await browser.newPage({ viewport: { width: 844, height: 390 }, deviceScaleFactor: 2, hasTouch: true });
  page.on('pageerror', e => report.errors.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') report.errors.push(m.text()); });
  await page.goto(`${process.env.CAPTURE_BASE_URL ?? 'http://localhost:5175'}/tools/stage/lifecycle-harness.html`);
  const sample = async () => {
    const frame = await page.evaluate(() => window.__perf?.frame ?? -1);
    await page.waitForFunction(frame => window.__perf?.frame > frame, frame, { timeout: 15000 });
    return page.evaluate(() => window.__perf);
  };
  await sample();
  const canvas = await page.locator('canvas').elementHandle();
  for (let i = 0; i < 14; i++) {
    await page.getByRole('button', { name: 'shilipo', exact: true }).tap();
    await page.waitForFunction(() => document.querySelector('[data-scene-environment]')?.getAttribute('data-scene-environment') === 'shilipo');
    await sample();
    const plain = await sample();
    assert.equal(await page.locator('[data-scene-environment]').getAttribute('data-scene-environment'), 'shilipo');
    await page.getByRole('button', { name: 'blood_pool', exact: true }).tap();
    await page.waitForFunction(() => document.querySelector('[data-scene-environment]')?.getAttribute('data-scene-environment') === 'blood_pool');
    await sample();
    const blood = await sample();
    assert.equal(await page.locator('[data-scene-environment]').getAttribute('data-scene-environment'), 'blood_pool');
    assert.ok(await canvas.evaluate(n => n === document.querySelector('canvas')), 'same Canvas element must survive scene switching');
    report.cycles.push({ i, plain, blood });
  }
  // 初次載入與 shader 暖機後，各場景的 GPU 資源數應維持固定。
  for (const scene of ['plain', 'blood']) {
    const baseline = report.cycles[3][scene];
    for (const cycle of report.cycles.slice(4)) {
      assert.equal(cycle[scene].geometries, baseline.geometries, `${scene} geometries grew`);
      assert.equal(cycle[scene].textures, baseline.textures, `${scene} textures grew`);
      assert.equal(cycle[scene].programs, baseline.programs, `${scene} programs grew`);
    }
  }
  report.checks.push('14 次場景往返共用同一 Canvas，暖機後 geometry／texture／program 數穩定');
  await page.getByRole('button', { name: 'hide', exact: true }).tap();
  await page.waitForTimeout(250);
  const paused = await page.evaluate(() => window.__perf);
  await page.waitForTimeout(1300);
  assert.deepEqual(await page.evaluate(() => window.__perf), paused);
  report.checks.push('隱藏舞台停止持續渲染與效能取樣');
  await page.getByRole('button', { name: 'show', exact: true }).tap();
  await sample();
  assert.ok(await canvas.evaluate(n => n === document.querySelector('canvas')));
  report.checks.push('恢復顯示後同一 Canvas 繼續渲染');
  await page.getByRole('button', { name: 'low', exact: true }).tap();
  report.highQuality = await sample();
  await page.getByRole('button', { name: 'high', exact: true }).tap();
  report.lowQuality = await sample();
  assert.equal(report.lowQuality.dpr, 1);
  await page.screenshot({ path: join(out, 'mobile-blood.jpg'), type: 'jpeg', quality: 85 });
  assert.equal(report.errors.length, 0, report.errors.join('\n'));
  report.checks.push('高／低畫質切換、省電 DPR1，0 瀏覽器錯誤');
  report.passed = true;
} catch (error) {
  if (page) await page.screenshot({ path: join(out, 'failure.jpg') }).catch(() => {});
  report.failure = String(error);
  process.exitCode = 1;
} finally {
  writeFileSync(join(out, 'validation.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify({ passed: report.passed, cycles: report.cycles.length, checks: report.checks, errors: report.errors, failure: report.failure }));
  await browser.close();
}

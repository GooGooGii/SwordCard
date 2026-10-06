import { chromium } from '@playwright/test';
import { mkdir, writeFile } from 'node:fs/promises';
const out = process.env.CHARACTER_QA_OUT ?? 'docs/previews/characters/browser';
const ids = (process.env.CHARACTER_QA_IDS ?? 'lin_yueru,anu,wuhou').split(',');
const variant = process.env.CHARACTER_QA_VARIANT ?? 'pal1_v1';
if (ids.some(id => !['li_xiaoyao','zhao_linger','lin_yueru','anu','wuhou'].includes(id)) || !/^[a-z0-9_]+$/.test(variant)) throw new Error('Invalid candidate selection');
await mkdir(out, { recursive: true });
const browser = await chromium.launch({ args: ['--use-angle=d3d11','--enable-gpu','--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 720, height: 720 } });
const report = { models: [], frames: [], errors: [], failedRequests: [] };
const checkReady = process.env.CHARACTER_QA_COMBAT_READY === '1';
if (checkReady && ids.some(id => id !== 'li_xiaoyao')) throw new Error('Combat-ready joint thresholds currently cover only the 1.75m Li rig');
function verifyReady(frame, reference) {
  const j = frame.joints;
  for (const side of ['L','R']) {
    const hip = j[`thigh${side}`], knee = j[`shin${side}`], ankle = j[`foot${side}`];
    const a = hip.map((v,i) => v-knee[i]), b = ankle.map((v,i) => v-knee[i]);
    const degrees = Math.acos(Math.max(-1,Math.min(1,a.reduce((s,v,i)=>s+v*b[i],0)/(Math.hypot(...a)*Math.hypot(...b))))) * 180/Math.PI;
    if (degrees > 165 || degrees < 90 || Math.abs(ankle[1] - .09625) > .015) throw new Error(`Idle leg is straight or ungrounded: ${side}, ${degrees}`);
    if (reference && Math.hypot(...ankle.map((v,i) => v-reference.joints[`foot${side}`][i])) > .015) throw new Error('Idle feet drift');
  }
  if (Math.abs(j.footR[2]-j.footL[2]) < .25 || j.handR[1] < j.pelvis[1]+.2 || j.handL[1] < j.pelvis[1]+.2) throw new Error('Missing staggered feet or raised guard');
}
page.on('pageerror', e => report.errors.push(String(e)));
page.on('console', m => { if (m.type() === 'error') report.errors.push(m.text()); });
page.on('requestfailed', r => report.failedRequests.push(r.url()));
try {
  for (const id of ids) {
    await page.goto(`http://localhost:5175/tools/stage/character-harness.html?id=${id}&variant=${variant}`);
    await page.waitForFunction(id => window.__character?.id === id, id);
    await page.getByLabel('clip').selectOption('idle');
    await page.getByLabel('time').fill('0');
    await page.waitForTimeout(350);
    const model = await page.evaluate(() => window.__character);
    if (model.triangles > 15000 || model.bones > 70 || model.textures.length !== 1 ||
        model.textures.some(t => t.width > 2048 || t.height > 2048) ||
        ['idle','attack','hit'].some(c => !model.clips.some(a => a.name === c))) throw new Error(`Asset budget/clips failed: ${JSON.stringify(model)}`);
    report.models.push(model);
    if (checkReady) verifyReady(model);
    for (const angle of ['front','back','left','right','front45','back45']) {
      await page.getByLabel('angle').selectOption(angle);
      await page.waitForTimeout(300);
      await page.screenshot({ path: `${out}/${id}-${angle}.png` });
    }
    await page.getByLabel('angle').selectOption('front45');
    for (const clip of ['idle','attack','hit']) {
      await page.getByLabel('clip').selectOption(clip);
      for (const time of clip === 'idle' ? [0,.5,1,1.5,1.99] : clip === 'attack' ? [0,.15,.3,.5,.7,1] : [0,.08,.2,.4]) {
        await page.getByLabel('time').fill(String(time));
        await page.waitForTimeout(120);
        const frame = await page.evaluate(() => window.__character);
        if (checkReady && clip === 'idle') verifyReady(frame,model);
        if (checkReady && (time === 0 || (clip !== 'idle' && time >= frame.clips.find(a => a.name === clip).duration))) {
          for (const joint of ['pelvis','handL','handR','footL','footR']) if (Math.hypot(...frame.joints[joint].map((v,i) => v-model.joints[joint][i])) > .025) throw new Error(`Clip does not return to guard: ${clip}, ${joint}`);
        }
        if (frame.bounds.min.some(v => !Number.isFinite(v)) || frame.bounds.max.some(v => !Number.isFinite(v))) throw new Error('Invalid animation bounds');
        report.frames.push(frame);
        await page.screenshot({ path: `${out}/${id}-${clip}-${time}.png` });
      }
    }
  }
} finally { await browser.close(); await writeFile(`${out}/validation.json`, JSON.stringify(report, null, 2)); }
console.log(JSON.stringify({ models: report.models.length, animationFrames: report.frames.length, errors: report.errors, failedRequests: report.failedRequests }));
if (report.errors.length || report.failedRequests.length) process.exitCode = 1;

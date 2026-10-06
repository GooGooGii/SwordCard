// Actual game UI with candidate GLBs routed locally until visual acceptance.
import { chromium } from '@playwright/test';
import { createServer } from 'vite';
import { mkdir, writeFile } from 'node:fs/promises';
import { bloodPoolFixture } from './blood-pool-fixture.mjs';
const out = process.env.CHARACTER_QA_OUT ?? 'docs/previews/characters/release';
const base = process.env.CAPTURE_BASE_URL ?? 'http://localhost:5175/';
const candidates = process.env.CHARACTER_CANDIDATES !== '0';
const candidateIds = (process.env.CHARACTER_QA_IDS ?? 'lin_yueru,anu,wuhou').split(',');
const variant = process.env.CHARACTER_QA_VARIANT ?? 'pal1_v1';
if (candidateIds.some(id => !['li_xiaoyao','zhao_linger','lin_yueru','anu','wuhou'].includes(id)) || !/^[a-z0-9_]+$/.test(variant)) throw new Error('Invalid candidate selection');
await mkdir(out, { recursive: true });
const initial = JSON.parse((await bloodPoolFixture()).save).run;
const vite = await createServer({ server: { middlewareMode: true, hmr: false }, appType: 'custom', logLevel: 'error' });
const fixtures = [];
const modelPaths = {};
try {
  const { GAME_DB: db } = await vite.ssrLoadModule('/src/content/index.ts');
  for (const cid of candidateIds) modelPaths[cid] = db.characters[cid].model;
  const { beginBattle } = await vite.ssrLoadModule('/src/core/run/run.ts');
  const { joinMember } = await vite.ssrLoadModule('/src/core/run/story.ts');
  for (const [id, chapter, ground, party] of [
    ['yueru',3,'blood_pool',['li_xiaoyao','zhao_linger','lin_yueru']],
    ['anu-wuhou',7,'water_maze',['li_xiaoyao','anu','wuhou']],
  ]) {
    let run = structuredClone(initial);
    run.chapter = chapter;
    // QA fixture selects existing characters; the production story is unchanged.
    for (const cid of party) joinMember(db, run, cid);
    run.party = party;
    const node = db.chapters[chapter].nodes.find(n => n.battle?.ground === ground);
    run = beginBattle(db, run, node.id, 0);
    const battle = run.pending.battle;
    const cards = [...battle.hand, ...battle.draw];
    const items = cards.filter(c => db.cards[c.defId].type === 'item').slice(0,3);
    const other = cards.filter(c => !items.includes(c));
    battle.hand = [...other.slice(0,3), ...items, ...other.slice(3,5)];
    const hand = new Set(battle.hand.map(c => c.uid));
    battle.draw = cards.filter(c => !hand.has(c.uid));
    fixtures.push({ id, ground, party, save: JSON.stringify({ version: 1, savedAt: Date.now(), run }) });
  }
} finally { await vite.close(); }
const browser = await chromium.launch({ args: ['--use-angle=d3d11','--enable-gpu','--ignore-gpu-blocklist'] });
const report = { captures: [], errors: [], models: [] };
try {
  for (const mobile of [false,true]) {
    const page = await browser.newPage({ viewport: mobile ? { width: 844,height: 390 } : { width: 1280,height: 720 }, hasTouch: mobile, deviceScaleFactor: mobile ? 2 : 1 });
    for (const cid of candidates ? candidateIds : []) await page.route(`**${modelPaths[cid]}`, async route => {
      await route.fulfill({ path: `source_art/characters/${cid}/raw_candidate_${variant}.glb`, contentType: 'model/gltf-binary' });
    });
    page.on('pageerror', e => report.errors.push(String(e)));
    page.on('console', m => { if (m.type() === 'error') report.errors.push(m.text()); });
    page.on('request', r => { if (r.url().endsWith('.glb') && r.method() === 'GET') report.models.push(r.url()); });
    for (const fixture of fixtures) {
      await page.goto(base);
      await page.evaluate(({ save, mobile }) => {
        localStorage.clear();
        localStorage.setItem('xiaoyao.settings', JSON.stringify({ animSpeed: 1, textSpeed: 0, quality: mobile ? 'low' : 'high', partyStyle: '3d', music: 0, sfx: 0 }));
        localStorage.setItem('xiaoyao.save.2', save);
      }, { save: fixture.save, mobile });
      await page.reload();
      await page.getByRole('button',{name:'舊的回憶',exact:true}).click({timeout:60000});
      await page.locator('.slot').nth(2).click();
      await page.locator('.bt').waitFor({timeout:60000});
      if (await page.getByRole('button',{name:'知道了',exact:true}).count()) await page.getByRole('button',{name:'知道了',exact:true}).click();
      await page.waitForFunction(id => document.querySelector(`[data-scene-environment="${id}"] canvas`), fixture.ground);
      await page.evaluate(() => document.fonts.ready);
      await page.waitForTimeout(1800);
      const layout = await page.evaluate(() => {
        const outside=[];
        for(const selector of ['.bt-intent','.hp','.actor-name','.bt-turn','.bt-top-right','.bt-end']) for(const el of document.querySelectorAll(selector)) {
          const r=el.getBoundingClientRect();
          if(r.width && r.height && (r.x < -1 || r.y < -1 || r.right > innerWidth+1 || r.bottom > innerHeight+1)) outside.push({selector,text:el.textContent});
        }
        return { outside, cards:document.querySelectorAll('.bt-card').length };
      });
      if(layout.outside.length || layout.cards !== 8) throw new Error(JSON.stringify(layout));
      const path=`${out}/${fixture.id}-${mobile?'mobile':'desktop'}.png`;
      await page.screenshot({path});
      report.captures.push({id:fixture.id,mobile,party:fixture.party,...layout,path});
    }
    await page.close();
  }
} finally { await browser.close(); await writeFile(`${out}/validation.json`,JSON.stringify(report,null,2)); }
for(const cid of candidateIds) if(!report.models.some(url=>url.endsWith(modelPaths[cid]))) throw new Error(`Model not loaded: ${cid}`);
console.log(JSON.stringify({captures:report.captures.length,errors:report.errors}));
if(report.errors.length) process.exitCode=1;

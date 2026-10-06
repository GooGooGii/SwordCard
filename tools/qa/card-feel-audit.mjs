// Read-only production interaction audit, isolated browser save and QA fixture.
import { createServer } from 'vite';
import { chromium } from '@playwright/test';
import { mkdir, writeFile } from 'node:fs/promises';
import { bloodPoolFixture } from '../stage/blood-pool-fixture.mjs';
const mobile=process.env.AUDIT_MOBILE==='1';
const out=`docs/previews/card-feel-audit${mobile?'-mobile':''}`;
await mkdir(out,{recursive:true});
const run=JSON.parse((await bloodPoolFixture()).save).run;
const vite=await createServer({server:{middlewareMode:true,hmr:false},appType:'custom',logLevel:'error'});
let def;
try {
  const {GAME_DB:db}=await vite.ssrLoadModule('/src/content/index.ts');
  const {canPlay}=await vite.ssrLoadModule('/src/core/battle/turn.ts');
  const b=run.pending.battle;
  b.enemies.forEach(e=>{if(db.enemies[e.defId].isField)e.dead=true;});
  def=Object.values(db.cards).find(c=>c.owner==='li_xiaoyao' && c.target==='enemy' && c.effects.some(e=>e.kind==='damage') && c.cost<=b.qi);
  b.hand[0]={uid:999990,defId:def.id,upgraded:false};
  b.nextUid=Math.max(b.nextUid,999991);
  const indices=b.enemies.flatMap((e,i)=>canPlay(db,b,999990,i)===null?[i]:[]);
  if(indices.length!==1) throw new Error(`Expected one legal enemy: ${indices}`);
} finally {await vite.close();}
const browser=await chromium.launch({args:['--use-angle=d3d11','--enable-gpu','--ignore-gpu-blocklist']});
const page=await browser.newPage({viewport:mobile?{width:844,height:390}:{width:1280,height:720},hasTouch:mobile,isMobile:mobile});
const session=mobile?await page.context().newCDPSession(page):null;
let touching=false,px=0,py=0;
const pointer=mobile?{
  async move(x,y,options={}) {const n=options.steps??1,ox=px,oy=py;for(let i=1;i<=n;i++){px=ox+(x-ox)*i/n;py=oy+(y-oy)*i/n;if(touching)await session.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:px,y:py}]});}},
  async down(){touching=true;await session.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:px,y:py}]});},
  async up(){touching=false;await session.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});},
  async click(x,y){px=x;py=y;await this.down();await this.up();},
}:page.mouse;
const report={mobile,input:mobile?'CDP touch':'mouse',card:def.name,legalTargets:1,observations:[],errors:[]};
page.on('pageerror',e=>report.errors.push(String(e)));
try {
  await page.goto('http://localhost:5174/');
  await page.evaluate(save=>{
    localStorage.clear();localStorage.setItem('xiaoyao.save.2',save);
    localStorage.setItem('xiaoyao.settings',JSON.stringify({animSpeed:1,quality:'low',music:0,sfx:0}));
  },JSON.stringify({version:1,savedAt:Date.now(),run}));
  await page.reload();
  await page.getByRole('button',{name:'舊的回憶',exact:true}).click({timeout:60000});
  await page.locator('.slot').nth(2).click();await page.locator('.bt').waitFor();
  if(await page.getByRole('button',{name:'知道了',exact:true}).count()) await page.getByRole('button',{name:'知道了',exact:true}).click();
  await page.waitForTimeout(1000);
  const card=page.locator('.bt-card').first();
  const cr=await card.boundingBox();
  const grab={x:cr.x+cr.width*.5,y:cr.y+30};
  await pointer.click(grab.x,grab.y);await page.waitForTimeout(180);
  report.observations.push({case:'single-target first tap',selected:await page.locator('.bt-card.selected').count(),hand:await page.locator('.bt-card').count()});
  const selected=await card.boundingBox();await pointer.click(selected.x+selected.width*.5,selected.y+30);await page.waitForTimeout(180);
  report.observations.push({case:'single-target second tap',selected:await page.locator('.bt-card.selected').count(),hand:await page.locator('.bt-card').count()});
  const target=await page.locator('[data-target="enemy:0"]').boundingBox();
  const from=await card.boundingBox();await pointer.move(from.x+from.width*.5,from.y+30);await pointer.down();
  const x=target.x+target.width*.5,y=target.y+target.height*.5;
  await pointer.move(x,y,{steps:8});await page.waitForTimeout(150);
  report.observations.push(await page.evaluate(({x,y})=>({case:'direct drag without preselection',activeDropZones:document.querySelectorAll('.drop-zone.active').length,hit:document.elementFromPoint(x,y)?.className,cardTransform:getComputedStyle(document.querySelector('.bt-card')).transform,dropPointerEvents:getComputedStyle(document.querySelector('[data-target="enemy:0"]')).pointerEvents}),{x,y}));
  await page.screenshot({path:`${out}/drag.png`});
  await pointer.up();await page.waitForTimeout(500);
  report.observations.push({case:'direct drag release',hand:await page.locator('.bt-card').count(),cardStillPresent:await page.evaluate(()=>JSON.parse(localStorage.getItem('xiaoyao.save.2')).run.pending.battle.hand.some(c=>c.uid===999990))});
  const before=await card.boundingBox();await pointer.click(before.x+before.width*.5,before.y+30);await page.waitForTimeout(180);
  const lifted=await card.boundingBox();await pointer.move(lifted.x+lifted.width*.5,lifted.y+30);await pointer.down();
  await pointer.move(x,y,{steps:8});await page.waitForTimeout(150);
  report.observations.push(await page.evaluate(({x,y})=>({case:'drag after selection',activeDropZones:document.querySelectorAll('.drop-zone.active').length,hitTarget:document.elementFromPoint(x,y)?.closest('[data-target]')?.getAttribute('data-target'),cardTransform:getComputedStyle(document.querySelector('.bt-card')).transform}),{x,y}));
  await pointer.up();await page.waitForTimeout(800);
  report.observations.push({case:'selected drag release',hand:await page.locator('.bt-card').count()});
} finally {await browser.close();await writeFile(`${out}/report.json`,JSON.stringify(report,null,2));}
console.log(JSON.stringify(report));

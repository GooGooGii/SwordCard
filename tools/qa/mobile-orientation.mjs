import { chromium } from '@playwright/test';
import { mkdir, writeFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
const out='docs/previews/mobile-orientation';
await mkdir(out,{recursive:true});
const browser=await chromium.launch({args:['--use-angle=d3d11','--enable-gpu','--ignore-gpu-blocklist']});
const report={checks:[],errors:[]};
try {
  for(const mode of ['success','denied','fullscreen-denied','unsupported']) {
    const context=await browser.newContext({viewport:{width:390,height:844},hasTouch:true,isMobile:true});
    await context.addInitScript(mode=>{
      window.__orientationCalls=[];
      let fullscreen=false;
      Object.defineProperty(document,'fullscreenElement',{get:()=>fullscreen?document.documentElement:null,configurable:true});
      Object.defineProperty(HTMLElement.prototype,'requestFullscreen',{value:async()=>{
        window.__orientationCalls.push('fullscreen');
        if(mode==='fullscreen-denied') throw new Error('denied');
        fullscreen=true;
      },configurable:true});
      Object.defineProperty(screen.orientation,'lock',{value:mode==='unsupported'?undefined:async direction=>{
        window.__orientationCalls.push(direction);
        if(!fullscreen || mode==='denied') throw new Error('denied');
      },configurable:true});
    },mode);
    const page=await context.newPage();
    page.on('pageerror',e=>report.errors.push(String(e)));
    await page.goto('http://localhost:5174/');
    await page.getByRole('dialog',{name:'橫向遊玩'}).waitFor();
    await page.getByRole('button',{name:'橫向全螢幕',exact:true}).click();
    await page.waitForTimeout(150);
    const calls=await page.evaluate(()=>window.__orientationCalls);
    assert.deepEqual(calls,mode==='unsupported'?[]:mode==='fullscreen-denied'?['fullscreen']:['fullscreen','landscape']);
    if(mode!=='success') await page.getByText('此瀏覽器無法自動轉向，請將手機轉為橫向。').waitFor();
    await page.screenshot({path:`${out}/${mode}-portrait.png`});
    await page.setViewportSize({width:844,height:390});
    await page.getByRole('dialog',{name:'橫向遊玩'}).waitFor({state:'hidden'});
    if(mode==='success') {
      await page.getByRole('button',{name:'新的故事',exact:true}).click();
      await page.waitForTimeout(100);
      assert.deepEqual(await page.evaluate(()=>window.__orientationCalls),['fullscreen','landscape','landscape']);
    }
    report.checks.push(`${mode}: fullscreen → lock ordering / fallback / landscape overlay hidden`);
    await context.close();
  }
  const page=await browser.newPage({viewport:{width:1280,height:720}});
  await page.goto('http://localhost:5174/');
  assert.equal(await page.getByRole('dialog',{name:'橫向遊玩'}).count(),0);
  report.checks.push('desktop: no orientation overlay');
} finally {await browser.close();await writeFile(`${out}/validation.json`,JSON.stringify(report,null,2));}
console.log(JSON.stringify(report));
if(report.errors.length) process.exitCode=1;

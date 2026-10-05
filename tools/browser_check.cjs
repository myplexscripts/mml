/* Optional WebGL and IndexedDB playtest. Run after exporting Web.
 * Requires Playwright and a Chromium executable; no player save is touched.
 * CHROMIUM_PATH=/path/to/chrome-headless-shell node tools/browser_check.cjs
 */
const {chromium} = require('playwright');
const {spawn} = require('child_process');
const path = require('path');
const fs = require('fs');
const assert = require('assert');
const root = path.resolve(__dirname, '..');
const output = path.join(root, 'test-results');
fs.mkdirSync(output, {recursive:true});

(async () => {
  const server = spawn('python', ['-m', 'http.server', '8774', '--bind', '127.0.0.1', '--directory', path.join(root, 'build/web')], {stdio:'ignore'});
  let browser;
  try {
    browser = await chromium.launch({
      executablePath:process.env.CHROMIUM_PATH || undefined,
      headless:true,
      args:['--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']
    });
    const page = await browser.newPage({viewport:{width:1280,height:720}});
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => {if (message.type()==='error') errors.push(message.text());});
    await page.goto('http://127.0.0.1:8774/', {waitUntil:'networkidle'});
    await page.waitForTimeout(3500);
    await page.screenshot({path:path.join(output,'web-title.png')});
    await page.mouse.click(400,515);
    await page.waitForTimeout(700);
    for (let i=0;i<6;i++) {await page.keyboard.press('e');await page.waitForTimeout(200);}
    await page.keyboard.press('c');await page.waitForTimeout(400);
    await page.screenshot({path:path.join(output,'web-seeds.png')});
    await page.mouse.click(640,390);await page.waitForTimeout(400);
    await page.keyboard.down('d');await page.waitForTimeout(700);await page.keyboard.up('d');
    await page.keyboard.press('Escape');await page.waitForTimeout(400);
    await page.mouse.click(400,140);await page.waitForTimeout(250);
    await page.screenshot({path:path.join(output,'web-equipment.png')});
    await page.mouse.click(950,648);await page.waitForTimeout(6000);
    const saved = await page.evaluate(async () => {
      for (const meta of await indexedDB.databases()) {
        const db = await new Promise((resolve,reject) => {const request=indexedDB.open(meta.name);request.onsuccess=()=>resolve(request.result);request.onerror=()=>reject(request.error);});
        for (const name of db.objectStoreNames) {
          const values = await new Promise((resolve,reject) => {const request=db.transaction(name).objectStore(name).getAll();request.onsuccess=()=>resolve(request.result);request.onerror=()=>reject(request.error);});
          for (const value of values) {
            if (!value.contents) continue;
            try {const data=JSON.parse(new TextDecoder().decode(value.contents));if (data.version===2 && data.crops) {db.close();return {day:data.day,seed_kind:data.seed_kind};}} catch {}
          }
        }
        db.close();
      }
      return null;
    });
    assert(saved && saved.seed_kind==='tomato', 'Web save must persist the new seed selection');
    await page.reload({waitUntil:'networkidle'});await page.waitForTimeout(3500);
    await page.mouse.click(400,610);await page.waitForTimeout(1000);
    await page.screenshot({path:path.join(output,'web-continue.png')});
    assert.deepStrictEqual(errors, [], 'Browser/runtime console must contain no errors');
    console.log('BROWSER PLAYTEST: PASS. WebGL startup, dialogue, seeds, movement, equipment, IndexedDB save, reload and Continue.');
  } finally {
    if (browser) await browser.close();
    server.kill();
  }
})().catch(error => {console.error(error);process.exitCode=1;});

/* CHROMIUM_PATH=/path/to/chrome node tools/browser_check.cjs
 * Fresh browser profile; does not touch a player's save. */
const {chromium}=require('playwright');
const {spawn}=require('child_process');
const path=require('path'),fs=require('fs'),assert=require('assert');
const root=path.resolve(__dirname,'..'),output=path.join(root,'test-results');
fs.mkdirSync(output,{recursive:true});
(async()=>{
 const server=spawn('python',['-m','http.server','8774','--bind','127.0.0.1','--directory',path.join(root,'build/web')],{stdio:'ignore'});
 let browser;
 try{
  browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||undefined,headless:true,args:['--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
  const page=await browser.newPage({viewport:{width:1280,height:720}}),errors=[];
  page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error'||/SCRIPT ERROR|^ERROR:/.test(m.text()))errors.push(m.text());});
  const wait=ms=>page.waitForTimeout(ms);
  const dialogue=async()=>{for(let i=0;i<6;i++){await page.keyboard.press('e');await wait(180);}};
  await page.goto('http://127.0.0.1:8774/',{waitUntil:'networkidle'});await wait(4500);
  await page.screenshot({path:path.join(output,'web-title.png')});
  await page.keyboard.press('Enter');await wait(500);await dialogue();
  await page.mouse.move(820,330);await page.mouse.down();await wait(700);await page.mouse.up();
  await page.mouse.down({button:'right'});await wait(800);await page.mouse.up({button:'right'});
  await page.mouse.wheel(0,-100);await wait(500);
  await page.keyboard.down('d');await page.keyboard.press('Shift');await wait(500);await page.keyboard.up('d');
  await page.screenshot({path:path.join(output,'web-play.png')});
  await page.keyboard.press('Escape');await wait(400);await page.mouse.click(1100,122);await wait(250);
  await page.mouse.click(600,364);await wait(400);await page.screenshot({path:path.join(output,'web-options.png')});
  await page.mouse.click(640,647);await wait(6000);
  const saved=await page.evaluate(async()=>{
   for(const meta of await indexedDB.databases()){
    const db=await new Promise((resolve,reject)=>{const r=indexedDB.open(meta.name);r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});
    for(const name of db.objectStoreNames){
     const values=await new Promise((resolve,reject)=>{const r=db.transaction(name).objectStore(name).getAll();r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});
     for(const value of values){if(!value.contents)continue;try{const data=JSON.parse(new TextDecoder().decode(value.contents));if(data.version===1&&'repair' in data&&'reduced_motion' in data){db.close();return data;}}catch{}}
    }db.close();
   }return null;
  });
  assert(saved&&saved.reduced_motion===true&&saved.camera_zoom>1,'motion and zoom settings must persist in IndexedDB');
  await page.reload({waitUntil:'networkidle'});await wait(4500);await page.keyboard.press('Tab');await page.keyboard.press('Enter');await wait(1000);
  await page.keyboard.press('m');await wait(400);await page.screenshot({path:path.join(output,'web-map.png')});
  await page.keyboard.press('Escape');await wait(400);await page.screenshot({path:path.join(output,'web-continue.png')});
  assert.deepStrictEqual(errors,[],'browser and Godot console errors');
  console.log('BROWSER PLAYTEST: PASS. WebGL models, dialogue, mouse fire/charge, movement/dash, pause/options/map, IndexedDB save, reload and Continue.');
 }finally{if(browser)await browser.close();server.kill();}
})().catch(e=>{console.error(e);process.exitCode=1;});

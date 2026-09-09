#!/usr/bin/env node
// Project:  Collectors App
// File:     tools/viewer_smoke.js
// Modified: 2026-09-09
// Version:  0.90.1.20260909.1200
// Purpose:  Smoke-test viewer.html against an export in TODAY's shape — the standalone
//           JSON viewer is a separate page that nothing else exercises.
// Changelog:
//   2026-09-09 v0.90.1.20260909.1200 — Initial creation. The viewer reads a file the app
//                        writes, and the app's schema changed this week (editionMarker,
//                        collectorNumber, photos as idb: refs on device). Nothing checked
//                        the two still agreed. Four field-name mismatches were found.
//
// Drives the REAL drop handler with a real File. The page wraps everything in an IIFE,
// so its functions are not reachable from the outside — poking at internals would test
// nothing a user does.
const path=require('path'),http=require('http'),fs=require('fs'),os=require('os');
process.env.LD_LIBRARY_PATH=[path.join(os.homedir(),'.local/lib/pwlibs/usr/lib/x86_64-linux-gnu'),'/tmp/nspr-extract/usr/lib/x86_64-linux-gnu',process.env.LD_LIBRARY_PATH||''].filter(Boolean).join(':');
const { chromium } = require('playwright-core');
const ROOT = require('path').resolve(__dirname, '..');
(async()=>{
  const srv=http.createServer((q,r)=>{const p=path.join(ROOT,decodeURIComponent(q.url.split('?')[0]));
    if(!p.startsWith(ROOT)||!fs.existsSync(p)||fs.statSync(p).isDirectory()){r.writeHead(404).end();return;}
    r.writeHead(200,{'Content-Type':'text/html'});fs.createReadStream(p).pipe(r);});
  await new Promise(res=>srv.listen(0,'127.0.0.1',res));
  const b=await chromium.launch(); const pg=await b.newPage();
  const errs=[]; pg.on('pageerror',e=>errs.push(String(e).split('\n')[0]));
  await pg.goto(`http://127.0.0.1:${srv.address().port}/viewer.html`);

  const out = await pg.evaluate(async () => {
    const photo='data:image/jpeg;base64,'+'A'.repeat(600);
    const data={ items:[
      {id:'1',name:'The Joker',itemType:'figure',brand:'McFarlane',barcode:'787926179668',
       editionMarker:'Platinum Edition',collectorNumber:'158/250',characters:'Joker',
       photos:[photo],dateAdded:new Date().toISOString()},
      {id:'2',name:'The Joker',itemType:'figure',brand:'McFarlane',barcode:'787926179668',
       editionMarker:'Red Platinum',characters:'Joker',photos:[photo],
       dateAdded:new Date().toISOString()}
    ]};
    // Drop a real File on the drop zone — the actual user path.
    const file = new File([JSON.stringify(data)], 'export.json', {type:'application/json'});
    const dt = new DataTransfer(); dt.items.add(file);
    const ev = new DragEvent('drop', { dataTransfer: dt, bubbles: true, cancelable: true });
    document.getElementById('dropZone').dispatchEvent(ev);
    for (let i=0;i<80 && !document.querySelector('.item-card, .card');i++) await new Promise(r=>setTimeout(r,25));
    const cards = document.querySelectorAll('.item-card, .card');
    const text = [...cards].map(c=>c.textContent).join(' | ');

    const si = document.getElementById('searchInput');
    si.value='red platinum'; si.dispatchEvent(new Event('input',{bubbles:true}));
    await new Promise(r=>setTimeout(r,80));
    const afterEdition = document.querySelectorAll('.item-card, .card').length;

    si.value='158/250'; si.dispatchEvent(new Event('input',{bubbles:true}));
    await new Promise(r=>setTimeout(r,80));
    const afterCollector = document.querySelectorAll('.item-card, .card').length;

    si.value=''; si.dispatchEvent(new Event('input',{bubbles:true}));
    await new Promise(r=>setTimeout(r,80));
    const typeOpts=[...document.querySelectorAll('#filterType option')].map(o=>o.value).filter(Boolean);

    return { cards: cards.length, showsEdition: text.includes('Platinum Edition'),
             showsRed: text.includes('Red Platinum'), showsCollector: text.includes('158/250'),
             showsType: text.includes('figure'), searchByEdition: afterEdition,
             searchByCollector: afterCollector, typeFilterOptions: typeOpts };
  });
  console.log(JSON.stringify(out,null,1));
  console.log('page errors:', errs.length?errs.join(' | '):'none');
  await b.close(); srv.close();
})();

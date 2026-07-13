/* Browser Generals service worker — offline app shell.
   Scope is the whole site (served from the root alongside index.html).
   Strategy: precache the core shell on install; cache-first with network
   fallback for same-origin GET requests so the game plays fully offline
   after the first load. Non-GET and cross-origin requests are passed
   straight through to the network. Robust to missing assets — a 404 on
   any single sprite must not break install. */

const CACHE = 'browser-generals-v4';

// Unit sprite keys — 8 directional frames each (assets/<key>_0..7.png).
// Keep in sync with UNIT_SPRITE_REG in generals-zero-hour.html.
const UNIT_KEYS = [
  'ranger','missile','sniper','burton','redguard','hunter','lotus','rebel','rpg','terrorist','jarmen','worker',
  'humvee','crusader','paladin','avenger','tomahawk','raptor','aurora','comanche','chinook',
  'dragon','gattling','battlemaster','overlord','inferno','nukecannon','mig','helix',
  'cycle','technical','buggy','quad','scorpion','marauder','bombtruck','toxin','scud',
  'truck','bulldozer','dozer','battlebus'
];

// Building sprite keys — up to 3 health states each (assets/bld_<k>_0..2.png).
const BLD_KEYS = [
  'hq','power','supply','barracks','training','factory','air','def','firebase','strategy',
  'particle','bunker','propaganda','nuke','market','tunnel','palace','scudstorm'
];

function buildPrecacheList() {
  const list = ['./', './index.html', './manifest.json', './icon-192.png', './icon-512.png', './icon-512-maskable.png'];
  for (const k of UNIT_KEYS) for (let i = 0; i < 8; i++) list.push('assets/' + k + '_' + i + '.png');
  for (const k of BLD_KEYS) for (let i = 0; i < 3; i++) list.push('assets/bld_' + k + '_' + i + '.png');
  return list;
}

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    const urls = buildPrecacheList();
    // Add each entry individually so one missing/404 asset can't abort the whole install.
    await Promise.all(urls.map(async (url) => {
      try {
        const res = await fetch(url, { cache: 'no-cache' });
        if (res && res.ok) await cache.put(url, res.clone());
      } catch (e) { /* asset unavailable — skip, non-fatal */ }
    }));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;                       // don't touch non-GET
  let url;
  try { url = new URL(req.url); } catch (e) { return; }
  if (url.origin !== self.location.origin) return;        // don't touch cross-origin

  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const cached = await cache.match(req, { ignoreSearch: false });
    if (cached) return cached;
    try {
      const res = await fetch(req);
      // Cache successful basic responses for next time (runtime fill).
      if (res && res.ok && res.type === 'basic') {
        cache.put(req, res.clone()).catch(() => {});
      }
      return res;
    } catch (e) {
      // Offline and not cached: fall back to the app shell for navigations.
      if (req.mode === 'navigate') {
        const shell = await cache.match('./index.html');
        if (shell) return shell;
      }
      return new Response('', { status: 504, statusText: 'Offline' });
    }
  })());
});

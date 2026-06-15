// Network-first service worker. v4 — guards against undefined-Response crash
// when both network and cache miss (e.g. with VPN blocking GitHub CDN).
const CACHE = 'multi-tracker-v4';

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // Only handle same-origin requests; never touch Supabase / Groq.
  if (url.origin !== self.location.origin) return;

  // Network-first: always try fresh, fall back to cache only when offline.
  e.respondWith(
    fetch(req)
      .then((res) => {
        // Only cache successful, non-opaque responses.
        if (res.ok) {
          const copy = res.clone();
          caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
        }
        return res;
      })
      .catch(async () => {
        // Fallback: cached version of the exact URL, then the shell, then a
        // synthetic 503 — respondWith must never receive undefined.
        const cached = (await caches.match(req)) ?? (await caches.match('/'));
        return cached ?? new Response('Offline', { status: 503, statusText: 'Offline' });
      }),
  );
});

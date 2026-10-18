// Organiser app: lets the dashboard open quickly and show a message when offline.
// Only the page itself and its icons are kept; registrations and photos always come live from the server.
const CACHE = "yp-organiser-v1";
const SHELL = ["/admin.html", "/config.js", "/images/yp-logo.jpg", "/images/app/icon-192.png"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

// Newest version from the internet first; the saved copy only when there is no connection
self.addEventListener("fetch", e => {
  const url = new URL(e.request.url);
  if (e.request.method !== "GET" || url.origin !== location.origin || !SHELL.includes(url.pathname)) return;
  e.respondWith(
    fetch(e.request)
      .then(res => { const copy = res.clone(); caches.open(CACHE).then(c => c.put(url.pathname, copy)); return res; })
      .catch(() => caches.match(url.pathname))
  );
});

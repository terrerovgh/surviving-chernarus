/**
 * Service Worker for Terrerov Personal Website
 * Aggressive caching strategy for optimal performance
 */

const CACHE_NAME = 'terrerov-v1.2.0';
const STATIC_CACHE = 'static-v1.2.0';
const DYNAMIC_CACHE = 'dynamic-v1.2.0';

// Resources to cache immediately
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/css/style.css',
  '/js/main.js',
  'https://fonts.googleapis.com/css2?family=Space+Mono:wght@400;700&family=Manrope:wght@400&display=swap',
  'https://cdnjs.cloudflare.com/ajax/libs/animejs/3.2.1/anime.min.js',
  'https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js',
  'https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/SplitText.min.js',
  'https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/ScrambleTextPlugin.min.js'
];

// Dynamic resources (GitHub API, etc.)
const DYNAMIC_ASSETS = [
  'https://api.github.com/users/terrerovgh/repos'
];

// Install event - cache static assets
self.addEventListener('install', event => {
  console.log('SW: Installing...');
  event.waitUntil(
    Promise.all([
      caches.open(STATIC_CACHE).then(cache => {
        console.log('SW: Caching static assets');
        return cache.addAll(STATIC_ASSETS);
      }),
      caches.open(DYNAMIC_CACHE).then(cache => {
        console.log('SW: Preparing dynamic cache');
        return Promise.resolve();
      })
    ]).then(() => {
      console.log('SW: Installation complete');
      return self.skipWaiting();
    })
  );
});

// Activate event - clean old caches
self.addEventListener('activate', event => {
  console.log('SW: Activating...');
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== STATIC_CACHE && cacheName !== DYNAMIC_CACHE) {
            console.log('SW: Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      console.log('SW: Activation complete');
      return self.clients.claim();
    })
  );
});

// Fetch event - serve from cache with network fallback
self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);

  // Handle different types of requests
  if (request.method === 'GET') {
    // Static assets - cache first
    if (STATIC_ASSETS.some(asset => request.url.includes(asset.replace('/', '')))) {
      event.respondWith(cacheFirst(request, STATIC_CACHE));
    }
    // GitHub API - network first with cache fallback
    else if (url.hostname === 'api.github.com') {
      event.respondWith(networkFirst(request, DYNAMIC_CACHE, 5000));
    }
    // Other requests - network first
    else {
      event.respondWith(networkFirst(request, DYNAMIC_CACHE));
    }
  }
});

// Cache first strategy (for static assets)
async function cacheFirst(request, cacheName) {
  try {
    const cache = await caches.open(cacheName);
    const cachedResponse = await cache.match(request);
    
    if (cachedResponse) {
      console.log('SW: Serving from cache:', request.url);
      return cachedResponse;
    }
    
    console.log('SW: Fetching and caching:', request.url);
    const networkResponse = await fetch(request);
    
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone());
    }
    
    return networkResponse;
  } catch (error) {
    console.error('SW: Cache first failed:', error);
    return new Response('Offline - Resource not available', {
      status: 503,
      statusText: 'Service Unavailable'
    });
  }
}

// Network first strategy (for dynamic content)
async function networkFirst(request, cacheName, timeout = 3000) {
  try {
    const cache = await caches.open(cacheName);
    
    // Try network with timeout
    const networkPromise = fetch(request);
    const timeoutPromise = new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Network timeout')), timeout)
    );
    
    try {
      const networkResponse = await Promise.race([networkPromise, timeoutPromise]);
      
      if (networkResponse.ok) {
        console.log('SW: Network success, caching:', request.url);
        cache.put(request, networkResponse.clone());
        return networkResponse;
      }
    } catch (networkError) {
      console.log('SW: Network failed, trying cache:', request.url);
    }
    
    // Fallback to cache
    const cachedResponse = await cache.match(request);
    if (cachedResponse) {
      console.log('SW: Serving stale from cache:', request.url);
      return cachedResponse;
    }
    
    // No cache available
    throw new Error('No cache available');
    
  } catch (error) {
    console.error('SW: Network first failed:', error);
    
    // Return offline page for navigation requests
    if (request.mode === 'navigate') {
      return new Response(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Offline - terrerov.com</title>
          <style>
            body { font-family: 'Space Mono', monospace; background: #0a0a0c; color: #f5f5f5; text-align: center; padding: 50px; }
            .offline { max-width: 400px; margin: 0 auto; }
          </style>
        </head>
        <body>
          <div class="offline">
            <h1>🌐 Offline</h1>
            <p>You're currently offline. Please check your connection and try again.</p>
            <button onclick="window.location.reload()">Retry</button>
          </div>
        </body>
        </html>
      `, {
        headers: { 'Content-Type': 'text/html' }
      });
    }
    
    return new Response('Offline', {
      status: 503,
      statusText: 'Service Unavailable'
    });
  }
}

// Background sync for GitHub data
self.addEventListener('sync', event => {
  if (event.tag === 'github-sync') {
    event.waitUntil(syncGitHubData());
  }
});

async function syncGitHubData() {
  try {
    console.log('SW: Syncing GitHub data...');
    const response = await fetch('https://api.github.com/users/terrerovgh/repos?sort=updated&per_page=5');
    
    if (response.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      await cache.put('https://api.github.com/users/terrerovgh/repos', response.clone());
      console.log('SW: GitHub data synced successfully');
    }
  } catch (error) {
    console.error('SW: GitHub sync failed:', error);
  }
}
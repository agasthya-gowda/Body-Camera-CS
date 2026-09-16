// Local dev-only reverse proxy.
//
// Problem: browsers refuse to let JS set the "Cookie" header, and block
// cross-origin credentialed requests unless the server echoes back the exact
// calling origin. Our real server's login uses a PHPSESSID cookie for every
// authenticated call, so testing the Flutter *web* build directly against
// http://116.73.243.111:8080 from a locally-served dev build (a different
// origin) silently loses the session after login.
//
// Fix for local testing: serve the Flutter dev server and the real API
// through one origin. The browser then treats every request as same-site and
// attaches the session cookie automatically - no code changes needed.
// (The permanent production fix is the same idea done for real: host the
// built web app on the same origin as the API, e.g. on 116.73.243.111 itself.)
//
// Usage:
//   1. flutter run -d web-server --web-port=8765   (in this project)
//   2. node tools/web_proxy.js
//   3. open http://localhost:8767  (not 8765)

const http = require('http');

const PROXY_PORT = 8767;
const FLUTTER_TARGET = { host: 'localhost', port: Number(process.env.FLUTTER_PORT) || 8765 };
const API_TARGET = { host: '116.73.243.111', port: 8080 };

const server = http.createServer((req, res) => {
  const isApi = req.url.startsWith('/rest/');
  const target = isApi ? API_TARGET : FLUTTER_TARGET;

  const proxyReq = http.request(
    {
      host: target.host,
      port: target.port,
      path: req.url,
      method: req.method,
      headers: { ...req.headers, host: `${target.host}:${target.port}` },
    },
    (proxyRes) => {
      res.writeHead(proxyRes.statusCode, proxyRes.headers);
      proxyRes.pipe(res, { end: true });
    },
  );

  proxyReq.on('error', (err) => {
    console.error(`Proxy error (${req.method} ${req.url}):`, err.message);
    if (!res.headersSent) res.writeHead(502, { 'Content-Type': 'text/plain' });
    res.end(`Proxy error reaching ${target.host}:${target.port}: ${err.message}`);
  });

  req.pipe(proxyReq, { end: true });
});

server.listen(PROXY_PORT, () => {
  console.log(`Dev proxy running at http://localhost:${PROXY_PORT}`);
  console.log(`  /rest/*  -> http://${API_TARGET.host}:${API_TARGET.port} (real server)`);
  console.log(`  other    -> http://${FLUTTER_TARGET.host}:${FLUTTER_TARGET.port} (flutter dev server)`);
});

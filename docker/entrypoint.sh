#!/usr/bin/env bash
set -euo pipefail

PORT=${PORT:-8080}

echo "Starting Vibe Kanban on port ${PORT} (placeholder)"

if command -v vibe-kanban >/dev/null 2>&1; then
  exec vibe-kanban --port ${PORT}
else
  # Start a minimal Python HTTP server that responds 200 on /health
  python3 - <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import os

port = int(os.environ.get('PORT', '8080'))

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        return

httpd = HTTPServer(('0.0.0.0', port), Handler)
print(f'Fallback health server listening on {port}')
httpd.serve_forever()
PY
fi

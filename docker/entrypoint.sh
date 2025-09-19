#!/usr/bin/env bash
set -euo pipefail

PORT=${PORT:-8080}

echo "Starting Vibe Kanban on port ${PORT} (placeholder)"

if command -v vibe-kanban >/dev/null 2>&1; then
  exec vibe-kanban --port ${PORT}
else
  python3 -m http.server ${PORT} &
  pid=$!
  trap "kill $pid" EXIT
  wait $pid
fi

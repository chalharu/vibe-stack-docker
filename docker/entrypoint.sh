#!/usr/bin/env bash
set -euo pipefail

PORT=${PORT:-8080}
export PORT

HOST=${HOST:-0.0.0.0}
export HOST

echo "Starting Vibe Kanban on ${HOST}:${PORT}"

 # vibe-kanban reads port from the PORT environment variable, do not pass --port
 exec vibe-kanban
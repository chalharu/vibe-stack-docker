#!/usr/bin/env bash
set -euo pipefail

# Entrypoint for Vibe Kanban
#
# Environment variables:
#   PORT        - port to listen on (default: 8080). Vibe Kanban reads this env var; do not pass --port.
#   SSHD_PORT   - port for sshd to listen on (default: 8022).
#   HOST        - host/address to bind to (default: 0.0.0.0).
#   DATA_DIR    - persistent data directory (default: /home/runner/.local/share/vibe-kanban).
#   VIBE_BIN    - path/name of the vibe-kanban executable (default: vibe-kanban).
#   GRACE_PERIOD- seconds to wait for graceful shutdown before SIGKILL (default: 10).

PORT=${PORT:-8080}
SSHD_PORT=${PORT:-8022}
HOST=${HOST:-0.0.0.0}
DATA_DIR=${DATA_DIR:-/home/runner/.local/share/vibe-kanban}
VIBE_BIN=${VIBE_BIN:-vibe-kanban}
GRACE_PERIOD=${GRACE_PERIOD:-10}

export PORT HOST DATA_DIR

sshd_pid=
if command -v "ssh-keygen" >/dev/null 2>&1; then
  # ssh-keygen -t rsa1 -N '' -f /home/runner/.ssh/ssh_host_key
  ssh-keygen -t rsa  -N '' -f /home/runner/.ssh/ssh_host_rsa_key
  ssh-keygen -t dsa  -N '' -f /home/runner/.ssh/ssh_host_dsa_key
  ssh-keygen -t ed25519  -N '' -f /home/runner/.ssh/ssh_host_ed25519_key
  ssh-keygen -t ecdsa  -N '' -f /home/runner/.ssh/ssh_host_ecdsa_key
  /usr/sbin/sshd \
    -h /home/runner/.ssh/ssh_host_rsa_key \
    -h /home/runner/.ssh/ssh_host_dsa_key \
    -h /home/runner/.ssh/ssh_host_ed25519_key \
    -h /home/runner/.ssh/ssh_host_ecdsa_key \
    -p ${SSHD_PORT} \
    -o PidFile=/home/runner/.sshd.pid
  sshd_pid=$(cat /home/runner/.sshd.pid)
fi

# Ensure data dir exists
mkdir -p "$DATA_DIR" || true

# Sanity check: ensure the binary exists
if ! command -v "$VIBE_BIN" >/dev/null 2>&1; then
  echo "Error: '$VIBE_BIN' not found in PATH. Ensure the package is installed." >&2
  exit 1
fi

echo "Starting Vibe Kanban on ${HOST}:${PORT} (DATA_DIR=${DATA_DIR})"

# Child PID placeholder
child_pid=

# Graceful shutdown function: forward SIGTERM/SIGINT to child and wait up to GRACE_PERIOD
shutdown() {
  echo "Entrypoint: received signal, initiating shutdown..."
  if [ -z "${child_pid:-}" ] && [ -z "${sshd_pid:-}" ]; then
    echo "Entrypoint: no child PID available, exiting"
    exit 0
  fi

  pids="$child_pid $sshd_pid"

  if ! kill -0 $pids 2>/dev/null; then
    echo "Entrypoint: child process $pids already exited"
    return
  fi

  # Ask the app to shutdown gracefully
  kill -TERM $pids 2>/dev/null || true

  # Wait up to GRACE_PERIOD seconds
  end=$((SECONDS + GRACE_PERIOD))
  while kill -0 $pids 2>/dev/null; do
    if [ "$SECONDS" -ge "$end" ]; then
      echo "Entrypoint: child did not exit after ${GRACE_PERIOD}s; sending SIGKILL"
      kill -KILL $pids 2>/dev/null || true
      break
    fi
    sleep 1
  done
}

trap 'shutdown' SIGTERM SIGINT

# Start the app in the background. Note: do not pass --port; the app reads PORT from env.
"$VIBE_BIN" &
child_pid=$!

# Wait for the app to exit and propagate its exit code
wait "$child_pid"
exit_code=$?

echo "Vibe Kanban exited with code $exit_code"
exit $exit_code

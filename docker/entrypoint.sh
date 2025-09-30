#!/usr/bin/env bash
set -euo pipefail

# Entrypoint for Vibe Kanban
#
# Environment variables:
#   PORT        - port to listen on (default: 8080). Vibe Kanban reads this env var; do not pass --port.
#   SSHD_PORT   - port for sshd to listen on (default: 8022).
#   HOST        - host/address to bind to (default: 0.0.0.0).
#   GRACE_PERIOD- seconds to wait for graceful shutdown before SIGKILL (default: 10).

PORT=${PORT:-8080}
SSHD_PORT=${SSHD_PORT:-8022}
HOST=${HOST:-0.0.0.0}
GRACE_PERIOD=${GRACE_PERIOD:-10}

export PORT SSHD_PORT HOST

sshd_pid=

echo "Starting Vibe Kanban on ${HOST}:${PORT})"

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
npx vibe-kanban &
child_pid=$!

if command -v "ssh-keygen" >/dev/null 2>&1; then
  # ssh-keygen -t rsa1 -N '' -f /home/runner/.ssh/ssh_host_key
  [ -f "/home/runner/.ssh/ssh_host_rsa_key" ] || ssh-keygen -t rsa  -N '' -f /home/runner/.ssh/ssh_host_rsa_key
  [ -f "/home/runner/.ssh/ssh_host_ed25519_key" ] || ssh-keygen -t ed25519  -N '' -f /home/runner/.ssh/ssh_host_ed25519_key
  [ -f "/home/runner/.ssh/ssh_host_ecdsa_key" ] || ssh-keygen -t ecdsa  -N '' -f /home/runner/.ssh/ssh_host_ecdsa_key
  chmod 600 /home/runner/.ssh/ssh_host_rsa_key \
    /home/runner/.ssh/ssh_host_ed25519_key \
    /home/runner/.ssh/ssh_host_ecdsa_key
  /usr/sbin/sshd \
    -h /home/runner/.ssh/ssh_host_rsa_key \
    -h /home/runner/.ssh/ssh_host_ed25519_key \
    -h /home/runner/.ssh/ssh_host_ecdsa_key \
    -p ${SSHD_PORT} \
    -o PidFile=/home/runner/.sshd.pid \
    -o StrictModes=no
  sshd_pid=$(cat /home/runner/.sshd.pid)
fi

# Wait for the app to exit and propagate its exit code
wait "$child_pid"
exit_code=$?

echo "Vibe Kanban exited with code $exit_code"
exit $exit_code

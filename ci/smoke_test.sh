#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

IMAGE=${1:-ghcr.io/chalharu/vibe-stack-docker:local}
CONTAINER=${2:-test_vibe_smoke}
HOST_PORT=${3:-8080}
CONTAINER_PORT=${4:-8080}
HEALTH_PATH=${HEALTH_PATH:-/api/health}
MAX_RETRIES=${MAX_RETRIES:-30}
SLEEP_SECONDS=${SLEEP_SECONDS:-1}

cleanup() {
  echo "Collecting container logs..."
  docker logs "${CONTAINER}" || true
  echo "Removing container ${CONTAINER}..."
  docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found; please install Docker" >&2
  exit 2
fi

echo "Image: ${IMAGE}"
echo "Container: ${CONTAINER}"

echo "Attempting to pull image ${IMAGE}..."
if docker pull "${IMAGE}"; then
  echo "Pulled image ${IMAGE}"
else
  echo "Pull failed; attempting to build image from repository Dockerfile..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
  if [ -f "${REPO_ROOT}/Dockerfile" ]; then
    echo "Building image ${IMAGE} from ${REPO_ROOT}/Dockerfile..."
    docker build -t "${IMAGE}" -f "${REPO_ROOT}/Dockerfile" "${REPO_ROOT}"
  else
    echo "No Dockerfile found at ${REPO_ROOT}/Dockerfile; cannot build image" >&2
    exit 3
  fi
fi

# ensure no leftover container
docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true

echo "Starting container ${CONTAINER} (host ${HOST_PORT} -> container ${CONTAINER_PORT})..."
docker run -d --name "${CONTAINER}" -p "${HOST_PORT}:${CONTAINER_PORT}" "${IMAGE}"

URL="http://localhost:${HOST_PORT}${HEALTH_PATH}"
echo "Waiting for ${URL} (up to ${MAX_RETRIES} attempts)..."

for i in $(seq 1 "${MAX_RETRIES}"); do
  if curl -s -f "${URL}" >/dev/null 2>&1; then
    echo "smoke test passed"
    exit 0
  fi
  echo "Attempt ${i}/${MAX_RETRIES} failed; sleeping ${SLEEP_SECONDS}s..."
  sleep "${SLEEP_SECONDS}"
  CONTAINER_RUNNING="$(docker ps -q -f name="^/${CONTAINER}$" || true)"
  if [ -z "${CONTAINER_RUNNING:-}" ]; then
    echo "Container ${CONTAINER} exited or is not running. Showing logs:"
    docker logs "${CONTAINER}" || true
    break
  fi
done

echo "smoke test failed"
exit 1

#!/usr/bin/env bash
set -euo pipefail

IMAGE=${1:-ghcr.io/chalharu/vibe-stack-docker:local}
CONTAINER_NAME=test_vibe_health

docker rm -f ${CONTAINER_NAME} >/dev/null 2>&1 || true
docker run -d --name ${CONTAINER_NAME} -p 8080:8080 ${IMAGE} || exit 2

trap 'docker logs ${CONTAINER_NAME} || true; docker rm -f ${CONTAINER_NAME} >/dev/null 2>&1' EXIT

for i in {1..30}; do
  sleep 1
  if curl -s -f http://localhost:8080/health >/dev/null 2>&1; then
    echo "health ok"
    STATUS=$(curl -s http://localhost:8080/health)
    echo "response: ${STATUS}"
    exit 0
  fi
done

echo "health endpoint did not respond"
exit 1

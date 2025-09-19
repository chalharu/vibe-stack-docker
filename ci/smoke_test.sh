#!/usr/bin/env bash
set -euo pipefail

IMAGE=${1:-ghcr.io/chalharu/vibe-stack-docker:local}
CONTAINER=test_vibe_smoke

docker rm -f ${CONTAINER} >/dev/null 2>&1 || true
docker run -d --name ${CONTAINER} -p 8080:8080 ${IMAGE}
trap 'docker logs ${CONTAINER} || true; docker rm -f ${CONTAINER} >/dev/null 2>&1' EXIT

for i in {1..30}; do
  sleep 1
  if curl -s -f http://localhost:8080/health >/dev/null 2>&1; then
    echo "smoke test passed"
    exit 0
  fi
done

echo "smoke test failed"
exit 1

#!/usr/bin/env bash
set -euo pipefail

IMAGE=${1:-ghcr.io/chalharu/vibe-stack-docker:local}
CONTAINER_NAME=test_vibe_health
PORT=8080
HEALTH_URL="http://localhost:${PORT}/api/health"
EXPECTED_BODY='{"success":true,"data":"OK","error_data":null,"message":null}'

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker run -d --name "${CONTAINER_NAME}" -p ${PORT}:${PORT} "${IMAGE}" || exit 2

trap 'docker logs "${CONTAINER_NAME}" || true; docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1' EXIT

for i in {1..30}; do
  sleep 1
  response=$(curl -s -w "HTTPSTATUS:%{http_code}" "${HEALTH_URL}" || echo "HTTPSTATUS:000")
  http_code="${response##*HTTPSTATUS:}"
  body="${response%HTTPSTATUS:*}"
  # Trim CR/LF and surrounding whitespace
  body="$(echo -n "$body" | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [ "${http_code}" = "200" ]; then
    echo "health response body: ${body}"
    if [ "${body}" = "${EXPECTED_BODY}" ]; then
      echo "health endpoint OK"
      exit 0
    else
      echo "unexpected body: ${body}"
      echo "expected: ${EXPECTED_BODY}"
      exit 1
    fi
  fi
done

echo "health endpoint did not respond with HTTP 200"
exit 1

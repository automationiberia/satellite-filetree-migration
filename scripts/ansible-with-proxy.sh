#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRIDGE_SCRIPT="${ROOT_DIR}/scripts/http-socks-bridge.py"
BRIDGE_PORT=18118
HTTP_PROXY_URL="http://127.0.0.1:${BRIDGE_PORT}"

if ! (echo >/dev/tcp/127.0.0.1/"${BRIDGE_PORT}") 2>/dev/null; then
  echo "Starting HTTP-to-SOCKS bridge on port ${BRIDGE_PORT}..."
  "${BRIDGE_SCRIPT}" &
  BRIDGE_PID=$!
  trap 'kill "${BRIDGE_PID}" 2>/dev/null || true' EXIT
  sleep 1
fi

export HTTP_PROXY="${HTTP_PROXY_URL}"
export HTTPS_PROXY="${HTTP_PROXY_URL}"
export NO_PROXY="localhost,127.0.0.1"

cd "${ROOT_DIR}"
exec ansible-playbook "$@"

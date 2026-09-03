#!/usr/bin/env bash
# Export HTTP_PROXY for Ansible and start the HTTP→SOCKS bridge when needed.
# Requires a SOCKS5 proxy on localhost:51313 (VPN, ssh -D, etc.).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRIDGE_SCRIPT="${ROOT_DIR}/scripts/http-socks-bridge.py"
BRIDGE_PORT=18118
HTTP_PROXY_URL="http://127.0.0.1:${BRIDGE_PORT}"

export HTTP_PROXY="${HTTP_PROXY:-${HTTP_PROXY_URL}}"
export HTTPS_PROXY="${HTTPS_PROXY:-${HTTP_PROXY_URL}}"
export NO_PROXY="${NO_PROXY:-localhost,127.0.0.1}"

if ! (echo >/dev/tcp/127.0.0.1/"${BRIDGE_PORT}") 2>/dev/null; then
  if ! pgrep -f "${BRIDGE_SCRIPT}" >/dev/null 2>&1; then
    echo "Starting HTTP-to-SOCKS bridge on port ${BRIDGE_PORT} (upstream SOCKS5 localhost:51313)..."
    "${BRIDGE_SCRIPT}" &
    sleep 1
  fi
fi

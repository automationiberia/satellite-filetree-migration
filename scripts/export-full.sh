#!/usr/bin/env bash
# Full export from satellite_source into satellite_config/.
# Requires HTTP_PROXY at shell level for Jinja url lookups in content_views templates.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# shellcheck source=ensure-http-proxy.sh
source "${ROOT_DIR}/scripts/ensure-http-proxy.sh"

echo "=== FULL EXPORT: satellite-drs -> satellite_config/ ==="
ansible-playbook playbooks/export.yml -e @vars/satellite.yml "$@"

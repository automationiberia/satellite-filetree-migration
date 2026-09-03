#!/usr/bin/env bash
# Demo workflow: bulk → export → filter → import (LE + locations + manifest).
# See DEMO.md for the presenter script.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# shellcheck source=ensure-http-proxy.sh
source "${ROOT_DIR}/scripts/ensure-http-proxy.sh"

STEP="${1:-}"

case "${STEP}" in
  0|cleanup)
    if [ -d "${ROOT_DIR}/satellite_config_demo" ]; then
      echo "=== DEMO STEP 0: Cleanup demo objects on target Satellite (LE, locations, manifest) ==="
      ansible-playbook playbooks/cleanup_demo.yml \
        -e @vars/satellite.yml \
        -e @vars/demo.yml
    else
      echo "=== DEMO STEP 0: Skipping demo cleanup (satellite_config_demo/ not found) ==="
    fi
    ;;
  100|full-cleanup)
    echo "=== DEMO STEP 100: Factory reset target Satellite (all orgs except Default Organization) ==="
    ansible-playbook playbooks/cleanup.yml -e @vars/satellite.yml
    rm -rf "${ROOT_DIR}/satellite_config_demo" "${ROOT_DIR}/satellite_config"
    ;;
  1|bulk)
    echo "=== DEMO STEP 1: Bulk import (domains, CVs, subnets, etc.; ~30s) ==="
    ./scripts/run-bulk-import.sh
    ;;
  2|export)
    echo "=== DEMO STEP 2: Export organizations, lifecycle environments and locations ==="
    ansible-playbook playbooks/export.yml \
      -e @vars/satellite.yml \
      -e @vars/demo.yml \
      --tags organizations,lifecycle_environments,locations,vault_template
    ;;
  3|filter)
    echo "=== DEMO STEP 3: Filter CaC for target organization ==="
    ansible-playbook playbooks/filter_organization.yml \
      -e @vars/satellite.yml \
      -e @vars/demo.yml
    ;;
  4|import)
    echo "=== DEMO STEP 4: Import org skeleton + lifecycle environments + locations + manifest ==="
    ansible-playbook playbooks/import.yml \
      -e @vars/satellite.yml \
      -e @vars/demo.yml \
      -e @vars/vault_import.yml \
      --tags organizations,lifecycle_environments,locations,manifest,manifest_validate
    ;;
  *)
    cat <<'EOF'
Usage: ./scripts/demo.sh <step>

    0 | cleanup       Remove demo objects only (LE, locations, manifest) from target Satellite
    1 | bulk          Bulk import from satellite_config/ (~30s; skips LE, locations, manifest)
    2 | export        Export org + lifecycle environments + locations from source Satellite
    3 | filter        Keep only satellite_organization_name objects in satellite_config_demo/
    4 | import        Apply LE + locations + manifest on target Satellite
  100 | full-cleanup  Factory reset target + wipe local CaC (prep only — run BEFORE export-full.sh)

Prerequisites for steps 1–4: export-full.sh + filter_organization.yml on satellite_config/
Full presenter script: DEMO.md
EOF
    exit 1
    ;;
esac

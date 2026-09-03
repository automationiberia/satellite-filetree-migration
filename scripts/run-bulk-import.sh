#!/usr/bin/env bash
# Import all red_ribbon CaC from satellite_config/ except lifecycle_environments,
# locations and manifest (shown in the 3-step demo).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# shellcheck source=ensure-http-proxy.sh
source "${ROOT_DIR}/scripts/ensure-http-proxy.sh"

echo "=== BULK IMPORT: skip demo objects + settings + ldap + roles (other-org refs) ==="
ansible-playbook playbooks/import.yml \
  -e @vars/satellite.yml \
  -e @vars/vault_import.yml \
  -e @vars/bulk_import.yml \
  --skip-tags lifecycle_environments,locations,manifest,manifest_validate,settings,auth_sources_ldap,roles,users,usergroups,activation_keys,partition_tables,provisioning_templates,operatingsystems,installation_mediums,job_templates,hostgroups

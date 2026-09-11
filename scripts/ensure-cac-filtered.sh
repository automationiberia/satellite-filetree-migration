#!/usr/bin/env bash
# Ensure satellite_config/ is scoped to satellite_organization_name before bulk import.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

VARS_FILE="${ROOT_DIR}/vars/satellite.yml"
if [ ! -f "${VARS_FILE}" ]; then
  echo "ERROR: ${VARS_FILE} not found. Copy vars/satellite.yml.example and configure it." >&2
  exit 1
fi

TARGET_ORG="$(awk -F': ' '/^satellite_organization_name:/ {print $2; exit}' "${VARS_FILE}" | tr -d '"')"
if [ -z "${TARGET_ORG}" ]; then
  echo "ERROR: satellite_organization_name is not set in ${VARS_FILE}" >&2
  exit 1
fi

CAC_PATH="${ROOT_DIR}/satellite_config"
if [ ! -d "${CAC_PATH}" ]; then
  echo "ERROR: ${CAC_PATH} not found. Run ./scripts/export-full.sh first." >&2
  exit 1
fi

ORG_SCOPED_DIRS=(
  satellite_activation_keys.d
  satellite_products.d
  satellite_content_views.d
  satellite_lifecycle_environments.d
  satellite_sync_plans.d
  satellite_host_collections.d
  satellite_content_credentials.d
  satellite_content_view_filters.d
  satellite_repositories.d
  satellite_repository_sets.d
)

foreign_orgs=()
for dir in "${ORG_SCOPED_DIRS[@]}"; do
  fragment_dir="${CAC_PATH}/${dir}"
  [ -d "${fragment_dir}" ] || continue
  while IFS= read -r line; do
    org="${line#  organization: }"
    if [ "${org}" != "${TARGET_ORG}" ]; then
      foreign_orgs+=("${org}")
    fi
  done < <(grep -h '^  organization:' "${fragment_dir}"/*.yaml 2>/dev/null || true)
done

orgs_file="${CAC_PATH}/satellite_organizations.d/satellite_organizations.yaml"
if [ -f "${orgs_file}" ]; then
  while IFS= read -r line; do
    org="${line#  name: }"
    if [ "${org}" != "${TARGET_ORG}" ]; then
      foreign_orgs+=("${org}")
    fi
  done < <(grep '^  name:' "${orgs_file}" 2>/dev/null || true)
fi

if [ "${#foreign_orgs[@]}" -eq 0 ]; then
  echo "=== CaC filter check: ${CAC_PATH} is scoped to '${TARGET_ORG}' ==="
  exit 0
fi

mapfile -t unique_foreign < <(printf '%s\n' "${foreign_orgs[@]}" | sort -u)
echo "=== CaC filter check: found other organizations in ${CAC_PATH}: ${unique_foreign[*]} ==="
echo "=== Running filter_organization.yml for '${TARGET_ORG}' ==="
ansible-playbook playbooks/filter_organization.yml -e @"${VARS_FILE}"

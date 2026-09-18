#!/usr/bin/env bash
# Syntax-check all playbooks with example vars (no Satellite connectivity).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck source=scripts/ci-ansible-env.sh
source "${ROOT}/scripts/ci-ansible-env.sh"

export ANSIBLE_LOCAL_TEMP="${ROOT}/.ansible/tmp"

mkdir -p "${ANSIBLE_LOCAL_TEMP}" collections

if [[ ! -d collections/ansible_collections/infra/satellite_configuration ]] \
  || [[ ! -d collections/ansible_collections/redhat/satellite ]]; then
  "${ROOT}/scripts/ci-install-collections.sh"
fi

mkdir -p satellite_config
cp vars/vault_import.yml.example satellite_config/vault_template.yaml

extra_vars=(
  -e "@vars/satellite.yml.example"
  -e "@vars/demo.yml"
  -e "@vars/bulk_import.yml"
)

for playbook in playbooks/*.yml; do
  echo "==> syntax-check ${playbook}"
  ansible-playbook "${playbook}" "${extra_vars[@]}" --syntax-check
done

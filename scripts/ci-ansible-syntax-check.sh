#!/usr/bin/env bash
# Syntax-check all playbooks with example vars (no Satellite connectivity).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export ANSIBLE_LOCAL_TEMP="${ROOT}/.ansible/tmp"
export ANSIBLE_COLLECTIONS_PATH="${ROOT}/collections:${HOME}/.ansible/collections:/usr/share/ansible/collections"

mkdir -p "${ANSIBLE_LOCAL_TEMP}" collections

if [[ ! -d collections/ansible_collections/infra/satellite_configuration ]]; then
  ansible-galaxy collection install -r requirements.yml -p collections
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

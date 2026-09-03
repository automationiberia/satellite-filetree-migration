#!/usr/bin/env bash
# Run Ansible syntax-check and ansible-lint (used by pre-commit and CI).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export ANSIBLE_COLLECTIONS_PATH="${ROOT}/collections:${HOME}/.ansible/collections:/usr/share/ansible/collections"

"${ROOT}/scripts/ci-ansible-syntax-check.sh"
ansible-lint playbooks/

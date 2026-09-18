#!/usr/bin/env bash
# Run Ansible syntax-check and ansible-lint (used by pre-commit and CI).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck source=scripts/ci-ansible-env.sh
source "${ROOT}/scripts/ci-ansible-env.sh"

"${ROOT}/scripts/ci-ansible-syntax-check.sh"
ansible-lint playbooks/

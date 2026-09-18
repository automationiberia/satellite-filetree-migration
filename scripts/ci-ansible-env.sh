#!/usr/bin/env bash
# Shared Ansible env for CI / pre-commit. Sourced by other ci-ansible-*.sh scripts.
#
# ansible-lint ships with "#!/usr/bin/python3 -sP" (no user site-packages).
# A pip --user ansible-core can then make `ansible` CLI report a different
# core version than ansible-lint, which aborts with a version-mismatch error.
# Prefer the same isolation for all Ansible tooling in CI.

export PYTHONNOUSERSITE=1
export ANSIBLE_COLLECTIONS_PATH="${ROOT}/collections:${HOME}/.ansible/collections:/usr/share/ansible/collections"

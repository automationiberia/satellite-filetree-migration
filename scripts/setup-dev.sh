#!/usr/bin/env bash
# Install development tooling and register git pre-commit hooks.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 -m pip install -r ci/requirements.txt
ansible-galaxy collection install -r requirements.yml -p collections
pre-commit install

echo "Pre-commit hooks installed. Run all checks with: pre-commit run --all-files"

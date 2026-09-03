#!/usr/bin/env bash
# Create local config files from examples (idempotent).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

mkdir -p manifests

for file in satellite vault_import; do
  target="vars/${file}.yml"
  example="vars/${file}.yml.example"
  if [ -f "${target}" ]; then
    echo "Keep existing ${target}"
  else
    cp "${example}" "${target}"
    echo "Created ${target} from ${example} — edit before use"
  fi
done

if [ ! -d .venv ]; then
  echo "Tip: create a venv and install deps: python3 -m venv .venv && .venv/bin/pip install requests pyyaml pysocks"
fi

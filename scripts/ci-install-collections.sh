#!/usr/bin/env bash
# Install Ansible collections for CI / pre-commit without Automation Hub secrets.
#
# redhat.satellite is Hub-only. CI installs the public theforeman.foreman twin
# from Galaxy and aliases it as redhat.satellite so playbook FQCNs and
# group/redhat.satellite.satellite module_defaults resolve for syntax-check
# and ansible-lint.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COLLECTIONS_PATH="${ROOT}/collections"
TF="${COLLECTIONS_PATH}/ansible_collections/theforeman/foreman"
RS="${COLLECTIONS_PATH}/ansible_collections/redhat/satellite"

mkdir -p "${COLLECTIONS_PATH}"

echo "==> Installing Galaxy collections (no Automation Hub)"
# --no-deps: infra.satellite_configuration declares Hub-only redhat.satellite.
ansible-galaxy collection install -r "${ROOT}/ci/requirements.yml" \
  -p "${COLLECTIONS_PATH}" \
  --force \
  --no-deps

if [[ ! -d "${TF}" ]]; then
  echo "ERROR: theforeman.foreman not found under ${COLLECTIONS_PATH}" >&2
  exit 1
fi

echo "==> Aliasing theforeman.foreman as redhat.satellite for CI"
mkdir -p "${COLLECTIONS_PATH}/ansible_collections/redhat"
rm -rf "${RS}"
cp -a "${TF}" "${RS}"

python3 - "${RS}" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
manifest_path = root / "MANIFEST.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest["collection_info"]["namespace"] = "redhat"
manifest["collection_info"]["name"] = "satellite"
manifest_path.write_text(json.dumps(manifest, indent=1) + "\n", encoding="utf-8")

runtime_path = root / "meta" / "runtime.yml"
if runtime_path.is_file():
    text = runtime_path.read_text(encoding="utf-8")
    text = text.replace("theforeman.foreman.", "redhat.satellite.")
    text = re.sub(
        r"(?m)^(action_groups:\n)  foreman:",
        r"\1  satellite:",
        text,
        count=1,
    )
    runtime_path.write_text(text, encoding="utf-8")
PY

echo "==> Collections ready under ${COLLECTIONS_PATH}"
ansible-galaxy collection list -p "${COLLECTIONS_PATH}" 2>/dev/null \
  | grep -E 'infra\.satellite_configuration|redhat\.satellite|theforeman\.foreman' \
  || true

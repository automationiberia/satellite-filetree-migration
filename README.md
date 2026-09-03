# satellite-filetree-migration

Ansible playbooks and scripts to migrate a Red Hat Satellite organization between instances using the [`infra.satellite_configuration`](https://github.com/ansible-automation-platform/infra.satellite_configuration) collection.

The collection’s **filetree** workflow drives this repo:

| Role | Purpose in this repo |
|------|----------------------|
| `filetree_create` | Export Satellite config to YAML (`playbooks/export.yml`) |
| `filetree_read` + `dispatch` | Import YAML back to a target Satellite (`playbooks/import.yml`) |

Typical flow: **export** from a source Satellite → **filter** for one organization → **import** to a target Satellite, with a scripted live-demo path for lifecycle environments, locations, and subscription manifest.

## Quick start

```bash
# 1. Install collections
ansible-galaxy collection install -r requirements.yml

# 2. Optional: Python deps for proxy bridge
python3 -m venv .venv
.venv/bin/pip install requests pyyaml pysocks

# 3. Local configuration (gitignored)
./scripts/setup-local.sh
# Edit vars/satellite.yml and vars/vault_import.yml

# 4. Place subscription manifest zip under manifests/ (see vars/satellite.yml)
```

## Layout

```
├── playbooks/          # export, import, filter, cleanup
├── scripts/            # demo.sh, export-full.sh, proxy bridge
├── vars/               # *.yml.example templates; copy to local *.yml
├── satellite_config/   # full export (gitignored, generated)
├── satellite_config_demo/  # demo export (gitignored, generated)
└── DEMO.md             # live demo presenter script
```

## Main commands

| Command | Purpose |
|---------|---------|
| `./scripts/export-full.sh` | Full export from source → `satellite_config/` |
| `ansible-playbook playbooks/filter_organization.yml -e @vars/satellite.yml` | Filter CaC for `satellite_organization_name` |
| `./scripts/run-bulk-import.sh` | Bulk import (skips LE, locations, manifest) |
| `./scripts/demo.sh <step>` | Scripted demo workflow (see `DEMO.md`) |

## Configuration

Copy and customize:

- `vars/satellite.yml.example` → `vars/satellite.yml` — hostnames, credentials, organization name, manifest path
- `vars/vault_import.yml.example` → `vars/vault_import.yml` — secrets for import (passwords, hidden parameters)

Both target files are **gitignored** so you can keep environment-specific values locally.

## Network / SOCKS proxy

If Satellites are reachable only through a SOCKS5 tunnel (`localhost:51313`), scripts start an HTTP→SOCKS bridge on `localhost:18118` automatically. Set `HTTP_PROXY` is handled by `scripts/ensure-http-proxy.sh`.

For full export, use `./scripts/export-full.sh` (not bare `ansible-playbook`) so Jinja `url` lookups in templates use the proxy.

## Demo

See **[DEMO.md](DEMO.md)** for preparation steps, live presenter script, and troubleshooting.

## License

Use and adapt as needed for workshops and internal migrations.

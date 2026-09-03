# Demo script: organization migration with Configuration as Code

Presenter guide for migrating an organization with the [`infra.satellite_configuration`](https://github.com/redhat-cop/infra.satellite_configuration) collection (`filetree_create` → filter → `filetree_read` / `dispatch`).

Set `satellite_organization_name` in `vars/satellite.yml` (default in the example: `example_org`).
Migration from `satellite-source.example.com` → `satellite-target.example.com`.

---

## Demo architecture

| Phase | Directory | What it does | When |
|-------|-----------|--------------|------|
| **Preparation** | `satellite_config/` | Factory reset (optional) → full export → filter | Before the session (or the night before) |
| **Live demo** | `satellite_config/` + `satellite_config_demo/` | Bulk → demo export → filter → skeleton import | In front of the audience |
| **Reset (demo only)** | — | Step 0: undo skeleton import | Between live runs, without re-exporting |

### Live steps (1–4)

| Step | What it does | Approx. duration |
|------|--------------|------------------|
| **1 — Bulk** | Imports domains, CVs, subnets, sync plans, host collections… | ~30 s |
| **2 — Export** | Exports org + LE + locations from source | ~1 min |
| **3 — Filter** | Keeps only the target organization in demo CaC | ~5 s |
| **4 — Import** | Applies org skeleton + manifest on target | ~1 min |

### What each step imports

| Object | Bulk (step 1) | Demo import (step 4) |
|--------|---------------|----------------------|
| Domains, subnets, CVs, sync plans… | ✅ | — |
| Target organization | ✅ (skeleton) | ✅ |
| Lifecycle environments | — | ✅ |
| Locations | — | ✅ |
| Subscription manifest | — | ✅ |

---

## Network and proxy

### Is the SOCKS bridge required?

**Only if you do not have direct access to the Satellites from your machine.**

| Scenario | Bridge required? |
|----------|------------------|
| VPN / internal network with direct access to Satellite hostnames | **No** |
| SOCKS5 only on `localhost:51313` (e.g. `ssh -D 51313`) | **Yes** |

Ansible understands `HTTP_PROXY`, not `socks5://`. The bridge (`http://127.0.0.1:18118` → SOCKS `51313`) acts as a translator.

All demo scripts (`demo.sh`, `run-bulk-import.sh`, `export-full.sh`) configure the proxy via `ensure-http-proxy.sh`.

**External requirement:** SOCKS5 active on `localhost:51313` (VPN, SSH tunnel, etc.).

---

## Preparation (once, before the session)

Run these steps **in order**. Step 100 is optional but, if used, **must come before** `export-full.sh` — it deletes local `satellite_config/` and `satellite_config_demo/`, so running it after export would wipe the CaC you just generated.

| Step | Command | Satellite | What it does |
|------|---------|-----------|--------------|
| **100** (optional) | `./scripts/demo.sh 100` | **Target** | Factory reset: all orgs except Default Organization, globals, local CaC dirs |
| **—** | `./scripts/export-full.sh` | **Source** | Full export → `satellite_config/` (~10 min) |
| **—** | `ansible-playbook playbooks/filter_organization.yml …` | — | Filter CaC to target organization only |

```bash
# 1. Optional: reset target + remove local CaC (run only before a fresh export)
./scripts/demo.sh 100

# 2. Export from source (requires HTTP_PROXY — handled by the script)
./scripts/export-full.sh

# 3. Filter for target organization
ansible-playbook playbooks/filter_organization.yml -e @vars/satellite.yml
```

> **Step 100 — what to say (if you run it on stage):** *"We start from a clean target Satellite with only the Default Organization. This also clears any local CaC from previous runs so the next export is fresh."*

**Check before going on stage:**

- [ ] `vars/satellite.yml` and `vars/vault_import.yml` configured
- [ ] `satellite_config/` generated and filtered (steps 2–3; or 1–3 if you ran factory reset)
- [ ] Manifest zip in `manifests/` (path set in `vars/satellite.yml`)
- [ ] SOCKS5 active on `localhost:51313` (if needed)

**Do not run step 100 during the live demo** — it is preparation only. The live session starts at step 1 (bulk import).

---

## Live demo script

### Step 1 — Bulk import (~30 s)

```bash
./scripts/demo.sh 1
```

Imports from `satellite_config/` everything except LE, locations, and manifest (reserved for step 4).

> **What to say:** *"First we apply the organization's operational configuration: domains, content views, subnets, sync plans… In about 30 seconds we have the organization base on the target."*

---

### Step 2 — Export org skeleton

```bash
./scripts/demo.sh 2
```

| | |
|---|---|
| **Source** | `satellite_source.server_url` in `vars/satellite.yml` |
| **Output** | `satellite_config_demo/` |
| **Tags** | `organizations`, `lifecycle_environments`, `locations`, `vault_template` |

> **What to say:** *"Now we export the organization skeleton from the source Satellite: org, lifecycle environments, and locations."*

---

### Step 3 — Multi-org filter

```bash
./scripts/demo.sh 3
```

Filters CaC to keep only objects for `satellite_organization_name`. Shared locations end up with a single organization in their list.

> **What to say:** *"The source is multi-org. We filter the CaC before importing to the target."*

---

### Step 4 — Skeleton import + manifest

```bash
./scripts/demo.sh 4
```

| | |
|---|---|
| **Target** | `satellite_target.server_url` in `vars/satellite.yml` |
| **Tags** | `organizations`, `lifecycle_environments`, `locations`, `manifest`, `manifest_validate` |
| **Secrets** | `vars/vault_import.yml` |
| **Manifest** | local zip file |

> **What to say:** *"Finally we apply lifecycle environments, locations, and the subscription manifest. With that, the organization is operational on the target."*

**Verify in the UI:** Administer → Organizations → your organization name.

---

### Step 0 — Repeat only step 4 (without factory reset)

If you have already run the demo and want to repeat only the skeleton + manifest part:

```bash
./scripts/demo.sh 0    # removes LE, locations, manifest
./scripts/demo.sh 4    # re-imports (steps 2–3 not needed if CaC unchanged)
```

---

## Command summary

```bash
# Preparation (before the session — run in this order)
./scripts/demo.sh 100    # optional; target reset + wipe local CaC — BEFORE export-full
./scripts/export-full.sh
ansible-playbook playbooks/filter_organization.yml -e @vars/satellite.yml

# Live demo (steps 1–4 only; preparation must already be done)
./scripts/demo.sh 1      # bulk import
./scripts/demo.sh 2      # export skeleton
./scripts/demo.sh 3      # filter organization
./scripts/demo.sh 4      # import + manifest

# Repeat skeleton import only (no factory reset, no re-export)
./scripts/demo.sh 0 && ./scripts/demo.sh 4
```

---

## Audience FAQ

**Why two imports (bulk + demo)?**
Bulk brings operational configuration (repos, CVs, subnets…) quickly. The demo shows the visible core of a migration: LE, locations, and manifest.

**Why is `vault_import.yml` needed?**
Hidden parameters or target-specific values that export cannot carry in plain text.

**How do I reset everything?**
`./scripts/demo.sh 100` — preparation only, **before** `export-full.sh`. Resets the target and deletes local `satellite_config/`. Then re-run export + filter.

---

## Troubleshooting

| Error | Solution |
|-------|----------|
| `satellite is undefined` | Add `tags: always` to the connection `set_fact` task in `export.yml` / `import.yml` |
| `Found no results while searching for organizations with name="…"` | Run `./scripts/demo.sh 3` to filter locations and other shared objects |
| `vault_satellite_location_parameters is undefined` | Fill in `vars/vault_import.yml` |
| Manifest download from Customer Portal | Set `manifest_download: false` in `vars/satellite.yml` |
| `TLSV1_UNRECOGNIZED_NAME` on export | Use `./scripts/export-full.sh` (`HTTP_PROXY` required in shell) |

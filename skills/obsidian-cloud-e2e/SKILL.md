---
name: obsidian-cloud-e2e
description: >-
  Cursor Cloud Linux synthetic vault and Obsidian E2E — AppImage under Xvfb,
  fixture notes, CDP secret injection from environment variables into
  secretStorage. Use when setting up or running Cloud Agent in-vault tests.
---

# Cloud Linux Obsidian E2E

This is **not** the Windows staging vault. Cloud Agents use a synthetic vault at `$HOME/plugin-sandbox-Obsidian` and an isolated `--user-data-dir`.

**Baking / repairing the whole environment** (sample files, toggles, snapshot/Save): [obsidian-cloud-env-setup](../obsidian-cloud-env-setup/SKILL.md).

Scripts: [`scripts/cloud-e2e/README.md`](../../scripts/cloud-e2e/README.md).

## Secrets (required pattern)

Cursor environment / user secrets appear as process env vars on the agent pod.

1. Never write keys to `data.json`, git, or Install snapshots.
2. Never interpolate keys into `obsidian eval code=...` (argv + logs).
3. After Obsidian is up: `node scripts/cloud-e2e/cdp.mjs inject`
4. Verify with **length only** via `cdp.mjs eval`.

See [obsidian-secret-mapping](../obsidian-secret-mapping/SKILL.md) for how each plugin **reads** ids (pointers vs hardcoded). Inject uses merged `<repo>/.cloud-e2e/secret-bindings.json`.

`node scripts/cloud-e2e/cdp.mjs probe` — env-set flag, id lengths, pointer values. Unset Cursor secrets skip inject.

## Boot

```bash
bash scripts/cloud-e2e/env-install.sh
bash scripts/cloud-e2e/env-start.sh   # dismiss-starter → enable-plugins → enable-cli → inject
export PATH="$HOME/.local/bin:$PATH"
obsidian vault=plugin-sandbox-Obsidian files
```

Full walkthrough (Restricted mode, CLI toggle, sample files): [`scripts/cloud-e2e/GETTING-STARTED.md`](../../scripts/cloud-e2e/GETTING-STARTED.md).

**Seinfeld (custom)** AI21 trivia corpus (episodes + Q&A notes) is materialized on install. Companion skill: [seek-seinfeld-eval](../seek-seinfeld-eval/SKILL.md).

Identity: `name` must be `plugin-sandbox-Obsidian`. `base` must be `CLOUD_E2E_VAULT`. Community plugins and CLI must both be enabled (see Getting Started).


## What this proves vs Windows sandbox

| Cloud E2E | Still Windows/self-hosted |
| --- | --- |
| Plugin load, CLI-equivalent CDP eval, Seek search over fixture notes, secret injection | 3k-note cold index, production-shaped vault, ACP CLIs you only installed locally |

See also [obsidian-settings-secrets](../obsidian-settings-secrets/SKILL.md) and [obsidian-plugin-sandbox](../obsidian-plugin-sandbox/SKILL.md).

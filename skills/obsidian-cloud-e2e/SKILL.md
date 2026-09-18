---
name: obsidian-cloud-e2e
description: >-
  Cursor Cloud Linux synthetic vault and Obsidian E2E — AppImage under Xvfb,
  fixture notes, CDP secret injection from environment variables into
  secretStorage. Use when setting up or running Cloud Agent in-vault tests.
---

# Cloud Linux Obsidian E2E

This is **not** the Windows staging vault. Cloud Agents use a synthetic vault at `$HOME/plugin-sandbox-Obsidian` and an isolated `--user-data-dir`.

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
./scripts/cloud-e2e/install-obsidian.sh
# npm run build in seek, whisper, agent-client
./scripts/cloud-e2e/materialize-vault.sh   # includes AI21 Seinfeld episodes via materialize-seinfeld.sh
# terminals: start-obsidian.sh (foreground)
node scripts/cloud-e2e/cdp.mjs wait
node scripts/cloud-e2e/cdp.mjs inject   # skips unset env vars
node scripts/cloud-e2e/cdp.mjs eval 'JSON.stringify({name:app.vault.getName(),base:app.vault.adapter.basePath})'
```

Identity: `name` must be `plugin-sandbox-Obsidian`. `base` must be `CLOUD_E2E_VAULT`.

## What this proves vs Windows sandbox

| Cloud E2E | Still Windows/self-hosted |
| --- | --- |
| Plugin load, CLI-equivalent CDP eval, Seek search over fixture notes, secret injection | 3k-note cold index, production-shaped vault, ACP CLIs you only installed locally |

See also [obsidian-settings-secrets](../obsidian-settings-secrets/SKILL.md) and [obsidian-plugin-sandbox](../obsidian-plugin-sandbox/SKILL.md).

---
name: obsidian-cloud-env-setup
description: >-
  End-to-end process for baking a Cursor Cloud Agent environment for Obsidian
  plugin work — sample vault files, AppImage + Xvfb, Restricted mode and CLI
  toggles, secret injection, plugin verification, snapshot and Save. Use when
  setting up, repairing, or documenting a Cloud Obsidian sandbox environment.
---

# Cloud Agent Obsidian environment setup

Generalized playbook from baking a multi-plugin Cloud sandbox (Seek, Whisper,
Agent Client). This is the **process**; concrete scripts for this workspace live
under [`scripts/cloud-e2e/`](../../scripts/cloud-e2e/). Day-to-day in-vault ops:
[obsidian-cloud-e2e](../obsidian-cloud-e2e/SKILL.md).

Windows staging vaults stay under [obsidian-plugin-sandbox](../obsidian-plugin-sandbox/SKILL.md).
Do not treat Cloud Linux as a substitute for a large production-shaped Windows vault.

## Outcome checklist

A Cloud environment is “done” when all of these are true:

| Gate | Pass criteria |
| --- | --- |
| Install | Idempotent `install` builds plugins and materializes the vault |
| Start | Obsidian up under Xvfb; CDP on `127.0.0.1:9222` |
| Sample files | Fixture notes present; any custom corpora materialized |
| Community plugins | Restricted mode **off**; target plugins loaded |
| CLI | `obsidian` on PATH; Advanced CLI toggle **on** |
| Secrets | Injected via CDP (lengths only in logs) |
| Verify | Offline unit tests + in-vault smoke per plugin |
| Bake | Snapshot → draft build (install log proves corpora) → user **Save** |

## Architecture (typical)

```text
/agent/repos/<plugin-a|plugin-b|…>     # plugin sources + lockfiles
/agent/repos/<skills-or-orchestrator>  # optional: env scripts + skills
$HOME/plugin-sandbox-Obsidian          # synthetic vault (same CLI name as Windows staging)
$HOME/.obsidian-cloud-e2e-profile      # isolated --user-data-dir
$HOME/.local/opt/obsidian              # extracted AppImage
$HOME/.local/bin/obsidian              # → obsidian-cli
$HOME/.local/bin/obsidian-app          # → Electron binary
```

Prefer one orchestrator repo whose `env-install.sh` / `env-start.sh` know how to
find siblings (e.g. `/agent/repos` or relative paths). Pin Cloud dashboard
`install` / `start` to those scripts.

### install vs start

| Phase | Put here | Do not put here |
| --- | --- | --- |
| `install` | `npm ci` / `pnpm install`, plugin `build`, AppImage download, vault materialize, corpora clone | Long-running Obsidian/Xvfb |
| `start` | Xvfb, launch Obsidian, enable plugins/CLI, inject secrets, identity gate | Dependency installs or lockfile rewrites |

`install` must be idempotent and terminate. `start` must tolerate an already-running app.

## Sample files (two layers)

### 1. Small fixture vault (always)

Commit a tiny synthetic vault under the orchestrator (e.g. `fixtures/vault/`):

- `Welcome.md`, `Notes/*.md` with unique canary phrases for search smoke
- `.obsidian/community-plugins.json` listing plugin ids to enable
- Minimal `app.json` / `core-plugins.json` (no secrets)

Materialize by copying into `$HOME/plugin-sandbox-Obsidian`, then overlay built
`main.js` / `manifest.json` / `styles.css` from each sibling plugin repo.

### 2. Custom corpora (optional, first-class folders)

Large or third-party corpora (trivia transcripts, eval sets) should **not** live
only as “optional docs.” Give them an explicit vault folder and a companion skill.

Pattern used for AI21 Seinfeld trivia:

| Piece | Role |
| --- | --- |
| Vault folder | e.g. `Seinfeld (custom)/episodes/` — retrieval documents |
| Q&A notes | e.g. `Seinfeld (custom)/trivia/Q*.md` — question → answer → gold episode |
| Eval JSON in git | Stable agent/CI fixture (query, answer, expectedEpisode) |
| Upstream demo repo | Source of transcripts + full `data.json` (not a standalone dataset project) |
| Companion skill | Documents Q→A→document mapping ([seek-seinfeld-eval](../seek-seinfeld-eval/SKILL.md)) |

Materialize corpora in `install` (shallow clone to a cache dir, then copy into the vault).
Agents should search with the **query** only; gold answers stay in notes/fixture for scoring.

## Hard-won toggles (must automate)

Fresh Obsidian profiles look “configured” but still fail two silent gates.

### Community plugins (Restricted mode)

`community-plugins.json` and plugin folders can exist while
`app.plugins.plugins` stays empty. Loading is gated by:

```text
localStorage["enable-plugin-" + app.appId] === "true"
```

Automate after app ready (CDP):

```js
await app.plugins.setEnable(true);
await app.plugins.loadManifests();
for (const id of app.plugins.enabledPlugins) {
  await app.plugins.enablePlugin(id);
}
```

### Command line interface

`obsidian-cli` may be on disk while every command prints:

```text
Command line interface is not enabled. Please turn it on in Settings > General > Advanced.
```

Automate:

1. Write `"cli": true` into the profile `obsidian.json` before launch.
2. After ready: `electron.ipcRenderer.sendSync("cli", true)`.

Also export `PATH="$HOME/.local/bin:$PATH"` in `start` and agent shells.

### Force the sandbox vault open

Passing the vault path on the Electron argv is not enough. A default
`Obsidian Vault` can still become `"open": true`. Before launch, rewrite
profile `obsidian.json` so only the sandbox path has `"open": true`, and drop
empty default vaults.

## CDP boot sequence

Keep each step bounded (`timeout`) so `start` always returns:

1. `dismiss-starter` — click Open / Quick start if needed; wait for `app`
2. `enable-plugins` — Restricted mode off + load enabled ids
3. `enable-cli` — Advanced CLI on
4. `inject` — Cursor env → `secretStorage` (see [obsidian-secret-mapping](../obsidian-secret-mapping/SKILL.md))
5. **Identity gate** — assert vault name/base and loaded plugin ids

```bash
# Example identity probe
node scripts/cloud-e2e/cdp.mjs eval \
  'JSON.stringify({name:app.vault.getName(),base:app.vault.adapter.basePath,plugins:Object.keys(app.plugins.plugins)})'
```

Expect `name === "plugin-sandbox-Obsidian"` (or your chosen Cloud vault name) and
loaded plugin ids matching the deploy set.

## Secrets

1. Never write API keys into `data.json`, git, Install logs, or snapshot-visible files.
2. Never interpolate secrets into `obsidian eval` / CDP strings that get logged.
3. Cursor secrets appear as process env on the pod; inject with CDP `secretStorage.setSecret`.
4. Verify with **length only** (`probe` / eval that returns `.length`).

## Kill / restart Obsidian safely

Do **not** `pkill -f` a path substring that also appears in the shell’s argv —
the shell can kill itself. Match the real binary via `/proc/*/exe`:

```bash
BIN="$HOME/.local/opt/obsidian/squashfs-root/obsidian"
for pid in $(ls /proc | grep -E '^[0-9]+$'); do
  exe=$(readlink "/proc/$pid/exe" 2>/dev/null || true)
  [ "$exe" = "$BIN" ] && kill "$pid" 2>/dev/null || true
done
```

## Verify each plugin

### Offline (CI-shaped)

Per plugin repo, prefer lockfile-faithful installs (`npm ci` / `pnpm install --frozen-lockfile`):

- Typecheck / lint if the repo gates on them
- `npm test` / `pnpm test`
- Unset live-smoke env vars (e.g. `GEMINI_API_KEY`) when a suite auto-enables network tests

### In vault (loaded + callable)

With Obsidian up and CLI enabled:

| Check | How |
| --- | --- |
| Loaded | `Object.keys(app.plugins.plugins)` includes each id |
| Commands | `Object.keys(app.commands.commands).filter(k => k.startsWith("<id>:"))` |
| Search / fixtures | Canary phrase search; optional corpus smoke |
| Secrets | Id lengths non-zero when required for that plugin |

Do not claim “tested” from build artifacts alone — copy + load + command surface matter.

## Bake into a Cloud environment build

Scripts on `main` are not enough. New agents need a **finished build** + user **Save**.

1. Run final `install` on the working VM (prove corpora counts).
2. `take-environment-snapshot` → wait until **ready**.
3. `trigger-environment-build` with `environmentJson`: `{ snapshot, install, start }` (omit `refs` for promotable default-branch builds).
4. Wait until build **SUCCEEDED**; confirm install logs show corpus materialize lines.
5. Optionally boot a cloud subagent with `cloud_requested_environment_build_id` and re-check vault counts.
6. `propose-environment-json` with that `buildId`.
7. User clicks **Save** in the Environment panel.

Until Save, future agents may still boot without the baked snapshot.

## Minimal agent runbook

```bash
bash /agent/repos/<orchestrator>/scripts/cloud-e2e/env-install.sh
bash /agent/repos/<orchestrator>/scripts/cloud-e2e/env-start.sh
export PATH="$HOME/.local/bin:$PATH"

obsidian version
obsidian vault=plugin-sandbox-Obsidian files | head
# per plugin: offline tests, then CDP loaded+commands probes
```

Human walkthrough for this workspace: [`scripts/cloud-e2e/GETTING-STARTED.md`](../../scripts/cloud-e2e/GETTING-STARTED.md).

## Related skills

- [obsidian-cloud-e2e](../obsidian-cloud-e2e/SKILL.md) — boot/CDP/secrets for the synthetic vault
- [obsidian-secret-mapping](../obsidian-secret-mapping/SKILL.md) — env → `secretStorage` bindings
- [obsidian-plugin-testing](../obsidian-plugin-testing/SKILL.md) — Vitest / stubs / live smoke policy
- [obsidian-plugin-sandbox](../obsidian-plugin-sandbox/SKILL.md) — Windows staging vs production
- [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md) — `vault=` targeting, serial CLI
- [seek-seinfeld-eval](../seek-seinfeld-eval/SKILL.md) — example custom-corpus Q&A mapping

---
name: obsidian-multi-vault-cli
description: >-
  Obsidian CLI multi-vault safety — per-vault reload vs global restart, serial CLI
  IPC discipline, reload escalation ladder. Use when multiple vaults are open,
  deploying or reloading plugins, or choosing plugin:reload vs reload vs restart.
  Vault target discovery is defined by the global rule obsidian-vault-target-verify.
---

# Obsidian CLI — multi-vault safety

**Vault targeting is not defined here.** The single definition of how `vault=`
resolves and how to discover the target folder is the global rule
`obsidian-vault-target-verify` (`.cursor/rules/`). Read it before any session command.
Machine-specific vault names/paths are in the `machine-profile` skill. Do not restate
those mechanics — point at them.

This skill keeps the mechanics that are *specific to the CLI*:

## Serial IPC discipline

Multiple vault windows share **one Obsidian process** and **one CLI IPC queue**. Run
commands **serially**. **One `obsidian` command per shell line** — never `cmd1 ; cmd2`,
even `reload ; eval`.

### Wedge vs slow command

| Signal | Wedge | Slow but OK |
|--------|-------|-------------|
| Output | Silence, no `=>`, no exit | Progress or eventual `=>` |
| Duration | Indefinite | 60–130s possible after heavy reload |
| Exit after kill | `4294967295` (force-killed shell) | N/A |

### CLI hang recovery

1. Stop — no more CLI.
2. Kill shell; quit Obsidian manually if wedged.
3. Reopen; then one target-discovery `eval` per `obsidian-vault-target-verify`. If it
   does not print the intended path, stop.

When wedged, `obsidian restart` often never reaches the app.

## Per-vault reload

**Prefer** `obsidian vault=<name> command id=app:reload` over `obsidian reload`.
`vault=` must stay the first argument.

| Goal | Command | Scope |
|------|---------|-------|
| Plugin JS/CSS | `vault=<name> plugin:reload id=<id>` | One plugin |
| Stale CSS / window | `vault=<name> command id=app:reload` | One vault |
| Verify runtime | `vault=<name> eval code="..."` | One vault |
| Close everything | `restart` (ask first) | **All vaults** |

### Escalation ladder

1. Close/reopen affected modals.
2. `vault=<name> command id=app:reload` (sandbox: auto; production: warn).
3. `vault=<name> reload` fallback.
4. `restart` — only after user accepts closing **all** vaults.

## IDB wipe (single vault)

Discover the target per `obsidian-vault-target-verify` before each CLI step.

1. `obsidian vault=<target> plugin:disable id=<id>`
2. Delete plugin cache dirs under `<vault>/.obsidian/plugins/<id>/`
3. `obsidian vault=<target> eval` → `indexedDB.deleteDatabase('<db-name>')` (plugin disabled)
4. Copy fresh artifacts
5. `obsidian vault=<target> plugin:enable id=<id>` — not `plugin:reload` mid full reindex

If `blocked`: quit Obsidian or accept global restart. See
[obsidian-indexeddb-storage](../obsidian-indexeddb-storage/SKILL.md).

## See also

- `obsidian-vault-target-verify` (global rule) — the vault-target discovery definition
- `machine-profile` (skill) — local vault names and paths
- [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md) — build, copy, verify
- [obsidian-plugin-debug](../obsidian-plugin-debug/SKILL.md) — eval, DevTools

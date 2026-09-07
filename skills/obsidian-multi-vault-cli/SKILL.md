---
name: obsidian-multi-vault-cli
description: >-
  Obsidian CLI multi-vault safety — per-vault reload vs global restart, staging
  vs production deploy targets, serial CLI, focus vault via URI. Use when multiple
  vaults are open, deploying or reloading plugins, choosing plugin:reload vs
  reload vs restart, or scoping eval/search to one vault instance.
---

# Obsidian CLI — multi-vault safety

Multiple vault windows share **one Obsidian process** and **one CLI IPC queue**. Run commands **serially**. **One `obsidian` command per shell line** — never `cmd1 ; cmd2`, even `reload ; eval`.

`vault=` must be the **first** argument. If shell cwd is a vault root, omit `vault=`.

## Target a vault (no focus steal)

`vault=` is a **substring** match. Short production names may match sandbox names (e.g. `Obsidian` inside `plugin-sandbox-Obsidian`).

| Role | Selector | Never use |
|------|----------|-----------|
| Sandbox | `vault=<sandbox-vault-name>` first | shorter tokens that substring-match |
| Production | cwd = `<production-vault-path>`, omit `vault=` | `vault=<production-vault-name>` when it matches sandbox |

```powershell
obsidian vaults verbose
obsidian vault=<sandbox-vault-name> eval code="app.vault.getName()"
Set-Location <production-vault-path>
obsidian eval code="app.vault.getName()"
```

**Do not** use `obsidian vault` or `obsidian://open` to "fix" targeting while the app is up — can focus-steal.

## Anti-chaining rule

```powershell
# WRONG — wedges if first command stalls
obsidian vault=<name> plugin:reload id=<id> ; obsidian vault=<name> eval code="'alive'"

# RIGHT — two separate shell invocations
obsidian vault=<name> plugin:reload id=<id>
obsidian vault=<name> eval code="'alive'"
```

### Wedge vs slow command

| Signal | Wedge | Slow but OK |
|--------|-------|-------------|
| Output | Silence, no `=>`, no exit | Progress or eventual `=>` |
| Duration | Indefinite | 60–130s possible after heavy reload |
| Exit after kill | `4294967295` (force-killed shell) | N/A |

## Per-vault reload

**Prefer** `obsidian command id=app:reload vault=<name>` over `obsidian reload`.

| Goal | Command | Scope |
|------|---------|-------|
| Plugin JS/CSS | `plugin:reload id=<id> vault=<name>` | One plugin |
| Stale CSS / window | `command id=app:reload vault=<name>` | One vault |
| Verify runtime | `eval vault=<name> code="..."` | One vault |
| Close everything | `restart` (ask first) | **All vaults** |

### Escalation ladder

1. Close/reopen affected modals.
2. `command id=app:reload vault=<name>` (sandbox: auto; production: warn).
3. `reload vault=<name>` fallback.
4. `restart` — only after user accepts closing **all** vaults.

## Staging vs production

| Role | CLI | Path |
|------|-----|------|
| Sandbox | `vault=<sandbox-vault-name>` | `<sandbox-vault-path>` |
| Production | cwd, omit `vault=` | `<production-vault-path>` |

Do **not** auto-promote after sandbox verify. See [obsidian-plugin-sandbox](../obsidian-plugin-sandbox/SKILL.md).

## IDB wipe (single vault)

1. `plugin:disable id=<id> vault=<target>`
2. Delete plugin cache dirs under `<vault>/.obsidian/plugins/<id>/`
3. `eval` → `indexedDB.deleteDatabase('<db-name>')` (plugin disabled)
4. Copy fresh artifacts
5. `plugin:enable` — not `plugin:reload` mid full reindex

If `blocked`: quit Obsidian or accept global restart. See [obsidian-indexeddb-storage](../obsidian-indexeddb-storage/SKILL.md).

## CLI hang recovery

1. Stop — no more CLI.
2. Kill shell; quit Obsidian manually if wedged.
3. Reopen; one `eval code="'alive'"` probe.

When wedged, `obsidian restart` often never reaches the app.

## See also

- [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md) — build, copy, verify
- [obsidian-plugin-debug](../obsidian-plugin-debug/SKILL.md) — eval, DevTools

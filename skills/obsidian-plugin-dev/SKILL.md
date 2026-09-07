---
name: obsidian-plugin-dev
description: >-
  Build, deploy, hot-reload, and verify Obsidian community plugins per official
  docs (esbuild → main.js, Obsidian CLI developer commands). Use when developing
  Obsidian plugins, rebuilding after code changes, copying artifacts to a vault,
  reloading plugins, debugging why UI changes are not visible, or verifying that
  main.js/styles.css in the vault match the repo build.
---

# Obsidian plugin development (build, deploy, reload, verify)

## Official documentation

| Topic | URL |
|-------|-----|
| Build a plugin (tutorial) | https://docs.obsidian.md/Plugins/Getting+started/Build+a+plugin |
| Obsidian CLI (developer commands) | https://obsidian.md/help/cli#Developer+commands |
| Developer docs (index) | https://docs.obsidian.md |

**Multi-vault / reload vs restart:** [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md)

**CLI reliability / wedges:** [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md) — one command per shell invocation; wedge vs slow-command signatures.

**Machine paths:** copy [`references/machine-profile.example.md`](../../references/machine-profile.example.md) locally.

---

## Mental model

Obsidian loads plugins from the vault, **not** your git repo (unless you develop in-place):

```
<vault>/.obsidian/plugins/<plugin-id>/
  main.js          # compiled bundle (required)
  manifest.json    # id, name, version (required)
  styles.css       # optional — auto-loaded if present
  data.json        # persisted settings (runtime) — preserve on deploy
```

Per the [Build a plugin](https://docs.obsidian.md/Plugins/Getting+started/Build+a+plugin) tutorial:

- **`npm run dev`** keeps running and rebuilds `main.js` when source changes.
- **`manifest.json` changes require restarting Obsidian** (not just reload) on some versions; prefer `app:reload` per vault when available.
- **Source changes** require reloading the plugin (see [Reload](#reload-official--practical)).

**Never develop in your main vault** — use a separate dev/staging vault.

| Layout | When |
|--------|------|
| **In-vault** (official tutorial) | `git clone` into `.obsidian/plugins/<id>/`, `npm run dev` writes `main.js` beside source |
| **Out-of-vault repo** | Build in repo → copy `main.js`, `manifest.json`, `styles.css` into vault plugin folder |

**"Deployed"** = vault `main.js` matches latest build — not necessarily git `main`.

### Artifact placement

- Ship only under `<vault>/.obsidian/plugins/<plugin-id>/` — never note folders or `.obsidian/snippets/` unless the feature is explicitly a CSS snippet.
- **Preserve `data.json`** on deploy: copy only `main.js`, `manifest.json`, `styles.css`. Never overwrite user settings or session folders.
- **CSS snippets vs plugin CSS:** plugin `styles.css` loads with the plugin; vault snippets need separate enablement. Coordinate `body` classes in plugin code with snippet selectors when both are used.

---

## Prerequisites (CLI)

1. **Obsidian 1.12 installer** (1.12.7+).
2. **Settings → General → Command line interface** → enable and register CLI.
3. **Obsidian app must be running** (CLI talks to the live app).
4. **Windows**: restart terminal after PATH registration.

```powershell
# Windows — if `obsidian` is not on PATH:
& "C:\Program Files\Obsidian\Obsidian.exe" help
```

Target vaults per [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md). Use `<sandbox-vault-name>` for staging; production via shell cwd at `<production-vault-path>`.

---

## CLI IPC queue discipline

The Obsidian developer CLI is a **single serial IPC queue** on the app's main thread.

1. **One `obsidian` command per shell invocation.** Never chain with `;` — if the first stalls, the second queues forever.
2. **Never run CLI commands concurrently** across shells or subagents.
3. **Wedge vs slow:** wedge = no `=>` output and no exit, indefinitely. Some commands legitimately take 60–130s after reload and still succeed.

**Recovery:** kill stuck shell → quit Obsidian (tray → Quit) → relaunch → wait 15–20s → one probe: `eval code="'alive'"`.

---

## Standard workflow

```
- [ ] 1. Edit TypeScript in src/
- [ ] 2. npm run typecheck && npm test
- [ ] 3. npm run build (or npm run dev watching)
- [ ] 4. User-facing fix ready? Add bullet under CHANGELOG `[Unreleased]` (no manifest bump yet)
- [ ] 5. Copy main.js (+ manifest.json, styles.css) to staging vault — not data.json
- [ ] 6. Reload plugin — restart Obsidian only after release bump on main
- [ ] 7. Verify deployment (disk + runtime)
- [ ] 8. Close/reopen plugin UI (modals pick up onOpen changes)
- [ ] 9. Shipping on main? Release commit: finalize `[Unreleased]` + bump manifest.json
```

### Deploy (out-of-vault)

```powershell
$dest = "<sandbox-vault-path>\.obsidian\plugins\<plugin-id>\"
Copy-Item main.js, manifest.json, styles.css -Destination $dest -Force
obsidian vault=<sandbox-vault-name> plugin:reload id=<plugin-id>
```

Promote to production only when user explicitly requests — see [obsidian-plugin-sandbox](../obsidian-plugin-sandbox/SKILL.md) and [ship-main-prod](../ship-main-prod/SKILL.md).

---

## Release notes and semantic versioning

**Source of truth** for changelog + semver across Obsidian plugin repos.

### `## [Unreleased]` (during development)

- Add bullets when a change is **ready** (built, deployed to sandbox, verified).
- Use `### Added`, `### Changed`, or `### Fixed`.
- **Do not bump `manifest.json` during this phase.**

### Release gate (main branch only)

1. Review `[Unreleased]` on `main`.
2. Decide semver from highest-impact change.
3. Rename `## [Unreleased]` → `## X.Y.Z`.
4. Bump `manifest.json` `version`. Sync `package.json` / `versions.json` if used.
5. Deploy to production → **restart Obsidian** after version change.

| Change | Bump |
|--------|------|
| Bug fix, regression | PATCH |
| New backward-compatible feature | MINOR |
| Breaking change | MAJOR |

---

## Reload

| Action | JS | CSS | `manifest.json` | Open modals |
|--------|----|-----|-----------------|-------------|
| `plugin:reload` | Yes | Often | No | Stale until closed |
| `command id=app:reload` | Yes | Yes | Often | Closed |
| `obsidian restart` | Yes | Yes | Yes | All vaults closed |

If CSS stale after `plugin:reload`: close modals → `app:reload` per vault → global `restart` only with user consent.

Modal settings apply on **next open** — user must close the modal completely.

Hotkeys: see [obsidian-hotkeys](../obsidian-hotkeys/SKILL.md).

---

## Verify deployment

### Disk

```powershell
(Get-Item repo\main.js).Length
(Get-Item <sandbox-vault-path>\.obsidian\plugins\<id>\main.js).Length
Select-String <vault-plugin-dir>\main.js -Pattern "YOUR_NEW_SYMBOL"
```

### Runtime eval

```powershell
obsidian vault=<sandbox-vault-name> eval code="JSON.stringify(app.plugins.plugins.<id>?.settings)"
```

Secrets: see [obsidian-settings-secrets](../obsidian-settings-secrets/SKILL.md).

### Developer tools

```powershell
obsidian vault=<sandbox-vault-name> devtools
obsidian vault=<sandbox-vault-name> dev:dom selector=".your-class" total
obsidian vault=<sandbox-vault-name> dev:screenshot path=screenshot.png
```

Full CLI list: [reference.md](reference.md)

---

## Common pitfalls

1. Built in repo, never copied to vault.
2. `manifest.json` edited but only plugin-reloaded when full restart required.
3. Modal still open after reload.
4. CSS stale — escalate per [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md).
5. Overwriting `data.json` on deploy.
6. Chaining CLI commands (`cmd1 ; cmd2`).
7. Manifest bumped on feature branch or during sandbox iteration.
8. Developing in production vault.

---

## See also

- [obsidian-plugin-debug](../obsidian-plugin-debug/SKILL.md) — eval, DevTools
- [obsidian-plugin-testing](../obsidian-plugin-testing/SKILL.md) — Vitest before deploy
- [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) — UI proof
- [obsidian-plugin-review](../obsidian-plugin-review/SKILL.md) — review antipatterns

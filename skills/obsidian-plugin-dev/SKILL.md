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

**Cursor Cloud sessions:** [obsidian-cloud-vm-demos](../obsidian-cloud-vm-demos/SKILL.md) — strict VM demos; local sandbox does not replace cloud proof.

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

Target vaults per [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md). Use the **full** `<sandbox-vault-name>` (exact folder name — `vault=` substring-matches); production via shell cwd at `<production-vault-path>`.

### Vault targeting (`vault=`)

`vault=` must be the **first** CLI argument and must use the **complete vault name**, not a shorthand:

```powershell
# WRONG — vault=Obsidian matches plugin-sandbox-Obsidian
obsidian vault=Obsidian plugin:reload id=<plugin-id>

# RIGHT — full folder name from obsidian vaults verbose
obsidian vault=plugin-sandbox-Obsidian plugin:reload id=<plugin-id>
```

Verify with an identity gate before trusting reload/eval output — see [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md).

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
- Write **user-visible detail**: which setting, command, modal, or behavior changed — not one-line “fix bug” without context.
- **Do not bump `manifest.json` during this phase.**

### CHANGELOG quality at release (`## X.Y.Z`)

When cutting a release, the new version section must stand alone for users and for BRAT/GitHub Release readers.

- Keep **Added / Changed / Fixed** headings; each bullet should describe an **outcome** (what users notice or can do).
- Mention **settings paths**, **command names**, or **UI areas** when they help someone find the change.
- **Do not ship** a release whose only changelog text is “bump version” / “manifest bump” with no list of changes since the previous tag. If the diff is internal-only, say so under `### Changed` with a short honest note.
- If `[Unreleased]` is thin at ship time, review commits since the last tag and backfill bullets before tagging.

### Release gate (main branch only)

1. Review `[Unreleased]` on `main` (substantive bullets per above).
2. Decide semver from highest-impact change.
3. Rename `## [Unreleased]` → `## X.Y.Z`.
4. Bump `manifest.json` `version`. Sync `package.json` / `versions.json` if used.
5. Annotated **Git tag** matching `manifest.json` (no `v` prefix), push tag, wait for release workflow (see below).
6. **Publish** the GitHub Release (not draft). Production vault updates via **BRAT** from published release assets — not manual copy unless explicitly requested.
7. After BRAT picks up the release on vault `Obsidian`, confirm installed `manifest.version` matches the tag.

| Change | Bump |
|--------|------|
| Bug fix, regression | PATCH |
| New backward-compatible feature | MINOR |
| Breaking change | MAJOR |

### Annotated tag message

Tag name **must equal** `manifest.json` `version` (`X.Y.Z`, no `v` prefix). Message format:

1. **First `-m` line:** plain-language **headline** of what shipped (not just the version).
2. **Further `-m` lines:** **3–8 bullets** (fewer for tiny patch releases) summarizing notable user-facing items from the new CHANGELOG section.

```bash
VERSION=X.Y.Z
git tag -a "$VERSION" \
  -m "Seek: faster modal open during catch-up indexing" \
  -m "- Changed: search modal shows partial results while index catches up" \
  -m "- Fixed: status bar stuck on 'Indexing' after reload"
git push origin main && git push origin "$VERSION"
```

Avoid tags whose entire message is only `X.Y.Z`.

### GitHub Release and BRAT install path

Obsidian and BRAT install from a **published** GitHub Release whose tag **exactly matches** `manifest.json` `version`, with `main.js`, `manifest.json`, and `styles.css` attached. Tag push triggers `.github/workflows/release.yml` in sibling plugin repos; workflows often create a **draft** release first. Manifest on `main` without a published release for that version breaks BRAT updates.

1. Wait for CI/workflow to attach assets to the tag.
2. **Publish:** `gh release edit "$VERSION" --repo <owner/repo> --draft=false`
3. **Release body (recommended):** paste the `## X.Y.Z` CHANGELOG section (Added/Changed/Fixed) so GitHub matches the tag and BRAT users see the same detail:

   ```bash
   gh release edit "$VERSION" --repo <owner/repo> --notes-file path/to/changelog-snippet.md
   ```

4. Verify: `gh release view "$VERSION" --repo <owner/repo>`

**BRAT** on the production vault tracks **published** GitHub Releases for the fork repo. Until the release is published (and assets exist), Obsidian cannot install/update from that tag. Day-to-day production shipping = **changelog + tag + published release**, not copying build artifacts into `Obsidian` unless explicitly requested.

Adrian’s Project store checklists (when available on the agent VM): `obsidian-manifest-bump-release.md` (user workflows) and `release-process.md` (project docs) — same tag/changelog/publish steps as this section.

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

In a **Cloud Agent** session (or when `.cursor/environment.json` is active on the VM), follow [obsidian-cloud-vm-demos](../obsidian-cloud-vm-demos/SKILL.md) in addition to the checks below.

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
9. Partial `vault=` name (substring match hits the wrong vault).

---

## See also

- [obsidian-plugin-debug](../obsidian-plugin-debug/SKILL.md) — eval, DevTools
- [obsidian-plugin-testing](../obsidian-plugin-testing/SKILL.md) — Vitest before deploy
- [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) — UI proof
- [obsidian-ui-visibility](../obsidian-ui-visibility/SKILL.md) — before a demo, prove the control is visible
- [obsidian-ui-verifier-demo](../obsidian-ui-verifier-demo/SKILL.md) — BDD functional verify; `/ui-verifier-demo` on large behavior changes
- [obsidian-plugin-review](../obsidian-plugin-review/SKILL.md) — review antipatterns

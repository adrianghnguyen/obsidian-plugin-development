---
name: obsidian-visual-verify
description: >-
  Capture Obsidian screenshots for visual verification of plugin UI (status bar,
  settings, modals, main chrome). Use when finishing UI/CSS/layout/modal/settings
  work, reporting visual bugs, or when deploy-and-verify requires proof beyond eval.
---

# Obsidian visual verification (screenshots)

Runtime proof for **what the user sees**. `eval` and unit tests are not enough for CSS, layout, status-bar labels, modal chrome, or Settings rows.

**Prerequisites:** Obsidian desktop, `obsidian` on PATH, **serial CLI only** (one command at a time). Helpers: [`scripts/ObsidianCliSerial.ps1`](scripts/ObsidianCliSerial.ps1).

**Default vault:** staging (`<sandbox-vault-name>`). Production only when user explicitly requests promotion verify.

## When to run

After deploy + `plugin:reload` when the task touches:

| Change area | Capture surface(s) |
|-------------|-------------------|
| Status bar | `StatusBar` or `Main` |
| Settings tab | `Settings` |
| Plugin modal / view | `PluginModal` (pass `-OpenCommandId`) |
| `styles.css` / global chrome | `Main` + affected surface |

**Skip** for: pure logic, comments, test-only, docs-only.

**Do not** open Settings unless capturing `Settings`.

## Driver script

From your plugin repo (PowerShell, **serial**):

```powershell
$script = '<path-to-this-skill>\scripts\capture-surfaces.ps1'

& $script -Vault <sandbox-vault-name> -PluginId <plugin-id> -Surface Main, StatusBar

& $script -Vault <sandbox-vault-name> -PluginId <plugin-id> -Surface Settings

& $script -Vault <sandbox-vault-name> -PluginId <plugin-id> `
  -OpenCommandId '<plugin-id>:your-open-command' -Surface PluginModal
```

| Parameter | Notes |
|-----------|-------|
| `-Vault` | Unique CLI vault name |
| `-PluginId` | `manifest.json` id |
| `-Surface` | `Main`, `StatusBar`, `Settings`, `PluginModal` |
| `-OpenCommandId` | Required for `PluginModal` |
| `-OutputDir` | Default `.tmp/visual-<vault>/` — gitignore artifacts |

Output: `main.png`, `status-bar.png`, `plugin-settings.png`, `plugin-modal.png`.

Write screenshots to `.tmp/` or another gitignored folder — never commit to the plugin repo root.

## Workflow

1. **Ensure vault ready** — `Ensure-ObsidianVaultReady` launches/polls CLI.
2. **Focus Obsidian window** (Win32) so `dev:screenshot` is not blank.
3. **Per surface:** dismiss modals → prepare UI → one screenshot.
4. **Report paths** to user; judge pass/fail from images.

## Manual CLI

```powershell
Start-Process "obsidian://open?vault=<sandbox-vault-name>"
# focus window (see ObsidianCliSerial.ps1 Focus-ObsidianWindow)
obsidian vault=<sandbox-vault-name> dev:screenshot path=<absolute-path>\main.png
```

Close stacked modals before capturing a different surface. After CSS deploy, close/reopen modals.

## Anti-patterns

- **Parallel CLI** — wedges IPC.
- **Screenshot without focus** — blank or wrong window.
- **Settings capture for every verify** — only when Settings UI changed.
- **Defaulting to production vault** — routine verify uses sandbox.

## See also

- [obsidian-plugin-debug](../obsidian-plugin-debug/SKILL.md) — eval, DOM hygiene
- [obsidian-menu-settings](../obsidian-menu-settings/SKILL.md) — settings popout capture
- [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md) — serial discipline
- [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md) — deploy first

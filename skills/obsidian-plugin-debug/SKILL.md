---
name: obsidian-plugin-debug
description: >-
  Debug Obsidian community plugins via the Obsidian CLI — open DevTools, reload a
  plugin under development, take screenshots, and eval JavaScript in the app. Use
  when developing or debugging an Obsidian plugin, verifying vault runtime behavior,
  or using obsidian eval / plugin:reload / devtools / dev:screenshot. For
  multi-vault reload vs restart, see obsidian-multi-vault-cli.
---

# Obsidian plugin debug (CLI)

Use the **Obsidian CLI** against a running Obsidian app. Prefer CLI over guessing UI state.

**Multi-vault:** [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md) — serial CLI, `vault=` first, one command per invocation.

**Windows eval quoting:** use the companion `powershell-agent` skill globally, or the patterns below.

## Core commands

```powershell
obsidian vault=<sandbox-vault-name> devtools
obsidian vault=<sandbox-vault-name> plugin:reload id=<plugin-id>
obsidian vault=<sandbox-vault-name> dev:screenshot path=screenshot.png
obsidian vault=<sandbox-vault-name> eval code="app.vault.getFiles().length"
```

Replace `<plugin-id>` with `manifest.json` `id`. Quote `code=` values; escape inner quotes for the shell.

## Typical debug loop

1. Copy `main.js`, `manifest.json`, `styles.css` to `<sandbox-vault-path>/.obsidian/plugins/<id>/` (not `data.json`).
2. `plugin:reload` — if CSS stale, `command id=app:reload` per vault before global `restart`.
3. Probe with `eval` (plugin instance, settings, DOM).
4. Optional: `devtools`, `dev:screenshot`, `dev:console`, `dev:errors`.
5. Production only when user explicitly requests.

## Eval tips

- **Serial only** — one CLI session at a time.
- **Sync-only eval** — the CLI does not reliably await top-level `async`/`await`. Use synchronous IIFEs or `new Promise` with explicit `res()` callbacks.
- Plugin access: `app.plugins.plugins['<plugin-id>']`.
- Parse stdout: keep lines starting with `=>`.
- After editing `data.json` on disk, call `plugin.loadSettings()` via eval before expecting new keys in memory.

```powershell
obsidian vault=<name> eval code="(()=>{const p=app.plugins.plugins['<id>'];p.loadSettings();return JSON.stringify(p.settings)})()"
```

## PowerShell-safe eval

- Chain shell commands with `;`, not `&&` (older Windows PowerShell).
- Prefer `--file` or stdin for long JS payloads instead of inline `code=`.
- JSON filters to CLIs: write to a temp file; see `powershell-agent` skill.
- Absolute paths for `dev:screenshot path=...`.

## Gated debugMode verify

When verifying a `debugMode` or verbose logging flag:

1. Enable via eval or settings.
2. Run the probe.
3. **Disable before finishing** — do not leave debug logging on in the user's vault.

## False boot signals

- **UTF-8 BOM** in another plugin's `data.json` can break JSON parse at boot — check with a hex dump if boot hangs mysteriously.
- **Core IndexedDB errors** during vault init are often Obsidian cache noise — do not treat as your plugin's failure until after `onLayoutReady` (see [obsidian-startup-performance](../obsidian-startup-performance/SKILL.md)).

## Settings tabs

```javascript
app.commands.executeCommandById('app:open-settings');
app.setting.openTabById('<plugin-id>');
const tab = (app.setting.pluginTabs || []).find(t => t.id === '<plugin-id>');
if (tab) tab.containerEl.innerText;
```

`document.body` often shows the wrong pane. Full navigation: [obsidian-menu-settings](../obsidian-menu-settings/SKILL.md).

## UI capture

Close stacked modals before `dev:dom` / `dev:screenshot`:

```javascript
document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
document.querySelectorAll('.modal-close-button').forEach(b => b.click());
if (app.setting?.close) app.setting.close();
```

## Chromium remote attach

```bash
node skills/obsidian-plugin-debug/scripts/launch-obsidian-debug.mjs
```

Set `DEV_VAULT` and optionally `OBSIDIAN_PATH` in project `.env`. Attach on port 9222.

## See also

- [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) — screenshot surfaces
- [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md) — deploy verify
- [obsidian-settings-secrets](../obsidian-settings-secrets/SKILL.md) — secret probes

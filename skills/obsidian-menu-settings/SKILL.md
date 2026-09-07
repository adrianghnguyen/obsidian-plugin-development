---
name: obsidian-menu-settings
description: >-
  Navigate, inspect, manipulate, and capture Obsidian settings tabs (Core settings
  and Community Plugins) programmatically via the Obsidian CLI or JavaScript eval.
  Covers opening/closing settings, switching tabs, Electron popout windows,
  reliable screenshot capture, reading/modifying settings, and DOM queries.
---

# Obsidian menu settings navigation

Programmatically navigate Settings via `obsidian eval` and `app.setting`.

## Architecture

| Property / Method | Purpose |
|-------------------|---------|
| `app.setting.settingTabs` | Core tabs (General, Editor, …) |
| `app.setting.pluginTabs` | Community plugin tabs (`manifest.id`) |
| `app.setting.activeTab` | Current tab |
| `app.setting.open()` / `close()` | Open/close settings |
| `app.setting.openTabById(id)` | Switch tab |
| `app.setting.popout` | Detached Electron window reference |

## Opening tabs

```javascript
app.setting.open();
app.setting.openTabById('editor');      // core
app.setting.openTabById('<plugin-id>'); // community plugin
```

### Common core tab IDs

`general`, `editor`, `files`, `appearance`, `hotkeys`, `core-plugins`, `community-plugins`

### Discover tabs at runtime

```javascript
JSON.stringify({
  core: (app.setting.settingTabs || []).map(t => ({ id: t.id, name: t.name })),
  plugins: (app.setting.pluginTabs || []).map(t => ({ id: t.id, name: t.name }))
});
```

## Electron popout window

Settings may open in a **detached popout** — DOM is in `app.setting.popout.win.document`, not `window.document`.

### Capture popout screenshot

```javascript
new Promise(resolve => {
  app.setting.open();
  setTimeout(() => {
    app.setting.openTabById('<plugin-id>');
    setTimeout(() => {
      const win = app.setting.popout?.win?.electronWindow || window.electronWindow;
      win.capturePage().then(img => {
        require('fs').writeFileSync('<output-path>', img.toPNG());
        resolve('captured');
      });
    }, 600);
  }, 300);
});
```

### Force in-window settings

```javascript
if (app.setting.popout?.win) app.setting.popout.win.close();
app.setting.popout = null;
app.setting.shouldUsePopout = () => false;
app.setting.open();
```

## Reading settings DOM

```javascript
const doc = app.setting.popout?.win?.document || document;
const activeTab = app.setting.activeTab;
activeTab?.containerEl.innerText;
```

Query `.setting-item` for toggles and labels.

## Modifying settings

**Core:** `app.vault.getConfig` / `setConfig`

**Plugins:**

```javascript
const plugin = app.plugins.plugins['<plugin-id>'];
plugin.settings.mySetting = true;
await plugin.saveSettings();
if (app.setting.activeTab?.id === '<plugin-id>') app.setting.activeTab.display();
```

Device-local vs synced: [obsidian-settings-secrets](../obsidian-settings-secrets/SKILL.md).

## Pre-navigation hygiene

Dismiss modals before opening Settings:

```javascript
document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
document.querySelectorAll('.modal-close-button').forEach(b => b.click());
if (app.setting?.close) app.setting.close();
```

## See also

- [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) — settings screenshots
- [obsidian-plugin-debug](../obsidian-plugin-debug/SKILL.md) — eval basics

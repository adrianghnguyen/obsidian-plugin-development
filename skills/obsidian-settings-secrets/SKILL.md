---
name: obsidian-settings-secrets
description: >-
  Obsidian plugin settings and secrets — PluginSettingTab, loadData/saveData,
  synced data.json vs loadLocalStorage vs secretStorage, hostname-keyed maps,
  empty password field UX, and UI transparency for new settings. Use when
  persisting credentials, device-local config, or verifying secrets at runtime.
---

# Obsidian plugin settings and secrets

## Three storage layers

| Layer | API | Syncs | Use for |
|-------|-----|-------|---------|
| Synced settings | `loadData()` / `saveData()` → `data.json` | Yes (vault sync) | User preferences, non-secret config |
| Device-local | `loadLocalStorage()` / `saveLocalStorage()` | No | Machine-specific paths, caches, opt-outs |
| Secrets | `app.secretStorage.get/set/delete` | No (encrypted OS store) | API keys, tokens |

Never put secrets in `data.json`. Strip secret fields before `saveData()`; store empty string or omit key in synced JSON.

## PluginSettingTab

```typescript
class MySettingTab extends PluginSettingTab {
  display(): void {
    const { containerEl } = this;
    containerEl.empty();
    new Setting(containerEl)
      .setName('Feature')
      .addToggle(t => t.setValue(this.plugin.settings.enabled)
        .onChange(async v => { this.plugin.settings.enabled = v; await this.plugin.saveSettings(); }));
  }
}
```

Rebuild safety: `containerEl.empty()` before redraw. If user has tab open during deploy, they may need to close/reopen Settings.

## Secret storage

```typescript
const SECRET_IDS = { apiKey: 'my-plugin-api-key' };

async resolveSecrets() {
  this.runtimeApiKey = await this.app.secretStorage.get(SECRET_IDS.apiKey) ?? '';
}

async saveApiKey(value: string) {
  if (value) await this.app.secretStorage.set(SECRET_IDS.apiKey, value);
  // never log value
}
```

### Runtime verify (never print values)

```powershell
obsidian vault=<name> eval code="JSON.stringify({has:!!app.secretStorage,len:((await app.secretStorage.getSecret('<secret-id>'))||'').length})"
```

Use sync eval pattern if `await` unsupported — see [obsidian-plugin-debug](../obsidian-plugin-debug/SKILL.md).

Find secret ids in source: `SECRET_IDS`, `getSecret(`, `secretStorage.set`.

## Empty password field ≠ delete

Settings UI for API keys:

- **Empty submit** on save → do **not** delete existing secret unless user explicitly clicks "Clear" or similar.
- Show "configured" state without revealing value (length indicator, masked placeholder).
- On load, resolve secret into runtime field; leave settings text input blank.

## Hostname-keyed maps in synced settings

Some plugins store per-machine overrides inside `data.json`:

```json
{ "deviceOverrides": { "DESKTOP-ABC": { "port": 9222 } } }
```

Document which keys are hostname-scoped. Prefer `loadLocalStorage` for truly device-local data when sync would leak wrong paths.

## UI transparency gate

New user-visible states (indexing, errors, connectivity) need at least one of:

- Settings row with description
- Status bar item
- Modal message

Do not add silent background states. See [obsidian-plugin-review](../obsidian-plugin-review/SKILL.md).

## manifest.json restart

Some settings require full restart when declared in manifest — document in settings description.

## See also

- [obsidian-menu-settings](../obsidian-menu-settings/SKILL.md) — settings tab navigation
- [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md) — verify deployment
- [obsidian-startup-performance](../obsidian-startup-performance/SKILL.md) — avoid `saveData` in `onload`

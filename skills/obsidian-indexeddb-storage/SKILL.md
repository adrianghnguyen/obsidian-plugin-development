---
name: obsidian-indexeddb-storage
description: >-
  IndexedDB lifecycle for Obsidian plugins — open, delete, blocked connections,
  backing-store corruption, multi-window locks, and disk paths. Use when IDB
  refuses to open, deleteDatabase returns blocked, store stays closed after
  restart, or planning a clean-slate reindex.
---

# Obsidian plugin IndexedDB storage

## Naming

Typical pattern: `<plugin-id>:<appId>` where `appId` comes from `app.appId` or vault identity. **Never guess** — read the name from plugin source (`indexedDB.open('...')`).

```javascript
const appId = app.appId || app.vault.getName();
const dbName = '<plugin-id>-index:' + appId; // example — verify in source
```

## Artifact placement

Plugin-specific disk cache (logs, sidecars, index shards) lives under:

```
<vault>/.obsidian/plugins/<plugin-id>/
```

IndexedDB files are **outside** the vault, per Electron profile:

```
%APPDATA%\Obsidian\IndexedDB\https_app.obsidian.md_0\<db-name>.*
```

(macOS/Linux paths differ; search `IndexedDB` under the Obsidian app data dir.)

## Clean-slate recovery

**Only when user asks** or corruption is confirmed — never reset IDB casually.

1. `obsidian plugin:disable id=<plugin-id> vault=<target>`
2. Quit Obsidian entirely (tray → Quit). CLI `restart` is unreliable when wedged.
3. Delete IDB directory for the db name, or whole `https_app.obsidian.md_0` (Obsidian recreates).
4. Delete plugin cache dirs under `<vault>/.obsidian/plugins/<plugin-id>/` if applicable.
5. Relaunch; copy fresh `main.js`, `manifest.json`, `styles.css`.
6. `plugin:enable` — **not** `plugin:reload` during full reindex bootstrap.

### Via eval (plugin disabled)

```javascript
new Promise((res) => {
  const r = indexedDB.deleteDatabase('<db-name>');
  r.onsuccess = () => res('deleted');
  r.onerror = () => res('error');
  r.onblocked = () => res('blocked');
});
```

If `blocked`: another window or handle holds the connection — close all vaults or quit Obsidian.

## Corruption signals

- `Internal error opening backing store for indexedDB.open`
- `deleteDatabase` → `blocked` persistently
- `store.isOpen()` stays `false` after enable
- Retry commands no-op

Often follows **manifest version bump + full restart** — prefer `plugin:reload` during dev; restart only when version actually changed.

## Prevention

- Disable plugin before `deleteDatabase`.
- Do not open IDB heavy work in `onload` before `onLayoutReady` ([obsidian-startup-performance](../obsidian-startup-performance/SKILL.md)).
- Use write mutex for concurrent mutations ([obsidian-workers-threading](../obsidian-workers-threading/SKILL.md)).

## See also

- [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md) — disable/enable sequence
- [obsidian-plugin-sandbox](../obsidian-plugin-sandbox/SKILL.md) — staging recovery
- [obsidian-plugin-testing](../obsidian-plugin-testing/SKILL.md) — `fake-indexeddb` in tests

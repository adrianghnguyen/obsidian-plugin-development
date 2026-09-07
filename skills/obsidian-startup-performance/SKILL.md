---
name: obsidian-startup-performance
description: >-
  Debug Obsidian cold-start time, first-note body paint lag, workspace layout
  cost, and plugin onload stalls. Use when startup is slow, a note title appears
  before the body renders, the Startup time overlay is in play, or Loading plugins
  hangs during plugin onload.
---

# Obsidian startup performance

Diagnose slow cold start and "title before body" paint lag. Combine Obsidian's **Startup time overlay** with plugin-author discipline.

## Official Startup time overlay

Obsidian 1.7.1+ (Settings → General → Advanced → startup timer).

| Bucket | Meaning |
|--------|---------|
| Total app startup | End-to-end launch |
| Initialization | Electron / app shell |
| Vault | File listing + metadata cache |
| Workspace | Restore tabs and layout; eager custom views |
| Core plugins | Bundled plugins |
| Community plugins | Per-plugin lines |

**Workspace** includes time to restore open tabs and custom plugin views — a heavy sidebar view left visible inflates Workspace, not only Community plugins.

Also run **Show debug info** for versions when filing bugs.

## Plugin author rules

From [Optimize plugin load time](https://docs.obsidian.md/Plugins/Releasing/Plugin+guidelines#Optimize+plugin+load+time):

1. **`onload` = register only** — commands, events, settings tab. No heavy IO.
2. **Defer with `onLayoutReady` callback** — never `await onLayoutReady()` inside `onload` (deadlock risk).
3. **Never `await saveData()` in `onload`** — can stall the "Loading plugins" screen indefinitely.
4. **Avoid `onLayoutReady → initLeaf()`** auto-open — inflates Workspace; prefer user-triggered open.
5. **Do not handle `vault.on('create')` for every file** during vault init — batch or defer.
6. **Deferred custom views** — cheap until user opens the tab.

## Core boot IDB noise

During vault init, Obsidian core may log IndexedDB errors (File Recovery, cache). **Ignore as plugin failures** until `onLayoutReady`. Your plugin should not open its own IDB before that gate ([obsidian-workers-threading](../obsidian-workers-threading/SKILL.md)).

## Disruptive probes (user consent)

Before force-quit, `taskkill`, or cold-boot timing scripts:

- Warn: unsaved buffers may be lost; Sync/plugins re-init.
- Wait for explicit `go` / `approve`.
- Until then, use live probes only (`eval` while app is up).

Never use `obsidian restart` for cold timing — may answer a dying process.

## Eval probes

- Keep eval **synchronous** — CLI does not reliably await async IIFEs.
- Paint lag: probe `editor.getValue()` and `.cm-content` text when user reports blank body.
- TIMEOUT on eval = main thread busy — same window as blank-body reports.

## Triage order

1. User-visible: which plugin changed? Recent layout/sidebar tabs?
2. Startup overlay after real cold quit (user consented).
3. Binary-search disable community plugins if one line dominates.
4. High Vault → file count, cloud placeholders, AV scanning.
5. High Workspace → collapse sidebars; close heavy views in saved layout.
6. Paint lag with OK overlay → gutters, post-processors, plugin still `bootPending`.

## Vault-specific harnesses

Optional per-vault scripts (snapshot live, cold boot poll) are **not** bundled here — keep them in your vault's `Administrative/scripts/` if needed. This skill documents the **portable** author and triage rules.

## See also

- [obsidian-workers-threading](../obsidian-workers-threading/SKILL.md) — onLayoutReady, mutex
- [obsidian-plugin-debug](../obsidian-plugin-debug/SKILL.md) — eval boundaries
- [obsidian-indexeddb-storage](../obsidian-indexeddb-storage/SKILL.md) — IDB after restart

---
name: obsidian-workers-threading
description: >-
  Threading and concurrency for Obsidian plugins — onLayoutReady gates, sandboxed
  iframes for CSP-blocked runtimes, Web Workers, write mutexes, and main-thread
  discipline. Use when deferring heavy work, avoiding onload deadlocks, or
  debugging IPC wedges vs in-plugin workers.
---

# Obsidian plugin workers and threading

## onLayoutReady gate

Official guidance: keep `onload` **registration-only**; defer heavy work to `workspace.onLayoutReady`.

```typescript
// WRONG — can deadlock
async onload() {
  await this.app.workspace.onLayoutReady();
}

// RIGHT — callback form
onload() {
  this.registerDomEvent(...);
  this.app.workspace.onLayoutReady(() => {
    this.initHeavyWork();
  });
}
```

Until layout is ready:

- Do not time startup or probe plugin IndexedDB.
- Do not treat core File Recovery / cache / sync IDB errors as your plugin's fault.

## Never block onload

| Anti-pattern | Why |
|--------------|-----|
| `await saveData()` in `onload` | Can stall "Loading plugins" screen |
| `await vault.read()` for many files | Blocks vault init |
| `onLayoutReady → initLeaf()` auto-open | Inflates Workspace startup bucket; surprises users |

Defer IO, indexing, and model load until after layout ready (and often until first user action).

## CLI wedge ≠ worker hang

The Obsidian CLI IPC queue is on the **app main thread**, not inside plugin Web Workers or sandboxed iframes. A wedged CLI (`eval` silent forever) is almost always:

- Chained CLI commands in one shell line
- Parallel CLI across shells
- App modal blocking the main thread

Recovery: [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md). Workers can keep running while CLI is wedged.

## Sandboxed iframe (CSP)

Obsidian's CSP blocks remote `import()` in the main plugin context. Heavy runtimes (e.g. transformers.js, WASM) often run in a `srcdoc` iframe with a permissive CSP injected at creation.

- Parent posts messages; iframe runs inference.
- Tear down iframe in `onunload`.
- Mobile: consider idle unload to save memory.

## Web Workers

Use for CPU-heavy work that must not block UI (e.g. binary scan, large transforms):

- Bundle worker as IIFE string or separate file per esbuild config.
- No DOM access in worker — pass serializable data only.
- Pause or lower priority during in-flight user queries.

## Write mutex (`runExclusive`)

When multiple async paths mutate a shared index:

```typescript
private runExclusive<T>(fn: () => Promise<T>): Promise<T> {
  return this.mutex = this.mutex.then(fn, fn);
}
```

- One writer at a time for IDB + in-memory caches.
- Bump generation on structural changes so readers see consistent snapshots.
- Pause background catch-up while user search is active.

## See also

- [obsidian-startup-performance](../obsidian-startup-performance/SKILL.md) — startup buckets
- [obsidian-indexeddb-storage](../obsidian-indexeddb-storage/SKILL.md) — IDB lifecycle
- [obsidian-plugin-testing](../obsidian-plugin-testing/SKILL.md) — fake workers in tests

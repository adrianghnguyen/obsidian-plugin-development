---
name: obsidian-plugin-testing
description: >-
  Test Obsidian community plugins with Vitest, obsidian type stubs, fake-indexeddb,
  and optional live-network smoke scripts outside CI. Use when setting up unit tests,
  CI typecheck→test→build, or stubbing the Obsidian API.
---

# Obsidian plugin testing

## Stack

| Tool | Role |
|------|------|
| **Vitest** | Unit/integration tests |
| **obsidian** npm package | Types only at build time — `main: ""` |
| **esbuild** | Bundles plugin; externalizes `obsidian` |
| **fake-indexeddb** | W3C-faithful IDB in Node |
| **Test stubs** | `src/test-stubs/obsidian.ts` aliased in `vitest.config` |

## CI order

```bash
npm run typecheck
npm test
npm run build
```

Fail fast on types before tests; never commit `main.js` from CI unless your release process requires it.

## Obsidian API stubs

Only import runtime **values** from `obsidian` if your stub provides them. Most tests mock:

- `Plugin`, `App`, `Vault`, `Workspace`, `Modal`, `Setting`
- `requestUrl` for network (or mock at service boundary)

Alias in `vitest.config.mts`:

```typescript
resolve: {
  alias: { obsidian: path.resolve(__dirname, 'src/test-stubs/obsidian.ts') },
},
```

## IndexedDB in tests

```typescript
import 'fake-indexeddb/auto';
```

Use the same schema code as production; test open/migrate/delete paths without Electron.

## What not to run in `npm test`

- Real embedding model downloads
- Hugging Face / CDN fetches
- Full vault integration

Move those to **optional live smoke scripts** (e.g. `scripts/smoke-live.mjs`) run manually with network and secrets from env — never in default CI.

## Live smoke pattern

```javascript
// scripts/smoke-live.mjs — run outside vitest
// 1. Require API_KEY from env (never commit)
// 2. Connect to running Obsidian via CLI eval OR test harness
// 3. Assert one end-to-end path
```

Document in repo `AGENTS.md` when smoke is required before release.

## Hotkey / modal logic

Pure functions (`eventMatchesHotkey`, `safeRegisterHotkeys`) are easy to unit test without Obsidian — see [obsidian-hotkeys](../obsidian-hotkeys/SKILL.md).

## See also

- [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md) — build before deploy
- [obsidian-indexeddb-storage](../obsidian-indexeddb-storage/SKILL.md) — IDB recovery vs tests
- [obsidian-plugin-review](../obsidian-plugin-review/SKILL.md) — review before publish

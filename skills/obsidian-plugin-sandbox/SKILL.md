---
name: obsidian-plugin-sandbox
description: >-
  Staging sandbox vault for Obsidian plugin development — deploy targets, promote
  contract, community-plugins.json recovery, orphan plugin dirs, and post-sync
  checklist. Use when working in a dedicated test vault before production promotion.
---

# Obsidian plugin sandbox (staging vault)

A **staging vault** is an isolated copy of your production vault for plugin testing. Routine deploy/reload/verify targets staging; production promotion requires explicit user request.

Configure paths in [machine profile](../../references/machine-profile.example.md): `<sandbox-vault-name>`, `<sandbox-vault-path>`.

## Principles

- **Staging-first:** build → copy → reload → verify in sandbox before any production copy.
- **Never auto-promote** after sandbox verification.
- **Promote copies only 3 artifacts:** `main.js`, `manifest.json`, `styles.css` — never `data.json`, sessions, or index folders unless user explicitly asks for a settings migration.

## Routine workflow

```powershell
# 1. Build in repo
npm run build

# 2. Deploy to staging
$dest = "<sandbox-vault-path>\.obsidian\plugins\<plugin-id>\"
Copy-Item main.js, manifest.json, styles.css -Destination $dest -Force

# 3. Reload and verify
obsidian vault=<sandbox-vault-name> plugin:reload id=<plugin-id>
```

## Promote to production

Only when user explicitly requests:

```powershell
# Optional helper script if you maintain one:
powershell -ExecutionPolicy Bypass -File <promote-script> -PluginId "<plugin-id>"
```

Or manual copy to `<production-vault-path>/.obsidian/plugins/<id>/` per [ship-main-prod](../ship-main-prod/SKILL.md).

## Post-sync checklist

After refreshing sandbox content from production:

```powershell
obsidian vault=<sandbox-vault-name> plugins:enabled
```

Compare against production list. Re-enable missing plugins:

```powershell
obsidian vault=<sandbox-vault-name> plugin:enable id=<plugin-id>
```

## Recovery: hangs on "loading plugins"

### Symptom

Obsidian stuck on loading plugins; `community-plugins.json` is `[]` or incomplete.

### Causes

- `app:reload` / `reload` wrote **in-memory** plugin list back to disk when memory had a minimal set.
- Orphan plugin folders missing `manifest.json` or `main.js`.

### Diagnosis

```powershell
Get-Content "<sandbox-vault-path>\.obsidian\community-plugins.json" -Raw
Get-ChildItem "<sandbox-vault-path>\.obsidian\plugins" -Directory | ForEach-Object {
  $m = Join-Path $_.FullName "manifest.json"
  $main = Join-Path $_.FullName "main.js"
  if (!(Test-Path $m) -or !(Test-Path $main)) { $_.Name }
}
```

### Fix

1. Restore `community-plugins.json` from production backup or re-run sync script.
2. Remove orphan directories: `Remove-Item -Recurse -Force <orphan-dir>`
3. Cold start Obsidian.

## Sync isolation

Staging vaults often disable Obsidian Sync and omit sensitive folders. Document your sandbox's git scope and sync policy in the vault's own `AGENTS.md`.

## See also

- [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md) — vault targeting
- [obsidian-plugin-tweaks](../obsidian-plugin-tweaks/SKILL.md) — fork deploy
- [obsidian-indexeddb-storage](../obsidian-indexeddb-storage/SKILL.md) — clean slate in sandbox

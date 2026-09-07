---
name: ship-main-prod
description: >-
  Squash-lands current Obsidian plugin work onto main, pushes origin/main, builds,
  and deploys to the production vault. Use when the user says "ship main prod",
  "/ship-main-prod", "promote worktree to main", "squash merge to main and deploy
  to production", or asks to promote a plugin worktree/branch to main and deploy to
  the main Obsidian vault. Works for any plugin repo with manifest.json. Explicit
  invoke only — never auto-promote.
disable-model-invocation: true
---

# Ship Main Prod

Squash current plugin work onto `main`, push, build, deploy to **production** vault.

Do **not** deploy to sandbox as part of this skill. Serial CLI: [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md). Build/reload: [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md).

Paths: `<production-vault-path>`, `<production-vault-name>` from [machine profile](../../references/machine-profile.example.md).

## Resolve plugin

From workspace git root:

1. Require `manifest.json` with `id`.
2. Production dir: `<production-vault-path>/.obsidian/plugins/<id>/`
3. Artifacts: `main.js`, `manifest.json`, `styles.css` if present
4. Build: `npm run build`

## Procedure

### 1. Git — squash onto main

| Situation | Action |
|-----------|--------|
| Feature branch ahead of `main` | Fetch; checkout `main`; `git merge --squash <branch>`; one conventional commit |
| On `main` with uncommitted work | Stage; one commit |
| Clean `main` already pushed | Skip commit; build/deploy if user wants prod refresh |

Never `--force` push; never amend pushed commits. No manifest bump unless user asked in same invoke.

### 2. Push

```powershell
git push origin main
```

### 3. Build

`npm run typecheck` / `npm test` if not already green. `npm run build`. Do not commit `main.js`.

### 4. Copy to production

```powershell
$dest = "<production-vault-path>\.obsidian\plugins\<id>"
Copy-Item -Force main.js, manifest.json -Destination $dest
if (Test-Path styles.css) { Copy-Item -Force styles.css -Destination $dest }
```

Compare manifest hash before copy to choose reload strategy. **Do not copy `data.json`.**

### 5. Reload

- Manifest unchanged: `obsidian plugin:reload id=<id> vault=<production-vault-name>` OR cwd production + omit `vault=`
- Manifest changed: warn; prefer `command id=app:reload` or full restart with user consent

**One CLI command per shell invocation.**

### 6. Verify

```powershell
Get-FileHash repo\main.js
Get-FileHash <production-vault-path>\.obsidian\plugins\<id>\main.js
obsidian eval code="JSON.stringify({id:app.plugins.plugins['<id>']?.manifest?.id,version:app.plugins.plugins['<id>']?.manifest?.version})"
```

(Run eval with production cwd / vault targeting per multi-vault skill.)

### 7. Report

Commit hash, plugin id, production path, reload used, hash match. Remind user to close/reopen plugin UI.

## Out of scope

- Sandbox deploy
- Force-push
- Auto-running without explicit user invoke

## See also

- [obsidian-plugin-sandbox](../obsidian-plugin-sandbox/SKILL.md) — promote contract
- [obsidian-plugin-tweaks](../obsidian-plugin-tweaks/SKILL.md) — fork workflow

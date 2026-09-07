---
name: obsidian-plugin-tweaks
description: >-
  Fork and customize Obsidian community plugins, deploy builds into the vault
  plugin folder, and document local tweaks. Use when forking a community plugin,
  setting up origin/upstream remotes, deploying a fork after code changes, or
  choosing fork vs in-vault patch vs snippets-only customization.
---

# Obsidian plugin tweaks (fork, deploy, catalog)

Out-of-vault layout:

```
<coding-projects>/<repo>/  → build →  <sandbox-vault-path>/.obsidian/plugins/<id>/ (staging)
                                    ↓ (explicit user request only)
                             <production-vault-path>/.obsidian/plugins/<id>/ (production)
```

Keep the community plugin `id` in `manifest.json` so hotkeys and synced `data.json` keep working. Gitignore `data.json`, secrets, and session folders in the repo.

## Fork repo

```powershell
cd <coding-projects>
gh repo fork <owner>/<repo> --clone --remote=true
```

- `origin` = your fork; `upstream` = parent
- Push/PR to **origin** only
- Upstream sync: merge on `sync/upstream-<version>` branch
- Do **not** use Community plugins **Update** for a fork — overwrites your build

Optional per-fork: repo `AGENTS.md` + `.cursor/rules/deploy-and-verify.mdc` with plugin id and sandbox deploy path.

## Fork vs patch vs snippets-only

| Approach | When |
|----------|------|
| **Snippets-only** | CSS-only or config in `data.json` — no code change |
| **In-vault patch** | Small `main.js` edit in vault plugin folder; document in per-plugin `AGENTS.md` in vault; no git fork |
| **Fork** | Ongoing changes, tests, PRs upstream |

### In-vault patch pattern

1. Edit `<vault>/.obsidian/plugins/<id>/main.js` (backup first).
2. Add `<vault>/.obsidian/plugins/<id>/AGENTS.md` describing the patch and why.
3. **Never** use Community Update on that plugin.
4. Re-apply patch after manual copy deploy from fork if you also maintain a repo.

## Deploy checklist

1. `npm run typecheck` / `npm test` when present
2. `npm run build`
3. User-facing change? `CHANGELOG.md` `[Unreleased]` (no manifest bump)
4. Copy **only** `main.js`, `manifest.json`, `styles.css` — never `data.json`
5. `obsidian vault=<sandbox-vault-name> plugin:reload id=<id>`
6. Verify disk + eval
7. Promote only when user asks — see [obsidian-plugin-sandbox](../obsidian-plugin-sandbox/SKILL.md)

Release gate: [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md).

## Per-vault-plugin AGENTS.md template

```markdown
# AGENTS.md (<plugin-id> in <vault-name>)

## Patch / fork status
- Source: fork at <repo-url> OR in-vault patch dated YYYY-MM-DD
- Do not use Community Update

## Deploy
- Staging: <sandbox-vault-path>/.obsidian/plugins/<id>/
- Production: promote only on explicit user request

## Secrets / local settings
- List secret ids and device-local keys (never values)
```

## See also

- [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md) — build, reload, semver
- [obsidian-plugin-debug](../obsidian-plugin-debug/SKILL.md) — staging verify
- [ship-main-prod](../ship-main-prod/SKILL.md) — production promote

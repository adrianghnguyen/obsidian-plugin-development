# Agent notes

## Cursor plugin install (this repo)

- **Local `:latest`:** `~/.cursor/plugins/local/obsidian-plugin-development` should be a junction to this working tree (`C:\Coding_projects\obsidian-plugin-development`), not a pinned marketplace commit. After skill edits: **Developer: Reload Window**.
- **Marketplace unpin:** Personal `/add-plugin` installs pin to the first commit; `marketplace update` does not advance them. Use `powershell -File scripts/refresh-cursor-marketplace.ps1` (remove + wipe cache + re-add `--git-ref main`).
- **Post-push:** `scripts/git-hooks/post-push` runs that refresh after `git push`. Install once: `powershell -File scripts/git-hooks/install.ps1`. Reload Cursor after push.

## Cursor Cloud environment

This repo owns the Cloud Agent setup. Sibling plugin `main`s carry the same `.cursor/environment.json`; **script and id-map bodies live only here**.

- Pointer: `.cursor/environment.json` (`install` / `start` — identical on all four plugin repos)
- Scripts: `scripts/cloud-e2e/env-install.sh`, `env-start.sh`, `install-acp-agents.sh`, `paths.env`
- Walkthrough: `scripts/cloud-e2e/README.md`, `GETTING-STARTED.md`
- Secret **ids** (not values): plugin-owned `<plugin>/.cloud-e2e/secret-bindings.json` (agent-client, whisper). Fallbacks: `scripts/cloud-e2e/bindings/{agent-client,whisper,seek}.json`, merged by `load-bindings.mjs` (`cdp.mjs inject`)
- Identity gate is not a separate file: `env-start.sh` CDP eval; vault name/path from `paths.env` (`CLOUD_E2E_VAULT_NAME` / `CLOUD_E2E_VAULT`)

Project overview (do not copy): `/cursor/stores/bc-a8a2e9ee-3f2b-4d31-ae8c-85b3734c071e/docs/cursor-environment-docs.md`

## Plugin release notes

When shipping sibling Obsidian plugins, use **detailed** changelog sections (Added/Changed/Fixed), **annotated tags** (headline + bullet lines), and **published GitHub Releases** (optional body from CHANGELOG) — production installs via BRAT. Full standard: `skills/obsidian-plugin-dev/SKILL.md` → *Release notes and semantic versioning*.

## PR product demos

**Complex features** and **user-facing behavioral changes** need a cloud VM **`.mp4` screen recording** walkthrough **embedded in the PR description** (screenshots-only is not enough for those PRs). Same “complex” bar as `rules/trigger-ui-verifier-demo.mdc`. Procedure: `skills/obsidian-cloud-vm-demos/SKILL.md` and `.cursor/rules/pr-product-demos.mdc`.

## UI jank verification

Before UI work is PR-ready, run the **UI jank pass/fail checklist** during the demo walkthrough (layout shift, flicker, alignment, overlays, focus, motion). Skills: `skills/obsidian-visual-verify/SKILL.md`, `skills/ux-design/SKILL.md`; recorded in BDD reports via `skills/obsidian-ui-verifier-demo/SKILL.md`.

## UI verifier demo (BDD functional)

Large or behavioral plugin work must delegate **`/ui-verifier-demo`** before done. The subagent runs happy and unhappy paths, writes `ui-verifier-demo-report.md` (**PASS** / **PARTIAL** / **FAIL**), and on failure explains **expected vs observed** behavior and the **BDD gap**. Skill: `skills/obsidian-ui-verifier-demo/SKILL.md`. Rule: `rules/trigger-ui-verifier-demo.mdc`. **Does not replace** the `.mp4` product demo or jank gate above when both apply.

## PR acceptance review (before human verify)

Before moving work to **🟠 Requires user input**, delegate **`/pr-acceptance-review`**. The subagent derives acceptance criteria from the PR, reviews embedded demo media, and updates the PR body with **`## Acceptance review`** (checklist + evidence). Skill: `skills/obsidian-pr-acceptance-review/SKILL.md`. Agent stub: `.cursor/agents/pr-acceptance-review.md`. **Do not** ask Adrian to verify until **Verdict: PASS** and all AC boxes are checked.

## Agent Client — verify UX

When demos or verification touch floating chat, multi-session, or tabs: use **tabbed floating chat** (Settings → Floating chat → Enable floating chat tabs; multiple sessions as tabs in one floating window), not sidebar-only, unless the task is sidebar-specific. Fork playbook: `obsidian-agent-client` repo `AGENTS.md` → *Cloud Agent UI demos*.

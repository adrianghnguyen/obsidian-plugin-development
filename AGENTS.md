# Agent notes

## Cursor plugin install (this repo)

- **Local `:latest`:** `~/.cursor/plugins/local/obsidian-plugin-development` should be a junction to this working tree (`C:\Coding_projects\obsidian-plugin-development`), not a pinned marketplace commit. After skill edits: **Developer: Reload Window**.
- **Marketplace unpin:** Personal `/add-plugin` installs pin to the first commit; `marketplace update` does not advance them. Use `powershell -File scripts/refresh-cursor-marketplace.ps1` (remove + wipe cache + re-add `--git-ref main`).
- **Post-push:** `scripts/git-hooks/post-push` runs that refresh after `git push`. Install once: `powershell -File scripts/git-hooks/install.ps1`. Reload Cursor after push.

## Cursor Cloud environment

This repo owns the Cloud Agent setup. Sibling plugin `main`s carry the same `.cursor/environment.json`; **script and id-map bodies live only here**.

- Pointer: `.cursor/environment.json` (same `install` / `start` / `repositoryDependencies` on all plugin `main`s — see [`.cursor/rules/cloud-environment-alignment.mdc`](.cursor/rules/cloud-environment-alignment.mdc))
- **`install` / `start`** run `.cursor/cloud-bootstrap.sh`, which symlinks or clones `/agent/repos/*` then calls orchestrator `env-install.sh` / `env-start.sh`. Keep **`repositoryDependencies`** listing every sibling checkout (token scope + agent runs); orchestrator-primary builds may not pre-clone `/agent/repos` — bootstrap covers that.
- Scripts: `scripts/cloud-e2e/bootstrap-cloud-repos.sh`, `env-install.sh`, `env-start.sh`, `install-acp-agents.sh`, `paths.env`
- Walkthrough: `scripts/cloud-e2e/README.md`, `GETTING-STARTED.md`
- Secret **ids** (not values): plugin-owned `<plugin>/.cloud-e2e/secret-bindings.json` (agent-client, whisper). Fallbacks: `scripts/cloud-e2e/bindings/{agent-client,whisper,seek}.json`, merged by `load-bindings.mjs` (`cdp.mjs inject`)
- Identity gate is not a separate file: `env-start.sh` CDP eval; vault name/path from `paths.env` (`CLOUD_E2E_VAULT_NAME` / `CLOUD_E2E_VAULT`)

Project overview (do not copy): `/cursor/stores/bc-a8a2e9ee-3f2b-4d31-ae8c-85b3734c071e/docs/cursor-environment-docs.md`

## Plugin release notes

When shipping sibling Obsidian plugins, use **detailed** changelog sections (Added/Changed/Fixed), **annotated tags** (headline + bullet lines), and **published GitHub Releases** (optional body from CHANGELOG) — production installs via BRAT. Full standard: `skills/obsidian-plugin-dev/SKILL.md` → *Release notes and semantic versioning*.

**Every git tag** (stable and `-rc.*`) must ship a **new unique** `manifest.json` `version` in the same change — never reuse a tag’s version or bump later. Settings UI version string must match that manifest. Always-on rule: `.cursor/rules/obsidian-manifest-per-tag.mdc`.

## Process visibility

Any process that is **not Ready** must show a descriptive progress indicator (phase label plus `done/total` or `%` when known). Static “Starting up”, “Working”, “Busy”, or **0% with no motion** is a bug. Applies to Seek, Agent Client, Whisper, and Book Search. Always-on rule: `.cursor/rules/obsidian-process-visibility.mdc`. Seek’s repo-local `.cursor/rules/ui-status-first-class.mdc` stays Seek-only — do not duplicate it here.

## Metrics fit the UI

Counts, percents, and timestamps must **stay inside their slot**. Overflow (wrapping out of a Settings metric box, colliding with the next control, clipping mid-digit) is a bug. Prefer right-aligning values, tabular-nums, reserved width, or a shorter label — never clip or wrap the value out of the box. Always-on rule: `.cursor/rules/obsidian-metrics-fit-ui.mdc`.

## PR draft vs ready for review

Create PRs as **Draft** by default. After deploy verify and an embedded demo, run **`obsidian-pr-ship-sync`** and **hand off in Draft** for Adrian unless the user asked to mark Ready. Rule: `.cursor/rules/pr-draft-ready.mdc`; procedure: `skills/obsidian-pr-ship-sync/SKILL.md`.

## PR product demos

**Complex features** and **user-facing behavioral changes** need a cloud VM **`.mp4`** embedded in the PR with **What to look for** bullets (screenshots-only is not enough for those PRs). Heuristics: `.cursor/rules/pr-product-demos.mdc`. Procedure: `skills/obsidian-cloud-vm-demos/SKILL.md`. **Recording:** delegate **`/ui-demo-agent`** ([agents/ui-demo-agent.md](agents/ui-demo-agent.md), **model `composer-2.5-fast`**) or follow `skills/obsidian-agent-ui-demo/SKILL.md` — preflight off camera, brief pauses on key UX proof moments, human handoff.

## UI jank verification

Run the **UI jank pass/fail checklist** during the demo walkthrough (layout shift, flicker, alignment, overlays, focus, motion). Skills: `skills/obsidian-visual-verify/SKILL.md`, `skills/ux-design/SKILL.md`.

## UI visibility (before any demo)

Before a screenshot or screen recording, run **`obsidian-ui-visibility`**. The demo fails if Settings, a modal, or another window covers the control, or if the control is missing, off screen, or too small to see. Skill: `skills/obsidian-ui-visibility/SKILL.md`.

## PR acceptance review (optional)

Optional **`/pr-acceptance-review`** subagent can append a structured **`## Acceptance review`** block after checking embedded media. Not required for human handoff. Skill: `skills/obsidian-pr-acceptance-review/SKILL.md`; agent: `.cursor/agents/pr-acceptance-review.md`.

## Agent Client — verify UX

When demos or verification touch floating chat, multi-session, or tabs: use **tabbed floating chat** (Settings → Floating chat → Enable floating chat tabs; multiple sessions as tabs in one floating window), not sidebar-only, unless the task is sidebar-specific. Fork playbook: `obsidian-agent-client` repo `AGENTS.md` → *Cloud Agent UI demos*.

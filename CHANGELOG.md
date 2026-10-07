# Changelog

All notable changes to this Agent Plugin package are documented here.

## [Unreleased]

### Added

- **`ui-demo-agent` subagent** — cloud VM UI demo recorder; **model `composer-2.5-fast`**; pairs with `obsidian-agent-ui-demo` skill.
- **`obsidian-agent-ui-demo` skill** — token-efficient demo phases for Cloud Agents (script/preflight off camera, short proof clip, pause on key UX proof moments, computerUse contract shape); linked from `pr-product-demos` and `obsidian-cloud-vm-demos`.

### Removed

- **`ui-verifier-demo` subagent**, **`obsidian-ui-verifier-demo` skill**, and **`trigger-ui-verifier-demo` rule** — replaced by record → embed `.mp4` → **What to look for** → Draft handoff to Adrian ([obsidian-agent-ui-demo](skills/obsidian-agent-ui-demo/SKILL.md)).

### Changed

- **Demo agent stop + parent kickoff** — `ui-demo-agent` stops if the named control is missing after one visibility check (no Settings, File menu, vault sidebar, or nested explorer). Coordinators name one shell command and, when restore/reload is the proof, the code entry ([obsidian-agent-ui-demo](skills/obsidian-agent-ui-demo/SKILL.md)).
- **Demo pacing** — no fixed second counts; move quickly between steps, pause briefly on readable proof frames ([obsidian-agent-ui-demo](skills/obsidian-agent-ui-demo/SKILL.md), [pr-product-demos](.cursor/rules/pr-product-demos.mdc), [obsidian-cloud-vm-demos](skills/obsidian-cloud-vm-demos/SKILL.md)).
- **`pr-draft-ready` / `pr-product-demos`** — human handoff stays **Draft** until Adrian marks Ready; optional `/pr-acceptance-review`.
- **`obsidian-pr-ship-sync`** — sync embeds + **What to look for**; `draft: false` only when user requests Ready.

### Added (prior)

- **`obsidian-ui-visibility` skill** — checks that must pass before a screenshot or screen recording: Settings and modals closed, target control mounted and on screen, not covered, large enough to see, and hover demos use the real pointer.
- `obsidian-cloud-vm-demos` skill — strict verification on Cursor Cloud VMs (runtime proof, mandatory screenshots for UI, identity gate, local vs cloud gap reporting, PR description embedded artifact URLs per Cloud Agents GitHub posting).
- Cloud Linux E2E harness (`scripts/cloud-e2e`) — synthetic vault, AppImage + Xvfb, CDP injection of Cursor env secrets into Obsidian `secretStorage`.
- Skill `obsidian-cloud-e2e` for Cloud Agent in-vault testing.
- Skill `obsidian-cloud-env-setup` — generalized process to bake a Cloud Obsidian environment (sample files, Restricted mode + CLI toggles, per-plugin verify, snapshot → Save).
- Skill `obsidian-secret-mapping` — how Whisper / Agent Client / Seek read `secretStorage` ids vs Cursor env vars; per-plugin `.cloud-e2e/secret-bindings.json`.

### Changed

- **Single definition for Obsidian vault targeting.** The global rule `obsidian-vault-target-verify` now solely defines how `vault=` resolves (exact basename, first argument), the `basePath` discovery gate, and “no printed path means stop.” `obsidian-multi-vault-cli`, `obsidian-plugin-dev`, `obsidian-plugin-debug`, `obsidian-cloud-vm-demos`, `obsidian-ui-verifier-demo`, `ship-main-prod`, `obsidian-plugin-sandbox`, `obsidian-plugin-tweaks`, `obsidian-visual-verify`, `obsidian-indexeddb-storage`, `seek-seinfeld-eval`, `obsidian-settings-secrets`, the machine-profile references, and the `ui-verifier-demo` agent now defer by name instead of restating the mechanics.
- **`obsidian-visual-verify` scripts enforce the target.** `Invoke-ObsidianCliSerial` now prepends `vault=` so it is always the first argument, and `Assert-ObsidianVaultTarget` gates on `app.vault.adapter.basePath`. `Invoke-ObsidianCliSerial` returns a string (was `{ Output, ExitCode }`); `Ensure-ObsidianVaultReady` and `capture-surfaces.ps1` gain `-ExpectedBasePath`.
- **`obsidian-plugin-dev` skill** — detailed release-notes standard (CHANGELOG Added/Changed/Fixed, annotated tag headline + bullets, GitHub Release publish/body, BRAT production path); `AGENTS.md` pointer.
- **`pr-product-demos` rule** — embedded `.mp4` + **What to look for**; delegates **`ui-demo-agent`** (`composer-2.5-fast`).
- Cloud E2E does not inject `ANTHROPIC_API_KEY`; Claude Code stays account-login in the synthetic vault.

## [0.1.2] - 2026-09-13

### Changed

- `obsidian-hotkeys` — when adding hotkeys, consider and propose focus-scoped `View.scope` / `Modal.scope` vs global `addCommand` bindings.
- `obsidian-multi-vault-cli`, `obsidian-plugin-debug`, `obsidian-plugin-dev` — require exact vault name for `vault=` CLI targeting (substring matching can hit the wrong vault).

### Added

- `AGENTS.md` — local plugin junction to this repo (`:latest`) and post-push marketplace refresh hook.
- `scripts/git-hooks/post-push` (+ `install.ps1`) — after `git push`, run marketplace refresh.
- `scripts/refresh-cursor-marketplace.ps1` — remove + wipe pin + re-add `--git-ref main` (unpins stale personal marketplace cache).
- README section **How to update plugin repo after changes** (junction + reload + push + unpin refresh).

## [0.1.1] - 2026-09-07

### Added

- `ux-design` skill — concise UX principles (transparency, cognitive load, jargon tooltips, all states, errors, recognition over recall); auto-invokes for UI work.
- `ux-gap-audit` skill — explicit audit agent for gathering feedback and reporting workflow gaps against `ux-design`.

### Changed

- `obsidian-plugin-review` — cross-links to `ux-design` and `ux-gap-audit`.

## [0.1.0] - 2026-09-06

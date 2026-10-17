# Changelog

All notable changes to this Agent Plugin package are documented here.

## [Unreleased]

### Added

- **`obsidian-metrics-fit-ui` global rule** (`.cursor/rules/obsidian-metrics-fit-ui.mdc`, `alwaysApply: true`) — counts, percents, and timestamps must stay inside their Settings / status / reporter slot; overflow is a bug. Prefer right-aligning values, tabular-nums, reserved width, or a shorter label — never clip or wrap the value out of the box. Cross-plugin (Seek, Agent Client, Whisper, Book Search). Pointers in `AGENTS.md` and [ux-design](skills/ux-design/SKILL.md).
- **`obsidian-process-visibility` global rule** (`.cursor/rules/obsidian-process-visibility.mdc`, `alwaysApply: true`) — any non-Ready process (hydrate / index / restore / embed / catch-up / recover / connect) must show a human phase label plus `done/total` or `%` when known; static Starting up / Working / Busy or 0% with no motion is a bug; status bar, Settings, and shared reporter chrome stay consistent. Cross-plugin SSoT (Seek, Agent Client, Whisper, Book Search). Pointers in `AGENTS.md`, [ux-design](skills/ux-design/SKILL.md), [obsidian-plugin-review](skills/obsidian-plugin-review/SKILL.md). Do not copy Seek’s `ui-status-first-class` rule into this repo.
- **`obsidian-manifest-per-tag` global rule** (`.cursor/rules/obsidian-manifest-per-tag.mdc`, `alwaysApply: true`) — every new git tag (stable **and** `-rc.*`) must bump `manifest.json` `version` to a unique Obsidian-compatible semver (`X.Y.Z` or `X.Y.Z-rc.N`) in the same change as the tag; Settings UI version must match; pointers in `AGENTS.md` and [obsidian-plugin-dev](skills/obsidian-plugin-dev/SKILL.md).
- **`obsidian-vault-target-verify` global rule** (`.cursor/rules/obsidian-vault-target-verify.mdc`, `alwaysApply: true`) — open the vault first; identity-gate `app.vault.getName()` **and** `app.vault.adapter.basePath` before every CLI command; `vault=` first; **never** `vault=Obsidian`; omit `vault=` for Windows production (`cwd` `C:\Obsidian`); do not interrupt a production full reindex. Skills already pointed here; the file was missing.
- **`ui-demo-agent` subagent** — cloud VM UI demo recorder; **model `composer-2.5-fast`**; pairs with `obsidian-agent-ui-demo` skill.
- **`obsidian-agent-ui-demo` skill** — token-efficient demo phases for Cloud Agents (script/preflight off camera, short proof clip, pause on key UX proof moments, computerUse contract shape); linked from `pr-product-demos` and `obsidian-cloud-vm-demos`.

### Removed

- **`ui-verifier-demo` subagent**, **`obsidian-ui-verifier-demo` skill**, and **`trigger-ui-verifier-demo` rule** — replaced by record → embed `.mp4` → **What to look for** → Draft handoff to Adrian ([obsidian-agent-ui-demo](skills/obsidian-agent-ui-demo/SKILL.md)).

### Changed

- **Release gate** — on **every** tagged vault-plugin version (minors **and** RCs), sync the Settings UI version string with `manifest.json` so Settings does not mislead about the installed version ([obsidian-plugin-dev](skills/obsidian-plugin-dev/SKILL.md), [obsidian-manifest-per-tag](.cursor/rules/obsidian-manifest-per-tag.mdc)).
- **Unobstructed UI demo** — proof frame must show the named feature with Settings and other modals closed. A clip of Settings (or any overlay hiding the control) is inconclusive; re-record ([obsidian-agent-ui-demo](skills/obsidian-agent-ui-demo/SKILL.md), [obsidian-ui-visibility](skills/obsidian-ui-visibility/SKILL.md)).
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

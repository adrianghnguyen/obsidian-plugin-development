# Changelog

All notable changes to this Agent Plugin package are documented here.

## [Unreleased]

## [0.1.3] - 2026-09-20

### Added

- `obsidian-cloud-vm-demos` skill — strict verification on Cursor Cloud VMs (runtime proof, mandatory screenshots for UI, identity gate, local vs cloud gap reporting, PR description embedded artifact URLs per Cloud Agents GitHub posting).
- Cloud Linux E2E harness (`scripts/cloud-e2e`) — synthetic vault, AppImage + Xvfb, CDP injection of Cursor env secrets into Obsidian `secretStorage`.
- Skill `obsidian-cloud-e2e` for Cloud Agent in-vault testing.
- Skill `obsidian-cloud-env-setup` — generalized process to bake a Cloud Obsidian environment (sample files, Restricted mode + CLI toggles, per-plugin verify, snapshot → Save).
- Skill `obsidian-secret-mapping` — how Whisper / Agent Client / Seek read `secretStorage` ids vs Cursor env vars; per-plugin `.cloud-e2e/secret-bindings.json`.

### Changed

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

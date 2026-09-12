# Changelog

All notable changes to this Agent Plugin package are documented here.

## [Unreleased]

### Changed

- `obsidian-hotkeys` — when adding hotkeys, consider and propose focus-scoped `View.scope` / `Modal.scope` vs global `addCommand` bindings.

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

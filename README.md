# Obsidian Plugin Development

A **Cursor Agent Plugin** (not an Obsidian community plugin) that packages portable agent skills for building, debugging, and verifying Obsidian community plugins.

Skills cover build/deploy/reload, multi-vault CLI safety, settings navigation, fork workflows, hotkeys, IndexedDB, workers/threading, secrets, startup performance, visual verification, sandbox staging, testing, and Plugin Review antipatterns.

## Install

1. Clone this repo.
2. Point Cursor at the plugin root (folder containing `plugin.json`), or install via [Agent Plugins](https://agent-plugins.org/) when your Cursor version supports it.
3. Copy [`references/machine-profile.example.md`](references/machine-profile.example.md) locally and fill in your sandbox/production vault paths.

**Windows eval quoting:** install the companion skill [`powershell-agent`](https://github.com/adrianghnguyen/cursor-skills) globally if you use `obsidian eval` from PowerShell.

## Skill index

| Skill | Load when |
|-------|-----------|
| [obsidian-plugin-dev](skills/obsidian-plugin-dev/SKILL.md) | Build, deploy, reload, verify artifacts, changelog/semver release gate |
| [obsidian-plugin-debug](skills/obsidian-plugin-debug/SKILL.md) | DevTools, `eval`, screenshots, runtime probes, PowerShell-safe eval |
| [obsidian-multi-vault-cli](skills/obsidian-multi-vault-cli/SKILL.md) | Multiple vaults open, `vault=` targeting, serial CLI, reload escalation |
| [obsidian-menu-settings](skills/obsidian-menu-settings/SKILL.md) | Navigate Settings tabs, popout windows, settings screenshots |
| [obsidian-plugin-tweaks](skills/obsidian-plugin-tweaks/SKILL.md) | Fork community plugins, upstream sync, staging deploy, in-vault patches |
| [ship-main-prod](skills/ship-main-prod/SKILL.md) | User explicitly asks to squash to `main` and deploy to production vault |
| [obsidian-hotkeys](skills/obsidian-hotkeys/SKILL.md) | Modal hotkeys, `addCommand` defaults, editor key hijacking |
| [obsidian-indexeddb-storage](skills/obsidian-indexeddb-storage/SKILL.md) | IndexedDB open/delete/blocked, corruption recovery |
| [obsidian-workers-threading](skills/obsidian-workers-threading/SKILL.md) | `onLayoutReady`, iframes, Web Workers, write mutexes, main-thread discipline |
| [obsidian-settings-secrets](skills/obsidian-settings-secrets/SKILL.md) | `data.json`, `secretStorage`, device-local settings, settings UI gate |
| [obsidian-startup-performance](skills/obsidian-startup-performance/SKILL.md) | Slow startup, overlay buckets, `onload` stalls, paint lag |
| [obsidian-visual-verify](skills/obsidian-visual-verify/SKILL.md) | Screenshot proof after UI/CSS/layout changes |
| [obsidian-plugin-sandbox](skills/obsidian-plugin-sandbox/SKILL.md) | Staging vault, promote contract, `community-plugins.json` recovery |
| [obsidian-plugin-testing](skills/obsidian-plugin-testing/SKILL.md) | Vitest, Obsidian stubs, `fake-indexeddb`, live smoke tests |
| [obsidian-plugin-review](skills/obsidian-plugin-review/SKILL.md) | Plugin Review antipatterns, UI transparency for new states |

## Machine profile

Skills use placeholders (`<sandbox-vault-name>`, `<sandbox-vault-path>`, `<production-vault-path>`, `<plugin-id>`). Copy the example profile and customize for your machine — do not commit local paths to a public fork unless intentional.

## Official references

- [Build a plugin](https://docs.obsidian.md/Plugins/Getting+started/Build+a+plugin)
- [Obsidian CLI](https://obsidian.md/help/cli)
- [Developer commands](https://obsidian.md/help/cli#Developer+commands)
- [Optimize plugin load time](https://docs.obsidian.md/Plugins/Releasing/Plugin+guidelines#Optimize+plugin+load+time)

## What stays in plugin repos

Plugin-specific skills remain in fork repos: telemetry playbooks, plugin UI smoke tests, protocol-specific docs. When a fork learns something **generic**, add it here instead of duplicating across repos.

## Contributing

1. Add or extend a skill under `skills/<skill-name>/SKILL.md` with valid YAML frontmatter (`name`, `description`).
2. Cross-link sibling skills with relative paths.
3. Avoid machine-specific hardcoding — use placeholders or `references/machine-profile.example.md`.
4. Update this README skill index and `CHANGELOG.md`.

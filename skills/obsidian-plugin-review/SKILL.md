---
name: obsidian-plugin-review
description: >-
  Obsidian Plugin Review antipatterns and UI transparency — no innerHTML, no
  detach leaves, CSS-only styling, Platform not process.platform, and exposing
  new user-visible states in Settings or status UI. Use before publishing or when
  refactoring plugin UI for Community release.
---

# Obsidian plugin review (antipatterns)

Official review criteria plus field-learned gates. Apply before Community submission and during refactors.

## Critical antipatterns

| Rule | Do | Don't |
|------|-----|-------|
| DOM creation | `createEl`, `createDiv`, `createSpan` | `innerHTML`, `outerHTML` |
| Leaf cleanup | Let Obsidian manage workspace leaves | `detach()` leaves in `onunload` |
| Styling | `styles.css` classes | JS `element.style.*` for layout/theme |
| Platform | `Platform.isMacOS`, `Platform.isMobile` | `process.platform` |
| Types | Proper Obsidian types | Excessive `any` |

## UI transparency gate

Every **new user-visible state** must appear in at least one of:

- Settings tab (name + description)
- Status bar item
- Modal or notice copy
- Command palette command name

Examples: indexing %, connection status, error backoff, "not ready" search block.

**Silent background behavior** confuses users and reviewers.

## CSS-only styling

- Scope with plugin-specific class prefixes on containers.
- Coordinate `body` classes set in plugin code with optional vault CSS snippets.
- After `styles.css` deploy: close/reopen modals; escalate reload per [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md).

## Settings changes

New toggles need:

- Default in `DEFAULT_SETTINGS`
- Migration in `loadSettings()` if key renamed
- Visible row in `PluginSettingTab`
- Bullet in `CHANGELOG.md` when user-facing

Secrets: [obsidian-settings-secrets](../obsidian-settings-secrets/SKILL.md).

## Hotkeys

Do not ship bare editor keys as global defaults — [obsidian-hotkeys](../obsidian-hotkeys/SKILL.md).

## Performance

`onload` registration only — [obsidian-startup-performance](../obsidian-startup-performance/SKILL.md).

## Pre-submit checklist

```
- [ ] No innerHTML/outerHTML in src/
- [ ] No detach() on leaves in onunload
- [ ] styles.css covers new UI; no inline style hacks
- [ ] Platform.* for OS checks
- [ ] New states visible in Settings/status/modal
- [ ] CHANGELOG [Unreleased] updated
- [ ] README or settings describe permissions (network, files)
- [ ] Visual verify for UI changes ([obsidian-visual-verify](../obsidian-visual-verify/SKILL.md))
```

## See also

- [ux-design](../ux-design/SKILL.md) — UX principles while building
- [ux-gap-audit](../ux-gap-audit/SKILL.md) — workflow gap report
- [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md) — release gate
- [obsidian-settings-secrets](../obsidian-settings-secrets/SKILL.md) — credentials UX
- Official: https://docs.obsidian.md/Plugins/Releasing/Plugin+guidelines

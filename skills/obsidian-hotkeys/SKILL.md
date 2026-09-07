---
name: obsidian-hotkeys
description: >-
  Obsidian plugin hotkey patterns — avoid hijacking editor keys with addCommand
  defaults, chorded bindings, in-modal keydown fallbacks, and hotkeyManager
  effective bindings. Use when registering modal commands, footer hint labels,
  or debugging keys stolen from the editor while typing.
---

# Obsidian plugin hotkeys

## The hijacking problem

Obsidian's keymap **claims registered command hotkeys globally**, even when `checkCallback` returns `false`. Bare `ArrowUp`, `ArrowDown`, `Enter`, `Tab`, or `Escape` in `addCommand({ hotkeys: … })` steal those keys from the editor — not only when your modal is active.

## Pattern

| Layer | What to do |
|-------|------------|
| `addCommand` defaults | **Chorded** bindings only (`Mod+Enter`, `Alt+Enter`, …). Omit bare editor keys. |
| In-modal handler | Bare keys as **local fallbacks** on the focused field (`keydown`). Match user's effective binding from `hotkeyManager`. |
| Footer / hints | Show **live** binding (custom or fallback), not only `addCommand` defaults. |

Commands stay listed in Settings → Hotkeys for remapping.

## Editor-conflicting bare keys

```typescript
export const EDITOR_CONFLICTING_BARE_KEYS = new Set([
  'ArrowUp', 'ArrowDown', 'Enter', 'Tab', 'Escape',
]);

export function safeRegisterHotkeys(fallback: Hotkey[]): Hotkey[] | undefined {
  const safe = fallback.filter(
    h => h.modifiers.length > 0 || !EDITOR_CONFLICTING_BARE_KEYS.has(h.key),
  );
  return safe.length > 0 ? safe : undefined;
}

// addCommand({ hotkeys: safeRegisterHotkeys(spec.hotkeys), ... })
```

## Effective hotkeys (user remaps)

```typescript
function effectiveHotkeys(app: App, fullCommandId: string, fallback: Hotkey[]): Hotkey[] {
  const hm = (app as any).hotkeyManager;
  if (!hm) return fallback;
  if (hm.customKeys && Object.prototype.hasOwnProperty.call(hm.customKeys, fullCommandId)) {
    return hm.customKeys[fullCommandId] ?? [];
  }
  return hm.getHotkeys?.(fullCommandId) ?? hm.getDefaultHotkeys?.(fullCommandId) ?? fallback;
}
```

Use `hm.printHotkeyForCommand(fullCommandId)` for footer labels when available.

## In-modal matching

On the modal input's `keydown`:

1. Resolve action via `effectiveHotkeys` for each command id.
2. Prefer **most modifiers** when several bindings share a key (Enter family).
3. `evt.preventDefault()` only when you handle the action.

## User workaround

Settings → Hotkeys → clear the conflicting plugin binding.

## Reference implementation

A full modal hotkey module (command specs, footer hints, `eventMatchesHotkey`) is a useful template — extract the pattern into your plugin; do not copy plugin-specific command ids.

## See also

- [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md) — hotkeys summary in pitfalls
- [obsidian-plugin-review](../obsidian-plugin-review/SKILL.md) — UX for discoverable shortcuts

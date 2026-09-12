---
name: obsidian-hotkeys
description: >-
  Obsidian plugin hotkey patterns — avoid hijacking editor keys with addCommand
  defaults, propose focus-scoped Scope bindings when appropriate, chorded
  bindings, in-modal keydown fallbacks, and hotkeyManager effective bindings.
  Use when registering modal/view commands, footer hint labels, or debugging
  keys stolen from the editor while typing.
---

# Obsidian plugin hotkeys

## Propose focus scope (agent duty)

When adding or changing hotkeys in a plugin, **consider whether they should be focus-scoped** and **propose that choice to the user** before wiring globals. Do not silently register view/modal-only actions as `addCommand` defaults.

| Prefer | When |
|--------|------|
| **Focus-scoped** (`View.scope` / `Modal.scope`) | Action only makes sense while a custom view, leaf, or modal is focused (navigate list, accept row, panel-local find, etc.) |
| **Global** (`addCommand` + Settings → Hotkeys) | Action should run from anywhere (open palette/modal, toggle feature, vault-wide command) |
| **Local `keydown` fallback** | Bare editor keys (`Enter`, arrows, `Tab`, `Escape`) needed inside a focused field — never as global defaults |

Ask briefly, e.g.: “These shortcuts only apply inside `<View/Modal>` — register them on that scope instead of global hotkeys?”

## The hijacking problem

Obsidian's keymap **claims registered command hotkeys globally**, even when `checkCallback` returns `false`. Bare `ArrowUp`, `ArrowDown`, `Enter`, `Tab`, or `Escape` in `addCommand({ hotkeys: … })` steal those keys from the editor — not only when your modal is active.

Focus-scoped bindings avoid that: they are active only while the view/modal scope is on the keymap stack.

## Pattern

| Layer | What to do |
|-------|------------|
| Decide scope | Propose focus-scoped vs global (table above). |
| `addCommand` defaults | **Chorded** bindings only (`Mod+Enter`, `Alt+Enter`, …). Omit bare editor keys. Use for vault-wide commands. |
| Custom `View` | `this.scope = new Scope(this.app.scope)` then `this.scope.register(…)` — active when the view is focused. |
| `Modal` / `SuggestModal` | Register on **`this.scope`** (already pushed on open). Do not replace with a new `pushScope` or you lose Escape/Enter/arrows. |
| In-modal / field handler | Bare keys as **local fallbacks** on the focused field (`keydown`) when Scope is not enough. Match user's effective binding from `hotkeyManager`. |
| Footer / hints | Show **live** binding (custom or fallback), not only `addCommand` defaults. |

Commands stay listed in Settings → Hotkeys for remapping when registered via `addCommand`. Scope-only bindings are **not** remappable there — say so when proposing focus scope.

## Focus-scoped registration

```typescript
// Custom view — since Obsidian 1.5.7
this.scope = new Scope(this.app.scope);
this.scope.register(['Mod'], 'f', (evt) => {
  // panel-local action; higher priority than globals while focused
  return false; // consume
});

// Modal — use the existing scope; Modal.open pushes it
this.scope.register(['Mod'], 'Enter', (evt) => {
  this.submit();
  return false;
});
```

`Scope.register(modifiers, key, func)` — return `false` to consume the event. Parent scopes still apply when you pass `this.app.scope` (or keep the modal’s built-in parent).

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
- [View.scope](https://docs.obsidian.md/Reference/TypeScript+API/View/scope) / [Scope](https://docs.obsidian.md/Reference/TypeScript+API/Scope) — official API

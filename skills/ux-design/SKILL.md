---
name: ux-design
description: >-
  UX principles for transparent, low-cognitive-load UI — status feedback,
  plain copy, tooltips for jargon, error/empty states, progressive disclosure.
  Use when designing or reviewing settings, modals, status UI, plugin UX, user-facing
  copy, tooltips, loading/empty/error states, or any new UI element.
---

# UX design (concise)

Apply these principles when adding or changing user-facing UI.

## 1. Be transparent (no silent machinery)

Application mechanisms should always have something to notify the user of what's happening; we want to avoid obfuscation.

- **Status bar** — ongoing work, connection state, indexing progress
- **Plugin settings** — expose hidden flags and modes users cannot discover elsewhere
- **Technical detail** — debug log modes, or hide detail in folded panels / optional trace toggles

## 2. Minimize cognitive load

Always consider cognitive burden/load on the user when creating new design UI elements. Simple and legible often wins over complexity and hard to understand.

- Prefer short descriptions, **one sentence max** when possible
- Limit choices per screen; chunk related controls
- Use progressive disclosure for advanced options

## 3. Explain jargon inline

When using technical jargon, always suggest embedding a UI tooltip to help understand.

- Pair unfamiliar terms with `setDesc`, helper text, or a tooltip
- Use the user's language, not internal implementation names

## 4. Cover every state

Loading, empty, error, and success each need distinct copy — not generic "Success!" or "Error".

- Say what happened and what to do next
- A labeled wait beats an unlabeled spinner

## 5. Errors and destructive actions

- Errors: what failed, why (if known), and how to recover or retry
- Confirm irreversible actions; disable or warn when prerequisites are missing

## 6. Recognition over recall

Keep labels, options, and current state visible. Match familiar platform patterns (Jakob's Law).

- Consider keyboard focus and contrast for new controls

## Quick review checklist

```
- [ ] New background work visible (status/settings/modal)
- [ ] Copy ≤1 sentence per control where possible
- [ ] Jargon has tooltip or setting description
- [ ] Loading/empty/error/success handled
- [ ] Destructive actions confirmed
- [ ] Matches platform patterns
```

## UI jank ship gate (interaction + motion)

Before PR-ready UI, verify during a **live walkthrough** or **`.mp4`** on the cloud VM when available ([obsidian-cloud-vm-demos](../obsidian-cloud-vm-demos/SKILL.md)). Complements BDD [obsidian-ui-verifier-demo](../obsidian-ui-verifier-demo/SKILL.md); does not replace it.

```
- [ ] Layout stable after load (no reflow jumps in settings/modals/chat)
- [ ] No flicker on status bar, lists, or streaming content
- [ ] Text and controls not clipped or overlapping
- [ ] Overlays open without position jump; not clipped by parents
- [ ] Focus behavior acceptable (no typing interruptions; modal traps work)
- [ ] Drag/resize/animations feel smooth for the feature
```

Capture checklist: [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md). Complex features need embedded video in the PR ([pr-product-demos](../../.cursor/rules/pr-product-demos.mdc)).

## Obsidian appendix

| Need | Pattern |
|------|---------|
| Ongoing state | `StatusBar` item |
| Config / flags | `PluginSettingTab` row + `setDesc` |
| Feedback | `Notice`, modal copy, command palette names |
| Debug detail | Settings toggle → console, or folded "Advanced" section |

## See also

- [ux-gap-audit](../ux-gap-audit/SKILL.md) — workflow gap report
- [obsidian-plugin-review](../obsidian-plugin-review/SKILL.md) — transparency gate, ship checklist
- [obsidian-settings-secrets](../obsidian-settings-secrets/SKILL.md) — credentials UX
- [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) — screenshot-verify UI changes

---
name: ux-gap-audit
description: >-
  Audits UX workflow gaps — collects user feedback, scans settings/status/modals/errors
  for transparency and cognitive-load issues, outputs a prioritized gap report against
  ux-design principles. Use when the user asks for a UX audit, workflow review, friction
  report, or gap analysis.
disable-model-invocation: true
---

# UX gap audit

Explicit audit workflow. Rubric: [ux-design](../ux-design/SKILL.md).

## When to run

User asks for a UX audit, workflow review, friction report, or gap analysis — or invokes `@ux-gap-audit`.

## Workflow

### 1. Gather feedback

Start with 1–2 `AskQuestion` rounds unless the user already described pain:

- Which workflows feel confusing or "silent"?
- Where did you expect status/feedback and not get it?
- Any jargon or settings you don't understand?

### 2. Scan the codebase

Search for:

- Background/async work without status bar, `Notice`, or settings exposure
- `PluginSettingTab` rows missing `setDesc`; hidden flags not in settings
- Modals/errors with generic copy ("Error", "Success")
- Technical labels without tooltips or descriptions
- Destructive actions without confirmation
- Missing empty, loading, or error states

**Large plugins:** launch one `explore` subagent (thoroughness: medium) with this checklist; return file paths + one-line finding each. Merge into the final report.

### 3. Optional sources

If the user points to them: GitHub issues, PR comments, support notes, or session notes mentioning friction.

### 4. Produce the gap report

Use the template below. Cap **recommended next steps** at 3.

## Report template

```markdown
# UX gap report — {plugin or scope}

## User-reported friction
- {workflow}: {what user expected vs what happened}

## Code findings (by severity)

### Critical — silent or misleading
- {path} — {gap} → {fix per ux-design}

### Suggestion — clarity / cognitive load
- ...

### Nice to have
- ...

## Checklist score (ux-design)

| Check | Pass | Fail | Notes |
|-------|------|------|-------|
| Background work visible | | | |
| Copy ≤1 sentence | | | |
| Jargon explained | | | |
| All states handled | | | |
| Destructive actions confirmed | | | |
| Platform patterns | | | |

## Recommended next steps (max 3)
1. ...
```

## Obsidian scan targets

| Surface | Look for |
|---------|----------|
| `PluginSettingTab` | Missing descriptions, undiscoverable toggles |
| `StatusBar` | Long-running work with no indicator |
| `Notice` / `Modal` | Vague or missing next-step copy |
| Commands | Names that don't match user mental model |
| Async / workers | Silent failure or success |

## See also

- [ux-design](../ux-design/SKILL.md) — principles and checklist
- [obsidian-plugin-review](../obsidian-plugin-review/SKILL.md) — ship gate, transparency gate
- [obsidian-settings-secrets](../obsidian-settings-secrets/SKILL.md) — credentials and empty-password UX
- [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) — verify high-impact UI gaps after audit

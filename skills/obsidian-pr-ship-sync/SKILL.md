---
name: obsidian-pr-ship-sync
description: >-
  Keep GitHub PR title, description, embedded demo media, draft/ready state,
  and acceptance review in sync with shipped code and the latest recording.
  Run after every demo and before marking Ready or asking for human verify.
---

# PR ship sync (GitHub ↔ code ↔ demo)

**Problem this solves:** Code and CI move forward while the PR still describes an **older UI** (wrong copy, wave clip after bars shipped, acceptance **PASS** tied to stale media). Reviewers and Adrian should never infer behavior from a mismatched PR body.

**Tooling:** **`ManagePullRequest`** only for routine updates (`update_pr`, `draft: false`). Do not use `gh pr edit` for cloud-agent PRs unless artifact upload is blocked.

**Related:** [pr-draft-ready](../../.cursor/rules/pr-draft-ready.mdc), [pr-product-demos](../../.cursor/rules/pr-product-demos.mdc), [obsidian-cloud-vm-demos](../obsidian-cloud-vm-demos/SKILL.md), [obsidian-pr-acceptance-review](../obsidian-pr-acceptance-review/SKILL.md).

---

## When to run (mandatory)

Run **`obsidian-pr-ship-sync`** (read this skill and execute the checklist) in the **same turn** as:

| Trigger | Why |
|---------|-----|
| Demo recording or screenshot set finished | Body must embed **this** capture, not a prior run |
| User-visible behavior changed on the branch | Description, AC, and media must match **current** UI |
| Re-record after feedback or bugfix | Old embeds and acceptance evidence are invalid |
| Before **`draft: false`** | Ready means “description = demo = diff” |
| Before **🟠 Requires user input** | Human verify reads the PR, not chat-only artifacts |
| Changelog `[Unreleased]` bullet changed | PR story should match changelog wording |

**Skip** only for docs-only PRs with no open behavioral story, or when the user explicitly keeps a draft WIP PR with no demo bar.

---

## Sync surfaces (keep aligned)

| Surface | Must match |
|---------|------------|
| **Branch diff** | What actually ships |
| **PR title** | User-facing summary (e.g. “level bars”, not “live wave”) |
| **PR Description** | Current behavior; no retired iterations in prose |
| **Embedded `<video>` / `<img>`** | Latest `/opt/cursor/artifacts/` paths; timestamp bullets for video |
| **`## Acceptance review`** | AC text + evidence filenames/times for **embedded** media; **Verdict: PASS** only if all `[x]` |
| **GitHub Draft / Ready** | Ready **only after** body sync in this turn |
| **CHANGELOG `[Unreleased]`** | Same feature name/behavior as PR (when user-facing) |
| **Project notes** (if used) | In progress vs 🟠 matches Ready + acceptance PASS |

---

## Procedure

### 1. Read ground truth

1. **`git log` / diff** on the PR branch — note the **current** user-visible behavior.
2. **`gh pr view`** (fork `--repo`) — title, body, `isDraft`.
3. **Latest artifacts** under `/opt/cursor/artifacts/` — filenames and what each frame shows.
4. **CHANGELOG** `[Unreleased]` for this feature.

### 2. Stale detection (fix before Ready)

Treat the PR as **stale** if **any** of:

- Description or AC use UI terms that the branch no longer implements (e.g. “wave” vs vertical bars).
- Embedded media from an **earlier agent run** or iteration while commit message says otherwise.
- Acceptance **PASS** references clip names or timestamps that are **not** in the current body embeds.
- Title contradicts description or changelog.
- Demo exists only in chat / agent dashboard, **not** embedded in the PR body (when [pr-product-demos](../../.cursor/rules/pr-product-demos.mdc) applies).

If stale → full **rewrite** of Description + demo section + acceptance block; do not flip Ready first.

### 3. `ManagePullRequest` → `update_pr` (body)

Provide the **full** PR body (tool preserves markers). Include:

```markdown
## Description

(Plain language for **current** behavior only.)

## Testing environment

…

## Demo

<video src="/opt/cursor/artifacts/your-demo.mp4"></video>

- 0:00–0:04 …
- 0:04–0:08 …

<img src="/opt/cursor/artifacts/state-idle.webp" alt="Idle mic" />
…
```

Rules:

- Use **absolute** artifact paths; short bullet list per clip (what reviewer should see).
- Remove or replace **all** superseded paragraphs and images — do not append a second story.
- If behavior changed: update **`title`** in the same or follow-up `update_pr`.

### 4. Acceptance review

- If demo or AC changed: delegate **`/pr-acceptance-review`** or update the `ACCEPTANCE_REVIEW_BEGIN` … `END` block so every **`[x]`** cites **new** evidence.
- **Never** leave **Verdict: PASS** while AC text still describes old UI.

See [obsidian-pr-acceptance-review](../obsidian-pr-acceptance-review/SKILL.md) for AC format.

### 5. `ManagePullRequest` → `update_pr` (`draft: false`)

Only after steps 3–4. Re-read the PR on GitHub mentally: would a reviewer who never opened chat understand the **current** feature from the body alone?

### 6. Project notes (optional)

- **In progress** until acceptance **PASS** and body synced.
- **🟠** only after Ready + PASS when asking Adrian to verify.

---

## Iteration / back to Draft

| Situation | Action |
|-----------|--------|
| Substantive fix after Ready | `update_pr` **`draft: true`**, fix code, re-demo, re-sync, Ready again |
| User asks to hold review | Stay Draft; do not mark 🟠 |
| Only CI/docs on branch | Still sync description if it mentions behavior |

---

## Anti-patterns

- Push commit → **`draft: false`** with no **`update_pr`** on body.
- Mark Ready while embeds still show pre-change UI.
- Copy acceptance block from a previous PR without re-checking media.
- Rely on `cursor.com/agents/…/artifacts` links as the **only** proof when a PR exists.

---

## Handoff line (parent / coordinator)

```text
PR ship sync: DONE | STALE-FIXED
PR: <url>
Media: <artifact filenames embedded>
Ready: yes/no
Acceptance: PASS | pending re-run
```

---

## See also

- [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md) — changelog bullets when user-facing
- [obsidian-ui-verifier-demo](../obsidian-ui-verifier-demo/SKILL.md) — BDD before acceptance when triggered

---
name: obsidian-pr-acceptance-review
description: >-
  Read-only PR + embedded media review before human verify: derive acceptance
  criteria from the PR story, check demo artifacts against them, and update the
  PR body with a pass/fail checklist. Run before moving work to Requires user
  input or asking Adrian to review.
---

# PR acceptance review

**Last gate before human verify.** After code, deploy, BDD (`/ui-verifier-demo` when required), and product demo are in place, a **readonly** reviewer subagent confirms the PR tells a coherent story and the embedded screenshots/videos **prove** the intended user behaviors. It **may edit the PR description only** — append or replace a standard **`## Acceptance review`** section with a checklist and evidence notes.

**Related:** [pr-draft-ready](../../.cursor/rules/pr-draft-ready.mdc), [pr-product-demos](../../.cursor/rules/pr-product-demos.mdc), [obsidian-cloud-vm-demos](../obsidian-cloud-vm-demos/SKILL.md), [obsidian-ui-verifier-demo](../obsidian-ui-verifier-demo/SKILL.md), [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md), [ux-design](../ux-design/SKILL.md). Project bar: user store `docs/ui-ship-quality.md`.

**Subagent:** `/pr-acceptance-review` (or Task → `pr-acceptance-review`) — delegate **foreground** before 🟠 **Requires user input**.

---

## When to run (mandatory)

Run **before**:

- Moving a PR or project note row to **🟠 Requires user input** (human verify / merge decision).
- Asking Adrian to watch a demo or approve a feature PR.

Run **after**:

- Implementing agent marked code complete, tests/build green, sandbox/cloud deploy verified.
- **`/ui-verifier-demo`** finished when [trigger-ui-verifier-demo](../../.cursor/rules/trigger-ui-verifier-demo.mdc) applies (PASS or accepted PARTIAL documented).
- Product demo embedded in PR when [pr-product-demos](../../.cursor/rules/pr-product-demos.mdc) applies.

**Skip** only for: docs/comments-only PRs, dependency bumps with zero behavior/UI delta, or explicit user `/no-test` (still add a minimal **Acceptance review** noting skip reason).

Same **“complex / user-facing”** heuristics as product demos and BDD verifier:

- New or changed user flow (commands, modals, settings, status, errors, permissions).
- **Large change:** ≥3 non-test files under `src/ui/`, `src/hooks/`, settings tab, or `styles.css`.
- User-facing `[Unreleased]` changelog bullet.

---

## Subagent constraints

| Allowed | Forbidden |
|---------|-----------|
| Read PR title, body, diff summary, linked artifacts | Push commits, change code, deploy |
| Open/download embedded PR images and videos | Edit agent-client PR #50 / #52 bodies unless explicitly assigned |
| **Update PR body** (description) via `ManagePullRequest` `update_pr` or equivalent | Merge, close, or change PR labels/status without user ask |
| Write internal report under project store `internal/` if detail is long | Modify vault `data.json`, secrets, or plugin settings in Obsidian |

The reviewer is ** skeptical of narrator claims**: pass an AC only when **visible or quoted CLI evidence** in the PR supports it.

---

## Procedure

### 1. Ingest intent

1. Read **PR title** and **full description** (feature goal, demo bullet list, verifier verdict if pasted).
2. Skim **diff summary** or changed paths — confirm scope matches the story (no surprise surfaces).
3. Note repo plugin id and any fork-specific verify hints (`AGENTS.md`, e.g. Agent Client floating tabs).

### 2. Derive acceptance criteria (AC)

Write **5–12** concrete AC items the product owner would recognize:

- **Expected user behaviors** — observable outcomes (UI label, command result, setting persistence, error message).
- **Explicit non-behaviors** — at least one AC per risky regression (“must not …”, “does not apply when …”).

Format each AC as one line, testable from demo or BDD report:

```text
AC-3: When the queue is active, the send control shows the list-plus icon (not the send arrow).
AC-7: Must not drop queued messages when switching preset agent before the new harness is ready.
```

Import scenarios from `ui-verifier-demo-report.md` when present; **do not** duplicate every BDD step — collapse to owner-level AC.

### 3. Review embedded media

For each image/video in the PR body (and supplementary paths cited in chat):

| Check | FAIL if |
|-------|---------|
| **In frame** | Claimed control (composer, chip strip, modal footer) cropped or unreadable |
| **Hold** | State flashes &lt; ~0.5s with no readable proof (prefer ≥2s per demo pacing rule) |
| **Match AC** | Demo shows something different from PR bullets or derived AC |
| **Jank** | Ship-blocking layout shift, flicker, or focus steal during the recorded flow |

Use **`videoReview`** subagent on `.mp4` when motion or subtle UI matters. For agent-client composer queue claims, optional cross-check against fork [ui-demo-verifier](https://github.com/adrianghnguyen/obsidian-agent-client/blob/main/.cursor/agents/ui-demo-verifier.md) visibility rules.

Record **evidence notes**: `video @ 0:42`, `screenshot Settings → Seek → Diagnostics`, `BDD report scenario S2 step 3`.

### 4. Verdict

| Outcome | Meaning |
|---------|---------|
| **PASS** | Every AC checked; media supports claims; verifier PASS (or PARTIAL with documented acceptance) |
| **FAIL** | Any AC unchecked or media contradicts story |
| **BLOCKED** | Missing demo when required, empty PR body, or artifacts not embedded |

On **FAIL** or **BLOCKED**: hand back to implementing agent — stay **🔄 In progress**; re-record demo or fix code. **Do not** move to 🟠.

### 5. Update PR body

Append or **replace** the section between markers (create if absent):

```markdown
<!-- ACCEPTANCE_REVIEW_BEGIN -->
## Acceptance review

**Reviewer:** pr-acceptance-review subagent  
**Verdict:** PASS | FAIL | BLOCKED  
**Reviewed:** YYYY-MM-DD (UTC)

### Acceptance criteria

- [x] **AC-1:** … — *Evidence: video 0:12–0:18, send icon visible*
- [ ] **AC-2:** … — *Gap: PR claims chip X cancel; no frame shows X click*
- [x] **AC-3:** … — *Evidence: ui-verifier-demo-report.md S1 Then*

### Non-behaviors verified

- [x] **N-1:** Must not … — *Evidence: …*

### Notes

- (Optional: PARTIAL BDD items accepted, env limits, retake recipe)
<!-- ACCEPTANCE_REVIEW_END -->
```

Use **`ManagePullRequest`** `update_pr` with the **full** PR body: preserve existing content outside the markers; only replace the block between `ACCEPTANCE_REVIEW_BEGIN` / `END`.

**PASS** requires every AC and N-item **`[x]`**. Any **`[ ]`** → verdict **FAIL** in the section header.

---

## Handoff to coordinator / parent

```text
PR acceptance review: <PASS|FAIL|BLOCKED>
PR: <url>
AC: <passed>/<total> passed
Action: <ready for 🟠 | return to implementer — list failed AC ids>
```

Coordinator: **never** move project notes or tell Adrian to verify until PR body contains **`## Acceptance review`** with **Verdict: PASS** and all boxes checked.

---

## Example template (docs only)

Do **not** paste into live PRs unless running this review. Illustrative AC for a “composer send queue” feature:

```markdown
<!-- ACCEPTANCE_REVIEW_BEGIN -->
## Acceptance review

**Reviewer:** pr-acceptance-review subagent  
**Verdict:** PASS  
**Reviewed:** 2026-09-26 (UTC)

### Acceptance criteria

- [x] **AC-1:** While a turn is in flight, primary send shows queue (list-plus) icon — *Evidence: demo.mp4 0:05*
- [x] **AC-2:** Queued messages appear as chips above composer border — *Evidence: demo.mp4 0:08–0:14*
- [x] **AC-3:** Cancel (X) removes one chip without flushing others — *Evidence: demo.mp4 0:20*

### Non-behaviors verified

- [x] **N-1:** Must not send queued text until session ready — *Evidence: demo.mp4 0:30 flush after idle*

### Notes

- BDD: PASS (report attached in PR comment)
<!-- ACCEPTANCE_REVIEW_END -->
```

---

## See also

- [trigger-ui-verifier-demo](../../.cursor/rules/trigger-ui-verifier-demo.mdc) — BDD before acceptance review
- User preferences — 🟠 gate and project notes layout (`/cursor/stores/user/preferences.md`)

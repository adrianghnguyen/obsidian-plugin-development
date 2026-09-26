---
name: obsidian-ui-verifier-demo
description: >-
  Behavior-driven functional verification of Obsidian plugin UI and flows — happy
  and unhappy paths, structured PASS/FAIL report with expected vs actual on
  failures. Use when finishing large user-facing changes, before PR review, or
  when delegating to the ui-verifier-demo subagent.
---

# UI verifier demo (BDD functional)

Independent **functional** proof after deploy + reload. Screenshots alone are not enough when behavior changed — exercise **happy paths** and **unhappy paths**, then emit a **BDD report** that states **PASS**, **FAIL**, or **PARTIAL** and explains every failure against the intended behavior.

**Related:** [obsidian-cloud-vm-demos](../obsidian-cloud-vm-demos/SKILL.md), [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md), [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md), [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md), [obsidian-plugin-debug](../obsidian-plugin-debug/SKILL.md), [obsidian-pr-acceptance-review](../obsidian-pr-acceptance-review/SKILL.md) (after BDD + demo, before 🟠).

**Subagent:** `/ui-verifier-demo` — parent agents should delegate here (foreground, not background) when this skill applies.

---

## When to run (mandatory)

Run **before marking the task complete** when **any** of:

| Signal | Examples |
|--------|----------|
| Large behavioral change | New flow, changed send/search/settings persistence, error handling, permissions |
| Multi-surface UI | Modal + settings + status bar; new commands or hotkeys |
| PR / product demo bar | Same triggers as [pr-product-demos](../../.cursor/rules/pr-product-demos.mdc) |
| Parent shipped feature work | User-facing `[Unreleased]` changelog bullet |

**Skip** only for: comments/docs-only, pure refactors with zero behavior delta (still run one smoke `eval`), or user `/no-test` / explicit skip.

**Large change heuristic:** ≥3 non-test files under `src/ui/`, `src/hooks/`, settings tab, or `styles.css` **or** any new user-visible state/label/error path.

---

## Prerequisites

1. `npm run typecheck` / `npm test` / `npm run build` passed on the machine running verify (VM when cloud).
2. Artifacts in vault plugin folder; `plugin:reload` (or cloud reload path).
3. **Identity gate** (serial CLI, `vault=<full-name>` first):

```javascript
JSON.stringify({ name: app.vault.getName(), base: app.vault.adapter.basePath })
```

4. Artifacts under a **git-ignored** dir (`.tmp/ui-verifier-demo/`, `/opt/cursor/artifacts/` on cloud).

---

## BDD scenario design

Before executing, write scenarios the **product owner would recognize** — not implementation steps.

Each scenario:

```markdown
**Story:** As a \<role\>, I want \<action\> so that \<outcome\>.
**Priority:** P0 (ship blocker) | P1 | P2
```

Steps use **Given / When / Then** (one row per step in the report):

| Phase | Meaning |
|-------|---------|
| **Given** | Vault state, settings, open view, secrets present/absent |
| **When** | User action (command, click, hotkey, invalid input) |
| **Then** | Observable outcome (UI label, Notice, eval JSON, disabled control) |

Include **at least**:

- **One happy path** — primary success flow end-to-end.
- **One unhappy path** — validation error, missing secret, cancel, empty input, or permission denied; must show **correct failure UX** (message, no crash, recoverable).

Plugin-specific playbooks (Seek telemetry, Agent Client ACP spawn, Whisper live) stay in fork repos — this skill defines **how** to verify; the subagent **imports** repo `AGENTS.md` / local skills for concrete steps.

---

## Execution

| Layer | Tool |
|-------|------|
| CLI behavior | Serial `obsidian vault=… eval`, plugin commands, log excerpts |
| GUI flows | `computerUse` subagent or manual steps + `dev:screenshot` / screen recording |
| DOM spot checks | `dev:dom` when labels/footer must match behavior |

**Do not** parallelize Obsidian CLI. **Do not** mark PASS on build/test alone.

On cloud VM, follow [obsidian-cloud-vm-demos](../obsidian-cloud-vm-demos/SKILL.md) for evidence in PR body when a PR exists. Complex or user-facing scope also requires an embedded **`.mp4`** walkthrough in the PR (see [pr-product-demos](../../.cursor/rules/pr-product-demos.mdc)) — BDD verification does not replace that demo.

---

## UI jank inspection (required during walkthrough)

While exercising scenarios (GUI layer), **watch the full interaction**, not only the final frame. Record or note jank during the same session used for BDD steps. On cloud VM, prefer a **screen recording** so reviewers can replay motion issues.

Mark each category **PASS** or **FAIL** in the report (add a **Visual / jank** section after scenarios):

| Check | FAIL examples |
|-------|----------------|
| Layout stability | Sudden reflow, jumping composer/modal height, settings tab rows shifting after load |
| Flicker | Flash of empty/wrong state, toolbar or status bar blinking, list virtualizer pop-in |
| Alignment | Misaligned icons/buttons, clipped or overlapping text, chip strip vs send control |
| Overlays | Modal/popover position jump on open, dropdown clipped by parent, focus ring off-control |
| Focus | Focus stolen from editor while typing, trap broken in modal, unexpected scroll jump |
| Motion | Janky resize/drag (floating chat), stutter during streaming updates |

- **P0 FAIL** — jank blocks the primary story (cannot complete flow, unreadable controls, data loss scare).
- **P1 FAIL** — noticeable but workaround exists; document in report if shipping with acceptance.
- Tie evidence to recording timestamp or screenshot path.

Full checklist copy also lives in [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) and [ux-design](../ux-design/SKILL.md).

---

## Report (required output)

Write **`ui-verifier-demo-report.md`** (and attach screenshots/video paths inline). Use [report-template.md](./report-template.md).

### Verdict rules

| Verdict | Condition |
|---------|-----------|
| **PASS** | All P0 scenarios PASS; no P1 FAIL |
| **PARTIAL** | All P0 PASS; at least one P1 FAIL or P2 FAIL |
| **FAIL** | Any P0 FAIL, or identity/deploy gate failed |

### Failure explanation (BDD)

For every **FAIL** step, fill:

1. **Expected behavior** — the **Then** clause (what the story promised).
2. **Observed behavior** — what actually happened (quote UI text, eval JSON, console line).
3. **BDD gap** — one sentence: how observation violates the story (e.g. "Then promised a clear error when API key missing, but UI showed silent disable with no Notice").
4. **Failure mode** — `regression` | `never-implemented` | `env-blocked` | `flaky` | `spec-ambiguous`.
5. **Evidence** — artifact paths or CLI output block (truncate secrets).
6. **Suggested fix** — smallest next change (optional but recommended for FAIL).

Parent agent must **surface the verdict** in chat and **not claim complete** on FAIL unless user accepts risk.

---

## Handoff to parent

Return to parent:

```text
UI verifier demo: <PASS|PARTIAL|FAIL>
Report: <path to ui-verifier-demo-report.md>
P0 failed: <count> — <titles>
Artifacts: <list>
```

If FAIL, include the **BDD gap** sentence for each P0 failure in the handoff message.

---

## See also

- [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) — capture surfaces referenced in report
- [obsidian-pr-acceptance-review](../obsidian-pr-acceptance-review/SKILL.md) — PR checklist gate before human verify
- [walkthrough-artifacts](https://cursor.com/docs/cloud-agent/capabilities#artifacts-in-github) — PR embed policy

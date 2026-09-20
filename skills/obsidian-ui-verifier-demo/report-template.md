# UI verifier demo report

| Field | Value |
|-------|--------|
| **Plugin id** | `<plugin-id>` |
| **Repo / branch** | `<repo>` @ `<branch>` |
| **Commit** | `<sha>` |
| **Build proof** | `main.js` size `<n>` / grep `<symbol>` |
| **Vault (identity gate)** | name=`<name>` base=`<path>` |
| **Date (UTC)** | `<ISO>` |
| **Verifier** | ui-verifier-demo subagent |

## Verdict

**`<PASS | PARTIAL | FAIL>`**

One-line summary: `<why this verdict>`

---

## Scenarios

### Scenario 1: `<short title>`

**Story:** As a `<role>`, I want `<action>` so that `<outcome>`.

**Priority:** P0

| # | Given | When | Then | Result |
|---|--------|------|------|--------|
| 1 | | | | PASS / FAIL / SKIP |
| 2 | | | | |

#### Failure detail (repeat per FAIL step)

- **Step #:** `<n>`
- **Expected behavior (Then):** `<what should happen>`
- **Observed behavior:** `<what happened>`
- **BDD gap:** `<how observation violates the story>`
- **Failure mode:** regression | never-implemented | env-blocked | flaky | spec-ambiguous
- **Evidence:** `<screenshot / video / eval output path>`
- **Suggested fix:** `<optional>`

---

### Scenario 2: `<unhappy path title>`

**Story:** As a `<role>`, I want `<invalid or edge case>` so that `<safe failure UX>`.

**Priority:** P0

| # | Given | When | Then | Result |
|---|--------|------|------|--------|
| 1 | | | | |

#### Failure detail

*(same block as above)*

---

## Evidence index

| Artifact | Path | Used in scenario |
|----------|------|------------------|
| Screenshot | `.tmp/...` | Scenario 1 step 2 |
| Recording | `/opt/cursor/artifacts/...mp4` | Scenario 1 happy path |

---

## Summary

| | Count |
|---|------|
| Scenarios | |
| Steps PASS | |
| Steps FAIL | |
| Steps SKIP | |
| P0 FAIL | |

## Notes

- Env limits, secrets missing, or skipped steps with reason.
- Follow-ups for parent agent (do not implement unless asked).

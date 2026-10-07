---
name: obsidian-agent-ui-demo
description: >-
  Token-efficient UI demo execution for Cloud Agents (computerUse + RecordScreen).
  Use when recording review-ready .mp4 walkthroughs — plan once, preflight off-camera,
  one short clip, ≥2s holds on proof frames. Complements obsidian-cloud-vm-demos and
  pr-product-demos; pairs with demo verification contracts in the project store.
---

# Agent UI demo playbook

**Audience:** implementing or demo subagents driving **computerUse** / **RecordScreen**.

**Goal:** One short clip a human reviewer can score without re-watching — **minimal agent turns**, **minimal on-camera time**.

**Related:** [obsidian-cloud-vm-demos](../obsidian-cloud-vm-demos/SKILL.md) (VM gates, embeds), [obsidian-ui-visibility](../obsidian-ui-visibility/SKILL.md) (preflight), [pr-product-demos](../../.cursor/rules/pr-product-demos.mdc). Project store: `docs/demo-verification-contract.md`, `docs/agent-ui-demo-playbook.md`.

---

## Token-efficient workflow (phases)

Do **not** interleave long exploration with recording. Fixed order:

| Phase | On camera? | Agent cost |
|-------|------------|------------|
| **A. Script** | No | One planning pass: ≤6 steps, each with one `must_show` |
| **B. Preflight** | No | Deploy, identity gate, visibility — shell/CLI first |
| **C. Stage** | Brief | Frame UI once; close Settings/modals; start **RecordScreen** |
| **D. Proof beats** | Yes | Only contract steps; fast moves, **2s hold** on evidence |
| **E. Stop + ship** | No | Save MP4; 3–5 PR bullets; [obsidian-pr-ship-sync](../obsidian-pr-ship-sync/SKILL.md) |

**Re-record:** only at ship gate when contract Overall is FAIL (project `docs/demo-verification-contract.md`). Do not loop takes during exploration.

---

## A. Script (off camera)

Write or paste a **demo contract** before touching the mouse:

- **One sentence goal** — what the reviewer must believe after the clip.
- **Setup line** — vault, surface (e.g. tabbed floating chat), Settings **closed**.
- **Steps** — each step: `action` (one verb), `must_show` (visible proof), `hold_seconds: 2` (use **3** for ship-critical states).
- **Out of scope** — explicit; do not fail the clip for these.

Prefer **CLI/eval** in setup notes (enable setting, open view) over menu drilling on camera.

**Agent Client:** multi-session / context features → tabbed floating chat, **switch tabs on camera**, show **outcome** (e.g. `@Note` on message), not icon state alone (repo `AGENTS.md` → Cloud Agent UI demos).

---

## B. Preflight (off camera)

1. Build + deploy + `plugin:reload` — [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md), serial CLI — [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md).
2. [obsidian-ui-visibility](../obsidian-ui-visibility/SKILL.md) — target mounted, uncovered, in frame, readable.
3. Optional jank spot-check — [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md), [ux-design](../ux-design/SKILL.md).

If preflight fails, **fix before** phase C. Do not “record and hope.”

---

## C. Stage (camera on, not yet proving)

1. **RecordScreen START** only when the relevant surface is already open and framed.
2. **Frame rule:** entire interactive surface in view (composer + toolbar, modal + footer, etc.).
3. **Unique labels** in UI when possible (distinct chip text) so reviewers can read state on a small video.
4. No idle desktop, no Settings tour, no hunt-through-menus at the start.

---

## D. Proof beats (camera — keep short)

**Motion:** purposeful clicks/types; no double-clicks, no cursor wandering.

**Pacing:** quick transitions between steps; **after each visible change**, hold still **≥2 seconds** on the **evidence frame** (chip, banner, new label, tab content difference).

| Do on camera | Avoid on camera |
|--------------|-----------------|
| Happy path end-to-end | Every related screen |
| One context switch if the story needs it (tab/session) | Repeated toggles of the same control |
| One short unhappy beat **only if** contract requires it | Long typing, generic lorem |
| Pause on **outcome** | Pause on loading spinners unless proving loading UX |

**Stop** immediately after the last hold — not minutes of idle.

**computerUse prompt shape (one delegation):** pass the **full contract** or path; list steps as numbered `action` + `must_show` + `hold 2s`; say “do not open Settings unless step N requires it.”

---

## E. Stop + ship (off camera)

1. **RecordScreen SAVE** → `/opt/cursor/artifacts/` (or git-ignored `.tmp/`).
2. Under the embed, **3–5 bullets**: “What to look for” mapped to contract steps.
3. PR: embed with `<video src="/opt/cursor/artifacts/…">` — [obsidian-cloud-vm-demos](../obsidian-cloud-vm-demos/SKILL.md).
4. Large behavioral scope: **`/ui-verifier-demo`** still required — this playbook does not replace BDD.

---

## Review-ready checklist (agent)

- [ ] Contract written before record
- [ ] Preflight visibility PASS
- [ ] Clip ≤ one feature story; proof holds ≥2s
- [ ] Reviewer can score from UI state without narration
- [ ] PR bullets + embedded MP4 (when PR exists)

---

## Common fails

- Feature cropped or covered by another window
- No hold after transition (reviewer cannot tell success vs flicker)
- Demo shows chrome only, not **outcome**
- Multi-session story with only one tab on camera
- Long exploratory recording burned into one MP4 (split: preflight off camera)

---
name: obsidian-agent-ui-demo
description: >-
  Token-efficient UI demo execution for Cloud Agents (computerUse + RecordScreen).
  Use when recording review-ready .mp4 walkthroughs — plan once, preflight off-camera,
  one short clip, brief pauses on key UX proof moments. Human handoff: embed on PR,
  What to look for bullets, stay Draft until the maintainer marks Ready.
---

# Agent UI demo playbook

**Audience:** implementing agents or the dedicated **`ui-demo-agent`** subagent driving **computerUse** / **RecordScreen**.

**Subagent:** `/ui-demo-agent` (Task → `ui-demo-agent`) — **model: `composer-2.5-fast`** (required; stub: [agents/ui-demo-agent.md](../../agents/ui-demo-agent.md)). Coordinators and implementing workers keep their default model unless docs say otherwise.

**Goal:** One short clip a human reviewer can score without re-watching — **minimal agent turns**, **minimal on-camera time**. No mandatory BDD verifier loop; Adrian reviews the embedded demo.

**Related:** [obsidian-cloud-vm-demos](../obsidian-cloud-vm-demos/SKILL.md) (VM gates, PR embeds), [obsidian-ui-visibility](../obsidian-ui-visibility/SKILL.md) (preflight), [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) (jank checklist), [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md) (serial CLI, vault identity), [pr-product-demos](../../.cursor/rules/pr-product-demos.mdc), [obsidian-pr-ship-sync](../obsidian-pr-ship-sync/SKILL.md). Project store: `docs/demo-verification-contract.md`, `docs/agent-ui-demo-playbook.md`.

---

## Token-efficient workflow (phases)

Do **not** interleave long exploration with recording. Fixed order:

| Phase | On camera? | Agent cost |
|-------|------------|------------|
| **A. Script** | No | One planning pass: ≤6 steps, each with one `must_show` |
| **B. Preflight** | No | **Parent only:** deploy, identity gate, open surface, seed state — not `ui-demo-agent` |
| **C. Stage** | Brief | Frame UI once; close Settings/modals; start **RecordScreen** |
| **D. Proof beats** | Yes | Fast between steps; **pause on evidence** at each key UX moment |
| **E. Stop + ship** | No | Save MP4; **What to look for** bullets; [obsidian-pr-ship-sync](../obsidian-pr-ship-sync/SKILL.md); **keep PR Draft** |

**Re-record:** only when the clip clearly fails the contract (wrong surface, covered control, no readable proof). Do not loop takes during exploration.

---

## How to make a good demo

### One path, one story

- Pick **one happy path** that proves the feature end-to-end. Add **one short unhappy beat** only when the PR story depends on it (validation error, empty state, permission denied) — show **correct failure UX**, not a crash.
- **Stage the frame** before recording: target surface centered, Settings and unrelated modals **closed**, entire interactive region in view (composer + toolbar, modal + footer, etc.).
- **Unique labels** in the UI when possible (distinct chip text, note titles) so reviewers can read state on a small video.

### Pacing (no fixed second counts)

There is **no** rigid 1s/2s rule and **no** “count one-thousand-two-thousand” timing.

- Move **quickly between steps** — no cursor wandering, menu tours, or idle desktop on camera.
- At each **key UX moment**, **pause briefly** on the **evidence frame** after the UI settles: hold still until a reviewer could **read** the proof (glyph visible, menu item legible, tab switch shows the right transcript, reload restored the expected state, error banner text readable, chip on the message, etc.).
- Do **not** skip through proof — montage edits that flash states are as bad as rambling clips.
- **Stop** right after the last proof moment — not minutes of idle.

Examples of moments that deserve a pause: opening a menu before clicking an item; switching floating-chat tabs to show different `@Note` attachments; showing send vs queue icon; permission banner with buttons; settings toggle reflected in the UI.

### What to show (vs what to skip)

| Show on camera | Keep off camera |
|----------------|-----------------|
| Outcome the PR claims (chip on message, new label, error banner) | Build logs, long CLI output |
| Tab/session switch when the story needs per-session state | Repeated toggles of the same control |
| CLI/eval in setup notes only unless the feature *is* CLI-visible | Settings tours unless verifying Settings |

**Agent Client:** multi-session / context features → tabbed floating chat, **switch tabs on camera**, show **outcome** (e.g. `@Note` on message), not icon state alone (fork `AGENTS.md` → Cloud Agent UI demos).

### Gates before RecordScreen

1. **Build + deploy + reload** — [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md); copy only `main.js`, `manifest.json`, `styles.css`.
2. **Vault identity** — per global rule `obsidian-vault-target-verify`; **serial** `obsidian` invocations — [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md) (`vault=` first).
3. **Visibility** — [obsidian-ui-visibility](../obsidian-ui-visibility/SKILL.md): mounted, on screen, uncovered, readable.
4. **Jank spot-check** during the walkthrough — [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md), [ux-design](../ux-design/SKILL.md); fail before ship if layout shift, flicker, or focus steal is ship-blocking.

If preflight fails, **fix before** phase C. Do not “record and hope.”

### Common fails

- Feature cropped or covered by Settings / another window
- Blitzing through proof (reviewer cannot tell success vs flicker)
- Demo shows chrome only, not **outcome**
- Multi-session story with only one tab on camera
- Long exploratory recording burned into one MP4 (split: preflight off camera)
- Wrong vault (identity gate skipped) — reload/eval hit the focused window, not sandbox
- Menu exploration (File, Settings, vault sidebar) instead of the contract path

---

## Parent kickoff

The coordinator follows this when writing the `ui-demo-agent` task. One kickoff, one path.

- **One path only.**
- Name the shell command (`obsidian restart` or `plugin:reload`). When restore/reload is the proof, also name the code entry (example: `restorePinnedSessions` on `onload`).
- Put that command in the kickoff. Do not say “follow the skills” instead of the command.
- Do not offer a GUI alternate (File → Exit) beside the shell command.
- Do not spawn a second agent with the same script.
- Do not ask the demo agent to fix code before that one cheap proof has run.

---

## If lost, stop

Demo agents must **not** rediscover Obsidian. The parent stages the app; the demo agent runs a **fixed path** only.

### 1. Parent preflight only

The **parent** (coordinator or implementing agent) — **not** `ui-demo-agent` — must finish before delegation:

- Deploy artifacts + `plugin:reload` (or `obsidian restart` when the story requires it)
- Vault identity gate (`name` + `basePath`)
- Open the **exact** surface (floating chat, modal, status bar, etc.)
- Seed state via **`obsidian eval`** or known palette commands

Do not delegate `ui-demo-agent` to “set up Obsidian.”

### 2. Kickoff navigation card (required in the Task prompt)

Paste this block for every delegation:

```text
Vault: <CLI vault name>
Surface: <already open — e.g. tabbed floating chat, tab "Session A">
Shell: <one command — obsidian vault=<name> plugin:reload id=<plugin-id> OR obsidian restart>
Code entry: <when restore/reload is the proof — e.g. restorePinnedSessions on onload>
First control: <exact label or aria text to click>
Contract: <path or inline steps>
```

No “figure out Obsidian.” The demo agent assumes the surface is **already** on screen.

### 3. Stop rule

If the **named control** is missing, off screen, or covered after **one** eval or [obsidian-ui-visibility](../obsidian-ui-visibility/SKILL.md) check:

- **Stop** — status `BLOCKED`
- Report what failed (vault, surface, control)
- Do **not** open **Settings**, the **vault file sidebar**, **File** menu, or hunt through plugin chrome

Return to the parent to fix preflight or update the navigation card.

### 4. No nested explorer

While a demo contract is in flight, do **not** spawn subagents to explore the UI, tour menus, or “find” controls. One path, one clip.

---

## A. Script (off camera)

Write or paste a **demo contract** before touching the mouse:

- **One sentence goal** — what the reviewer must believe after the clip.
- **Setup line** — vault, surface (e.g. tabbed floating chat), Settings **closed**.
- **Steps** — each step: `action` (one verb), `must_show` (visible proof), `pause_on` (what the reviewer must be able to read on that frame).
- **Out of scope** — explicit; do not fail the clip for these.

Prefer **CLI/eval** in setup notes (enable setting, open view) over menu drilling on camera.

---

## B. Preflight (off camera)

Follow **Gates before RecordScreen** above.

---

## C. Stage (camera on, not yet proving)

1. **RecordScreen START** only when the relevant surface is already open and framed.
2. No idle desktop, no Settings tour, no hunt-through-menus at the start.

---

## D. Proof beats (camera — keep short)

**Motion:** purposeful clicks/types; no double-clicks.

**Pacing:** fast between steps; at each step, **pause on `must_show`** until readable — see **Pacing** under *How to make a good demo*.

**Delegation:** Prefer Task → **`ui-demo-agent`** with **`model: composer-2.5-fast`** and the full demo contract in the prompt. When the parent runs **computerUse** inline, use the same contract shape: numbered `action` + `must_show` + `pause until readable`; say “do not open Settings unless step N requires it.”

---

## E. Stop + human handoff (off camera)

1. **RecordScreen SAVE** → `/opt/cursor/artifacts/` (or git-ignored `.tmp/`).
2. **`ManagePullRequest` `update_pr`** — embed the clip:

```markdown
## Demo

<video src="/opt/cursor/artifacts/your-demo.mp4"></video>

### What to look for

- … (3–5 bullets: each maps to a contract step / visible proof)
- …
```

3. Run [obsidian-pr-ship-sync](../obsidian-pr-ship-sync/SKILL.md) so **title**, **description**, and **embeds** match **this** branch and **this** recording.
4. **Leave the PR Draft** unless the user explicitly asked to mark Ready. Tell Adrian the PR is ready for **human** review (demo embedded, bullets under the video).
5. Optional: delegate **`/pr-acceptance-review`** if you want a structured AC block before Adrian watches — **not required** for handoff.

---

## Review-ready checklist (agent)

- [ ] Contract written before record
- [ ] Preflight visibility PASS; vault identity confirmed
- [ ] Clip ≤ one feature story; each proof moment **readable** on camera (not skipped)
- [ ] Reviewer can score from UI state without narration
- [ ] PR has embedded MP4 + **What to look for** (3–5 bullets)
- [ ] PR ship sync done; PR stays **Draft** until maintainer marks Ready

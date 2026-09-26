---
name: obsidian-cloud-vm-demos
description: >-
  Strict end-to-end verification on Cursor Cloud VMs when environment.json or a
  Cloud Agent session is available. Use when finishing Obsidian plugin features,
  fixes, or refactors in cloud — mandatory VM runtime proof; complex or
  user-facing work needs embedded .mp4 walkthroughs plus jank inspection; do not
  treat local-only build/test as done in a cloud session.
---

# Cloud VM demos (strict)

When **Cursor Cloud** is available, plugin work is **not complete** until the change is **demonstrated on the cloud VM** with **evidence in chat**. In a **cloud session**, local Windows sandbox runs do **not** replace VM proof.

**Related:** [obsidian-plugin-dev](../obsidian-plugin-dev/SKILL.md) (build/deploy), [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md) (serial CLI, `vault=` first), [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) (screenshots), [obsidian-plugin-sandbox](../obsidian-plugin-sandbox/SKILL.md) (staging vault on metal).

---

## Cloud is available when

Any of:

- Workspace `.cursor/environment.json` defines `install` and `start` (and optional `repositoryDependencies`).
- Shell cwd or paths indicate the cloud agent host (e.g. `/agent/`, `/agent/repos/`).
- User opened a **Cloud Agent** for this task.

If none apply, follow the plugin repo’s local `.cursor/rules/deploy-and-verify.mdc` (or equivalent) on the machine you are on.

---

## Required evidence (strict)

| Change type | Required on cloud VM |
|-------------|----------------------|
| UI, CSS, layout, modal, status bar, settings | **Screenshots** of every affected surface — [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) or repo-specific capture script. Show images in chat. |
| Behavior, CLI, index, search, settings runtime | **Command + full relevant output** (`eval` JSON, log excerpt). Summaries alone are not enough. |
| Both visible and behavioral | **Both** screenshot set and CLI/runtime output. |
| **Complex feature** or **user-facing flow** (same bar as [pr-product-demos](../../.cursor/rules/pr-product-demos.mdc) / [trigger-ui-verifier-demo](../../.cursor/rules/trigger-ui-verifier-demo.mdc)) | **Screen recording (`.mp4`)** end-to-end on the VM, embedded in the PR when one exists. Include numbered steps in chat or PR. **Screenshots-only is not sufficient** for review-ready PRs here. |
| Large behavioral change | **`/ui-verifier-demo`** BDD report ([obsidian-ui-verifier-demo](../obsidian-ui-verifier-demo/SKILL.md)) — happy + unhappy paths; FAIL must cite BDD gap. |
| Before human verify (🟠) | **`/pr-acceptance-review`** — PR **`## Acceptance review`** checklist ([obsidian-pr-acceptance-review](../obsidian-pr-acceptance-review/SKILL.md)). |

**Complex / user-facing** triggers (any one): new or changed user flow; ≥3 non-test files under `src/ui/`, `src/hooks/`, settings tab, or `styles.css`; user-visible changelog bullet.

Before recording or attaching media, run [obsidian-ui-visibility](../obsidian-ui-visibility/SKILL.md). Do not ship a clip where Settings or a modal covers the feature.

During every **`.mp4` walkthrough** (and while capturing screenshots for animated UI), run the **UI jank checklist** in [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) and [ux-design](../ux-design/SKILL.md). Treat ship-blocking jank as incomplete work.

**Before claiming complete**, confirm:

1. Env bootstrap on VM (`environment.json` `install` / `start`, or repo `scripts/cloud-e2e/` / `GETTING-STARTED.md` when present).
2. `npm run typecheck` / `npm test` / `npm run build` passed **on the VM** when applicable.
3. Artifacts copied into the **VM vault** plugin folder and `plugin:reload` (or documented cloud reload path).
4. **Identity gate** — vault name + basePath match the cloud staging vault (not the developer’s `C:\` paths):

```javascript
JSON.stringify({ name: app.vault.getName(), base: app.vault.adapter.basePath })
```

5. Evidence attached per table above.
6. **PR embeds:** when the change has an open PR, screenshots/video/logs must appear as **embedded media in the PR description** (inline images/players), not only on the agent run page or in chat.

`npm test` and `npm run build` are **gates only** — they never satisfy this skill alone when cloud is available.

---

## PR description embeds (Artifacts in GitHub)

Follow Cursor [Cloud Agent capabilities — Demos and Artifacts](https://cursor.com/docs/cloud-agent/capabilities#artifacts-in-github):

| Step | Action |
|------|--------|
| Dashboard | Enable **Allow posting artifacts to GitHub** ([Cloud Agents → My pull requests](https://cursor.com/dashboard/cloud-agents)). |
| Cloud Agent PR | **`ManagePullRequest` `update_pr`** — rewrite description + embed `/opt/cursor/artifacts/` paths in `<video>` / `<img>` tags; confirm embedded URLs on the PR after upload (`artifact_created` on the run dashboard). |
| Ready for review | Same turn: **`update_pr`** with **`draft: false`** only after the body matches the demo ([pr-draft-ready](../../.cursor/rules/pr-draft-ready.mdc)). |
| Manual PR from VM | Fallback: `gh pr edit <n> --body-file BODY.md --attach ./path.png --attach ./demo.mp4` ([attaching files](https://docs.github.com/en/github-cli/github-cli/attaching-files-with-github-cli)). |
| Blocked | Tell the user posting is off or failed; enable setting or use `gh pr edit`/`gh pr comment --attach` — do not mark UI/flow work complete with agent-link-only proof. |

Chat and local `.tmp/` paths are supplementary; reviewers should validate from the **PR body** without a local checkout.

**Related:** [obsidian-cloud-e2e](../obsidian-cloud-e2e/SKILL.md) (VM boot and capture context).

---

## Obsidian on the cloud VM

- **Serial CLI only** — one `obsidian` invocation at a time; see [obsidian-multi-vault-cli](../obsidian-multi-vault-cli/SKILL.md).
- **`vault=<name>` first** — full vault folder name; never shorthand that substring-matches another vault.
- **Reload after deploy** — copy only `main.js`, `manifest.json`, `styles.css`; preserve `data.json`.
- **UI proof** — use [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) with VM vault name and paths from cloud `paths.env` / project docs. Capture each touched surface (`Main`, `StatusBar`, `Settings`, plugin modal).
- **Artifacts** — write screenshots and dumps under a **git-ignored** dir (`.tmp/`, plugin `.seek-artifacts/`, or OS temp). Never commit demo PNGs.
- **Demo pacing** — in screen recordings, hold each distinct UI/behavior state for **≥2 seconds** after transitions finish before advancing to the next step (click, hotkey, or navigation). Avoid rapid montages that hide what changed.

If screenshot capture fails, fix and **retry once**; then report CLI error output — do not mark UI work complete.

---

## When demo can be skipped (narrow)

Only when:

- User explicitly asked for **local-only** or **no demo**;
- Pure comment/typo with **zero** behavior or UI impact; or
- Cloud env **failed to start** or demo is **impossible** (missing secrets) — state which and what was verified instead.

Refactors, performance, and “internal only” changes still need a **cloud smoke demo** (one `eval` or screenshot) when cloud is available.

---

## Local agent + cloud config in repo

If `.cursor/environment.json` exists but you are on a **local** agent:

1. Complete local staging verify per repo rules.
2. Tell the user **cloud demo was not run here**.
3. List exact commands/surfaces a Cloud Agent should run to close the loop (copy from this skill’s checklist).

---

## Do not

- Mark complete without VM evidence when cloud is available and the env starts.
- Leave demo media only on `cursor.com/agents` when a PR exists — **embed in the PR description**.
- Assume cloud vault paths match `references/machine-profile.md` on Windows — read cloud `paths.env` / project AGENTS cloud section.
- Substitute unit tests for UI screenshots or CLI output for layout proof.

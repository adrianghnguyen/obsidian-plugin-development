---
name: obsidian-ui-visibility
description: >-
  Visibility checks before Obsidian plugin screenshots or screen recordings.
  Prove the target control is mounted, on screen, uncovered by Settings or a
  modal, and large enough to see. Use before RecordScreen, dev:screenshot of a
  feature, cloud VM product demos, or when a DOM probe says the control exists
  but the user cannot see it.
---

# UI visibility checks

A control that exists in the DOM can still be invisible in the demo. Computed style, `:hover`, and a video-review model are not proof that a person can see the feature.

Run this gate **before** `RecordScreen` or attaching a demo to a PR. Fail the demo and do not record until every check passes.

**Related:** [obsidian-visual-verify](../obsidian-visual-verify/SKILL.md) (which surface to capture), [obsidian-cloud-vm-demos](../obsidian-cloud-vm-demos/SKILL.md) (PR embed), [obsidian-ui-verifier-demo](../obsidian-ui-verifier-demo/SKILL.md) (behavior after this gate), [obsidian-menu-settings](../obsidian-menu-settings/SKILL.md) (Settings is its own surface).

## When to run

Any screenshot or recording whose subject is a plugin control: button, icon, status, modal, composer, banner. Skip only for docs or a change with no pixels.

## Checks

All of these must pass. Record the JSON from the probe below with the still frame.

| # | Check | Fail when |
|---|--------|-----------|
| 1 | **Settings closed** | `.mod-settings` is open, unless the subject is that Settings tab |
| 2 | **No covering modal** | `.modal-bg` or a trust / popout dialog is up |
| 3 | **Control is mounted** | The selector matches nothing. A feature flag left off is this failure. Turn the flag on for the demo, then restore it |
| 4 | **Inside the viewport** | `getBoundingClientRect()` is outside `innerWidth` / `innerHeight` |
| 5 | **Topmost at its center** | `elementFromPoint` is not the control or a descendant. Settings, a modal, or another leaf is on top |
| 6 | **Large enough** | The shorter side is under 24px. Move or enlarge the Obsidian window so the control is readable. A 16px glyph in the corner of a 1920×1200 desktop recording fails |
| 7 | **Front window** | The desktop frame shows the Obsidian window in front, and the control is inside that window, not under another app |
| 8 | **Real pointer for hover** | Hover or click demos move the OS cursor onto the control and hold there for at least 2 seconds. CDP `Input.dispatchMouseEvent` can set `:hover` while the cursor in the video stays elsewhere. Do not claim a hover from computed opacity alone |

After the clip, watch it (or a zoomed crop of the control). If the feature is covered, tiny, or absent, the demo **fails** even when the probe JSON said `pass: true`.

## Probe

Serial CLI only. Replace `SELECTOR` with a CSS selector for the control (one element).

```javascript
(() => {
  const sel = "SELECTOR";
  const el = document.querySelector(sel);
  const settings = document.querySelector(".mod-settings");
  const modal = document.querySelector(".modal-bg, .modal");
  const reasons = [];
  if (settings) reasons.push("settings-open");
  if (modal) reasons.push("modal-open");
  if (!el) {
    reasons.push("control-missing");
    return JSON.stringify({ pass: false, reasons, sel });
  }
  const r = el.getBoundingClientRect();
  const cx = r.left + r.width / 2;
  const cy = r.top + r.height / 2;
  const top = document.elementFromPoint(cx, cy);
  const hit = top === el || (top && el.contains(top));
  if (r.width < 24 || r.height < 24) reasons.push("too-small");
  if (r.bottom <= 0 || r.right <= 0 || r.top >= innerHeight || r.left >= innerWidth) {
    reasons.push("off-screen");
  }
  if (!hit) reasons.push("occluded");
  return JSON.stringify({
    pass: reasons.length === 0,
    reasons,
    sel,
    box: { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height) },
    top: top ? String(top.className).slice(0, 80) : null,
  });
})()
```

`pass: true` is necessary and not sufficient. Take one still of the **desktop** (the same frame a recording would capture) and confirm the control is visible there. `dev:screenshot` of the app can hide a Settings window that sits on top of Obsidian.

## Recording

1. Close Settings (`app.setting.close()` when that API exists) and dismiss modals. Do not open Settings to "check something" and leave it up.
2. Run the probe. On any reason, fix the layout and probe again.
3. Put the control in the middle of the Obsidian window. Keep the whole control in frame for the whole clip.
4. Hold each state for at least 2 seconds (idle, active, hover, after click).
5. For hover, move the OS pointer onto the control. Confirm `:hover` **and** that the pointer is visibly on the control in the still.
6. Save a zoomed crop of the control next to the video so a 32px icon is reviewable.
7. Restore any setting you flipped for the demo (feature flag, debug mode). Reload if you stubbed runtime methods.

## What does not count

- Unit tests or a production build.
- `classList` / `getComputedStyle` while Settings or `.modal-bg` covers the app.
- A vision-model description of a full-desktop frame. Crop the control and look at that crop.
- A recording where the only readable UI is plugin Settings.

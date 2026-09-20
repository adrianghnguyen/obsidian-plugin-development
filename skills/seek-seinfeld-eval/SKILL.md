---
name: seek-seinfeld-eval
description: >-
  AI21 Seinfeld (custom) trivia corpus in the Cloud sandbox vault — how episode
  transcripts and Q&A notes relate, and how to run Seek retrieval checks against
  gold episodes. Use for Cloud E2E search validation, not production vaults.
---

# Seek — Seinfeld (custom) trivia Q&A

AI21 in-house trivia over TV episode transcripts. The **corpus and trivia live
in the demo repo**, not a standalone dataset project:

[AI21Labs/multi-window-chunk-size](https://github.com/AI21Labs/multi-window-chunk-size)
→ `seinfeld_trivia/` (`documents_content/` + `data.json`).

Always use **`vault=plugin-sandbox-Obsidian`**. Never run this against the
Windows production vault.

## Vault layout (after `materialize-seinfeld.sh`)

| What | Path |
| --- | --- |
| Corpus root | `$HOME/plugin-sandbox-Obsidian/Seinfeld (custom)/` |
| Episode transcripts (174 `.md`) | `…/Seinfeld (custom)/episodes/` |
| Q&A notes (34 `.md`) | `…/Seinfeld (custom)/trivia/` |
| Human index | `…/Seinfeld (custom)/README.md` |
| Eval JSON (in git) | `scripts/cloud-e2e/fixtures/seinfeld-eval.json` |
| Clone cache (install only) | `$HOME/.cache/cloud-e2e-seinfeld` |

Transcripts are **not** committed to this skills repo. Cloud Agent **install**
runs `materialize-seinfeld.sh` via `materialize-vault.sh` / `env-install.sh`.

```bash
bash scripts/cloud-e2e/materialize-seinfeld.sh
ls "$HOME/plugin-sandbox-Obsidian/Seinfeld (custom)/episodes/"*.md | wc -l   # 174
ls "$HOME/plugin-sandbox-Obsidian/Seinfeld (custom)/trivia/"Q*.md | wc -l      # 34
```

## How the files are Q and A

Think of three layers that must stay aligned:

```text
Question (query) ──► Answer (gold string) ──► Episode note (gold document)
```

### Upstream (`data.json` in AI21 repo)

Each item in `seinfeld_trivia/data.json` → `examples[]`:

| Field | Role |
| --- | --- |
| `id` | Stable UUID |
| `query` | **Q** — the trivia question (also the Seek search string) |
| `answer` | **A** — reference answer text for humans |
| `targets[].file_name` | Gold **document** filename under `documents_content/` (e.g. `S09E10.md`) |

Curated subset: single-target questions only (multi-target / no-answer / ambiguous dropped upstream — see fixture `description`).

### Sandbox fixture (`seinfeld-eval.json`)

Same 34 examples, flattened for agents and smoke tests:

| Field | Maps from upstream |
| --- | --- |
| `examples[].id` | `id` |
| `examples[].query` | `query` (**Q**) |
| `examples[].answer` | `answer` (**A**) |
| `examples[].expectedEpisode` | `targets[0].file_name` |

List:

```bash
jq -r '.examples[] | "Q: \(.query)\nA: \(.answer)\nDoc: \(.expectedEpisode)\n"' \
  scripts/cloud-e2e/fixtures/seinfeld-eval.json
```

### Vault notes (`trivia/` + `episodes/`)

`materialize-seinfeld.sh` writes one Obsidian note per example under `trivia/`:

- Title / H1 = **Q** (`query`)
- Body **Answer:** = **A**
- Wikilink **Gold episode** → `../episodes/<SxxEyy>`
- Frontmatter: `id`, `expected_episode`, `type: seinfeld-trivia`

Episode markdown under `episodes/` is the retrieval target (summary + transcript).
Trivia notes are for humans/agents browsing Q&A — **Seek rank scoring should
hit the episode note**, not the trivia note.

## Run a question (Seek)

Prerequisites: Obsidian up, community plugins on, Seek enabled, index caught up.
Boot: [obsidian-cloud-e2e](../obsidian-cloud-e2e/SKILL.md) and
[`scripts/cloud-e2e/GETTING-STARTED.md`](../../scripts/cloud-e2e/GETTING-STARTED.md).

1. Pick an example (`jq '.examples[0]' …/seinfeld-eval.json` or open a `trivia/Q*.md` note).
2. Search **only the `query` string** with Seek (`vault=plugin-sandbox-Obsidian`).
3. **Pass:** rank-1 path ends with `Seinfeld (custom)/episodes/<expectedEpisode>`
   (or basename matches `expectedEpisode`).
4. Optionally confirm the snippet supports `answer` (human check; not required for automated smoke).

Do **not** paste the answer into the search box — that leaks the label.

CLI sketch:

```bash
export PATH="$HOME/.local/bin:$PATH"
Q=$(jq -r '.examples[0].query' scripts/cloud-e2e/fixtures/seinfeld-eval.json)
# Prefer Seek command / modal; plain `obsidian search` is lexical-only.
obsidian vault=plugin-sandbox-Obsidian search query="$Q"
```

## Offline smoke (not the skill’s manual eval)

Tier-2 Seek harness (fake embedder — partial rank-1 hits expected):

```bash
bash scripts/cloud-e2e/run-seinfeld-seek-smoke.sh
```

## Related

- [obsidian-cloud-e2e](../obsidian-cloud-e2e/SKILL.md) — vault bootstrap, CDP, Linux Obsidian
- `scripts/cloud-e2e/README.md` — install lifecycle
- Upstream: https://github.com/AI21Labs/multi-window-chunk-size/tree/master/seinfeld_trivia

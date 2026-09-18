---
name: seek-seinfeld-eval
description: >-
  Use the AI21 Seinfeld trivia corpus and fixed eval questions in the Cloud
  sandbox vault for manual Seek retrieval checks. Use for Cloud E2E search
  validation, not production vaults.
---

# Seek — Seinfeld trivia eval (Cloud sandbox)

Corpus: [AI21Labs/multi-window-chunk-size](https://github.com/AI21Labs/multi-window-chunk-size) (`seinfeld_trivia/` — episode markdown; upstream also ships `data.json`).

Always use **`vault=plugin-sandbox-Obsidian`**. Do not run this eval against the Windows production vault.

## Where files live

| What | Path |
| --- | --- |
| Vault root | `$HOME/plugin-sandbox-Obsidian` |
| Episode transcripts (174 `.md`) | `$HOME/plugin-sandbox-Obsidian/Seinfeld/episodes/` |
| Eval questions (34, in git) | `scripts/cloud-e2e/fixtures/seinfeld-eval.json` in **obsidian-plugin-development** |
| Clone cache (install only) | `$HOME/.cache/cloud-e2e-seinfeld` |

Transcripts are **not** in git. Cloud Agent **install** runs `materialize-seinfeld.sh` via `materialize-vault.sh` (see `.cursor/environment.json`).

Manual rerun on a live pod:

```bash
bash scripts/cloud-e2e/materialize-seinfeld.sh
```

Overrides: `CLOUD_E2E_SEINFELD_CACHE`, `CLOUD_E2E_SEINFELD_REPO`, `CLOUD_E2E_SEINFELD_REF`, `CLOUD_E2E_VAULT`.

Quick check:

```bash
ls "$HOME/plugin-sandbox-Obsidian/Seinfeld/episodes/"*.md | wc -l
```

Expect **174** files after a successful materialize.

## Eval fixture schema

`fixtures/seinfeld-eval.json` fields:

| Field | Meaning |
| --- | --- |
| `examples[].id` | Stable UUID from the AI21 dataset |
| `examples[].query` | Question text to search |
| `examples[].expectedEpisode` | Gold episode **filename** (e.g. `S09E10.md`) under `Seinfeld/episodes/` |
| `examples[].answer` | Reference answer text (human check; not used for automated rank scoring in this skill) |

List questions:

```bash
jq -r '.examples[] | "\(.query) → \(.expectedEpisode)"' \
  scripts/cloud-e2e/fixtures/seinfeld-eval.json
```

Pick one example:

```bash
jq '.examples[0]' scripts/cloud-e2e/fixtures/seinfeld-eval.json
```

## Run a question (in Obsidian)

Prerequisites: Obsidian up on the Cloud pod, Seek enabled, index finished for the sandbox vault. Boot flow: [obsidian-cloud-e2e](../obsidian-cloud-e2e/SKILL.md).

1. Read `query` and `expectedEpisode` from the fixture (or jq as above).
2. Run Seek for that query with **`vault=plugin-sandbox-Obsidian`** — Obsidian CLI `seek:search` with JSON output, or open the Seek modal in the sandbox vault and search the same string.
3. **Pass (manual):** rank-1 result path ends with `Seinfeld/episodes/<expectedEpisode>` (or the note basename matches `expectedEpisode`).
4. Optionally confirm snippet content aligns with `answer` in the fixture.

Run several questions across seasons; the fixture is a curated subset of the AI21 benchmark (single target episode per question).

## Related

- [obsidian-cloud-e2e](../obsidian-cloud-e2e/SKILL.md) — vault bootstrap, CDP, Obsidian on Linux
- `scripts/cloud-e2e/README.md` — install lifecycle; optional Tier-2 smoke script for CI (not covered here)

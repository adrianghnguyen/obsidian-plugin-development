---
name: seek-seinfeld-eval
description: >-
  Load the AI21 Seinfeld trivia transcript corpus into the Cloud sandbox vault and
  smoke-test Obsidian Seek rank-1 retrieval against fixed questions. Use for Cloud
  E2E search regression, not production vaults.
---

# Seek — Seinfeld trivia eval (Cloud sandbox)

Corpus: [AI21Labs/multi-window-chunk-size](https://github.com/AI21Labs/multi-window-chunk-size) (`seinfeld_trivia/` — episode markdown + `data.json` examples).

Vault target: `$HOME/plugin-sandbox-Obsidian` (`vault=plugin-sandbox-Obsidian`). Episodes land under `Seinfeld/episodes/*.md`. Questions and gold episode filenames live in git as `scripts/cloud-e2e/fixtures/seinfeld-eval.json` (no transcript dump in git).

## Materialize corpus (every Cloud Agent install)

Seinfeld episodes are **not** in git. They are copied on every `env-install.sh` / `materialize-vault.sh` (wired from `.cursor/environment.json` install on Cloud Agents).

Vault path: `$HOME/plugin-sandbox-Obsidian/Seinfeld/episodes/*.md` (`vault=plugin-sandbox-Obsidian`).

Source: shallow clone of [AI21Labs/multi-window-chunk-size](https://github.com/AI21Labs/multi-window-chunk-size) (`master` by default) into `$HOME/.cache/cloud-e2e-seinfeld`, then copy transcripts.

Manual rerun:

```bash
bash scripts/cloud-e2e/materialize-seinfeld.sh
```

Override `CLOUD_E2E_SEINFELD_CACHE`, `CLOUD_E2E_SEINFELD_REPO`, `CLOUD_E2E_SEINFELD_REF`.

## Smoke Seek (Tier-2 harness)

Uses the real Seek `SearchOrchestrator` + fake embedder (same as `obsidian-seek` Scenario tests), reading episode files from the vault directory.

```bash
bash scripts/cloud-e2e/run-seinfeld-seek-smoke.sh
```

Environment:

| Variable | Default |
| --- | --- |
| `SEINFELD_EPISODES_DIR` | `$CLOUD_E2E_VAULT/Seinfeld/episodes` |
| `SEINFELD_SMOKE_LIMIT` | `8` (first N eval questions) |

Stdout includes JSON with `hits` count and `misses` (query, expected episode, actual rank-1 path). Test fails if zero hits.

For in-Obsidian CLI smoke (indexed embedder, slow cold build), use serial `obsidian eval vault=plugin-sandbox-Obsidian` + `seek:search` only after index ready — see [obsidian-cloud-e2e](../obsidian-cloud-e2e/SKILL.md). Prefer the harness script in Cloud Agent CI.

## Related

- [obsidian-cloud-e2e](../obsidian-cloud-e2e/SKILL.md) — vault bootstrap, Obsidian CDP
- `obsidian-seek` `src/test-harness/scenario.ts` — harness implementation

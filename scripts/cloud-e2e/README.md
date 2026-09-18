# Cloud E2E vault

Linux synthetic vault for Cursor Cloud Agents. Same plugin ids as the Windows staging vault (`seek`, `whisper`, `agent-client`), fake notes only.

**Full boot + CLI walkthrough:** [`GETTING-STARTED.md`](./GETTING-STARTED.md)

## Layout

| Path | Role |
| --- | --- |
| `$HOME/plugin-sandbox-Obsidian` | Vault root (`vault=plugin-sandbox-Obsidian`) |
| `$HOME/.obsidian-cloud-e2e-profile` | Isolated Electron user-data-dir (not your laptop profile) |
| `$HOME/.local/opt/obsidian` | Extracted AppImage |
| `$HOME/.local/bin/obsidian` | Symlink to `obsidian-cli` (requires CLI toggle on) |

Override with `CLOUD_E2E_*` vars in `paths.env`.

## Lifecycle

| Phase | Script | Secrets |
| --- | --- | --- |
| Build / install | `install-obsidian.sh` then `materialize-vault.sh` | No. Download Obsidian, copy plugin artifacts, seed notes. |
| Start | `start-obsidian.sh` (foreground; Xvfb if needed) | Forwards process env into Electron. Writes `"cli": true` into profile `obsidian.json`. |
| After ready | `dismiss-starter` → `enable-plugins` → `enable-cli` → `inject` | Turns off Restricted mode, loads community plugins, ensures CLI IPC is on, then injects secrets over localhost CDP. |

Do not put keys in `data.json`, git, Install logs, or `obsidian eval code="...$KEY..."`.

`start-obsidian.sh` forces the sandbox vault (`plugin-sandbox-Obsidian`) as the sole `open` vault in the isolated profile so Obsidian does not land on an empty default vault.

Two toggles that must be **on** (both automated by `env-start.sh`):

1. **Community plugins** — Restricted mode off (`cdp.mjs enable-plugins`)
2. **Command line interface** — Settings → General → Advanced (`cdp.mjs enable-cli` / profile `"cli": true`)


## Secret map

Each plugin owns `.cloud-e2e/secret-bindings.json` (Cursor env → `secretStorage` id + optional settings pointer). `cdp.mjs inject` merges those files. Skill: `obsidian-secret-mapping`.

```bash
node cdp.mjs probe   # envSet, id lengths, pointer strings — no key values
```

## Identity gate

```bash
node cdp.mjs eval 'JSON.stringify({name:app.vault.getName(),base:app.vault.adapter.basePath,plugins:Object.keys(app.plugins.plugins)})'
```

Expect `name` = `plugin-sandbox-Obsidian` and `base` = the `CLOUD_E2E_VAULT` path.

## ACP agents (Cursor + Antigravity)

`env-install.sh` runs `install-acp-agents.sh`, which:

- Installs the **Cursor CLI** (`~/.local/bin/agent`) when missing
- Downloads **Antigravity** `agy_acp_server.par` (ACP registry `linux-x86_64`) into `~/.local/bin/`
- Ensures a **`nobody`** system group exists (required for the bridge on minimal images)
- Writes `~/.gemini/antigravity-cli/settings.json` with `modelProvider: gemini` when `GEMINI_API_KEY` is set

**Secrets (Cloud environment, not Obsidian secretStorage):**

| Env var | Used by |
| --- | --- |
| `CURSOR_API_KEY` | Cursor CLI / `agent acp` (User API key from [dashboard → API Keys](https://cursor.com/dashboard/api)) |
| `GEMINI_API_KEY` | Antigravity bridge API-key auth (also injected into Obsidian for other presets) |

`agent status` may still say “Not logged in” in API-key mode; verify with a non-interactive prompt (`agent -p -f --api-key "$CURSOR_API_KEY" "Reply OK"`). Agent Client preset UX for Cursor/Antigravity requires [obsidian-agent-client](https://github.com/adrianghnguyen/obsidian-agent-client) PRs #27 / #28 on `main`.

## Plugin builds

`materialize-vault.sh` copies `main.js`, `manifest.json`, `styles.css` from sibling checkouts. Run `npm run build` in those repos first.

## Seinfeld (custom) eval corpus (AI21)

`env-install.sh` → `materialize-vault.sh` → `materialize-seinfeld.sh` shallow-clones [AI21Labs/multi-window-chunk-size](https://github.com/AI21Labs/multi-window-chunk-size) (`master`) and materializes:

| Vault path | Contents |
| --- | --- |
| `Seinfeld (custom)/episodes/` | 174 episode transcripts from `seinfeld_trivia/documents_content` |
| `Seinfeld (custom)/trivia/` | 34 Q&A notes generated from `fixtures/seinfeld-eval.json` |
| `Seinfeld (custom)/README.md` | Index + how Q→A→episode maps |

Trivia lives in that AI21 **demo** repo (not a standalone dataset project). Eval questions are also pinned in git as `fixtures/seinfeld-eval.json`. Companion skill: **`seek-seinfeld-eval`** (Q&A file mapping + Seek checks).

**Smoke (CI / scripts, not the skill):** Tier-2 Seek harness via `run-seinfeld-seek-smoke.sh` (copies `seinfeld-seek-smoke.test.ts` into `obsidian-seek` and runs Vitest). Env: `SEINFELD_SMOKE_LIMIT` (default 8), `SEINFELD_EPISODES_DIR`. Uses the fake embedder — partial rank-1 hits are expected; not AI21 benchmark fidelity.

```bash
bash scripts/cloud-e2e/run-seinfeld-seek-smoke.sh
```

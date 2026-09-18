# Cloud E2E vault

Linux synthetic vault for Cursor Cloud Agents. Same plugin ids as the Windows staging vault (`seek`, `whisper`, `agent-client`), fake notes only.

## Layout

| Path | Role |
| --- | --- |
| `$HOME/plugin-sandbox-Obsidian` | Vault root (`vault=plugin-sandbox-Obsidian`) |
| `$HOME/.obsidian-cloud-e2e-profile` | Isolated Electron user-data-dir (not your laptop profile) |
| `$HOME/.local/opt/obsidian` | Extracted AppImage |

Override with `CLOUD_E2E_*` vars in `paths.env`.

## Lifecycle

| Phase | Script | Secrets |
| --- | --- | --- |
| Build / install | `install-obsidian.sh` then `materialize-vault.sh` | No. Download Obsidian, copy plugin artifacts, seed notes. |
| Start | `start-obsidian.sh` (foreground; Xvfb if needed) | Forwards process env into Electron. Does not write keys to disk. |
| After ready | `node cdp.mjs dismiss-starter` → `enable-plugins` → `inject` | Turns off Restricted mode (`localStorage enable-plugin-<appId>`), loads enabled community plugins, then injects secrets over localhost CDP. |

Do not put keys in `data.json`, git, Install logs, or `obsidian eval code="...$KEY..."`.

`start-obsidian.sh` forces the sandbox vault (`plugin-sandbox-Obsidian`) as the sole `open` vault in the isolated profile so Obsidian does not land on an empty default vault.

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

## Plugin builds

`materialize-vault.sh` copies `main.js`, `manifest.json`, `styles.css` from sibling checkouts. Run `npm run build` in those repos first.

## Seinfeld eval corpus (AI21)

`env-install.sh` → `materialize-vault.sh` → `materialize-seinfeld.sh` shallow-clones [AI21Labs/multi-window-chunk-size](https://github.com/AI21Labs/multi-window-chunk-size) (`master`) and copies 174 episode transcripts to `$CLOUD_E2E_VAULT/Seinfeld/episodes/`. Eval questions (34) live in git as `fixtures/seinfeld-eval.json`. Skill: `seek-seinfeld-eval`.

**Smoke (CI / scripts, not the skill):** Tier-2 Seek harness via `run-seinfeld-seek-smoke.sh` (copies `seinfeld-seek-smoke.test.ts` into `obsidian-seek` and runs Vitest). Env: `SEINFELD_SMOKE_LIMIT` (default 8), `SEINFELD_EPISODES_DIR`. Uses the fake embedder — partial rank-1 hits are expected; not AI21 benchmark fidelity.

```bash
bash scripts/cloud-e2e/run-seinfeld-seek-smoke.sh
```

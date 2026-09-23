# Getting Obsidian running on Cursor Cloud (with sample files + CLI)

This is the end-to-end setup for the multi-repo Obsidian Cloud Agent environment:
`obsidian-plugin-development` (orchestrator) plus sibling plugins `obsidian-seek`,
`whisper-obsidian-plugin`, and `obsidian-agent-client`.

**Generalized process skill:** [`skills/obsidian-cloud-env-setup/SKILL.md`](../../skills/obsidian-cloud-env-setup/SKILL.md)
(sample files, Restricted mode + CLI, verify, snapshot/Save).

Target vault name: **`plugin-sandbox-Obsidian`**
Vault path: **`$HOME/plugin-sandbox-Obsidian`** (default `/home/ubuntu/plugin-sandbox-Obsidian`)

## What “working” means

| Gate | Pass criteria |
| --- | --- |
| App running | Obsidian Electron process up; CDP on `127.0.0.1:9222` |
| Sample files | Fixture notes under `Notes/` plus **Seinfeld (custom)** AI21 corpus |
| Community plugins on | Restricted mode **off**; `seek`, `whisper`, `agent-client` loaded |
| CLI access | `obsidian` binary responds (not “CLI is not enabled”); can `files` / `read` / `search` |

## One-shot boot

From any cwd after the four repos are checked out under `/agent/repos`:

```bash
# 1) Install deps, download AppImage, materialize vault + plugin artifacts
bash /agent/repos/obsidian-plugin-development/scripts/cloud-e2e/env-install.sh

# 2) Start Xvfb + Obsidian, enable plugins + CLI, inject secrets
bash /agent/repos/obsidian-plugin-development/scripts/cloud-e2e/env-start.sh

# 3) Put CLI on PATH (env-start also exports this for its own process)
export PATH="$HOME/.local/bin:$PATH"
```

Environment `install` / `start` in the Cloud Agent dashboard should point at those two scripts.

## Why two toggles must be turned on

### 1. Community plugins (Restricted mode)

New Obsidian profiles ship with **Restricted mode** on. Community plugins appear in
`community-plugins.json` but **do not load** until:

```text
localStorage["enable-plugin-" + app.appId] === "true"
```

`env-start.sh` runs `node cdp.mjs enable-plugins`, which calls
`app.plugins.setEnable(true)` and then `enablePlugin` for each listed id.

Without this step you will see empty `app.plugins.plugins` even though the
plugin folders and `main.js` files exist.

### 2. Command line interface

The `obsidian-cli` binary is installed by `install-obsidian.sh` as
`$HOME/.local/bin/obsidian`, but Obsidian still refuses CLI IPC until
**Settings → General → Advanced → Command line interface** is on.

That flag is stored as `"cli": true` in the profile `obsidian.json` and toggled
live via Electron IPC:

```js
electron.ipcRenderer.sendSync("cli", true);
```

`start-obsidian.sh` writes `"cli": true` into the profile before launch.
`env-start.sh` also runs `node cdp.mjs enable-cli` so an already-running app
picks it up without a restart.

If you see:

```text
Command line interface is not enabled. Please turn it on in Settings > General > Advanced.
```

run:

```bash
node /agent/repos/obsidian-plugin-development/scripts/cloud-e2e/cdp.mjs enable-cli
```

## Sample files

`materialize-vault.sh` copies fixtures from
`scripts/cloud-e2e/fixtures/vault/` into `$HOME/plugin-sandbox-Obsidian`, then
`materialize-seinfeld.sh` adds the **Seinfeld (custom)** AI21 trivia corpus:

| Path | Role |
| --- | --- |
| `Welcome.md` | Sandbox landing note |
| `Notes/*.md` | Small searchable corpus (canary: `obsidian-cloud-e2e-canary-phrase`) |
| `Seinfeld (custom)/episodes/*.md` | 174 AI21 episode transcripts |
| `Seinfeld (custom)/trivia/Q*.md` | 34 Q&A notes (question → answer → gold episode) |
| `Seinfeld (custom)/README.md` | Corpus index + Q&A mapping |
| `.obsidian/community-plugins.json` | Enables `seek`, `whisper`, `agent-client` |
| `.obsidian/appearance.json` | Dark mode (`obsidian`) plus community theme **Material Gruvbox** |
| `.obsidian/themes/Material Gruvbox/` | Vendored theme (`manifest.json`, `theme.css`, `LICENSE`) |
| `.obsidian/plugins/*/main.js` | Built plugin artifacts from sibling repos |

Q&A companion skill: `seek-seinfeld-eval` (how `query` / `answer` / `expectedEpisode` map to vault files).

## CLI cheatsheet

Always pass the vault name on Cloud (no interactive picker):

```bash
export PATH="$HOME/.local/bin:$PATH"
VAULT=plugin-sandbox-Obsidian

obsidian version
obsidian vault="$VAULT" files
obsidian vault="$VAULT" read file="Welcome"
obsidian vault="$VAULT" search query="obsidian-cloud-e2e-canary-phrase"
obsidian vault="$VAULT" plugins          # includes seek / whisper / agent-client when loaded
obsidian vault="$VAULT" create name="demo" content="# demo\n"
```

Socket used by the CLI on Linux: `$HOME/.obsidian-cli.sock` (created once CLI is enabled and Obsidian is running).

## CDP identity gate (plugins + vault)

```bash
node /agent/repos/obsidian-plugin-development/scripts/cloud-e2e/cdp.mjs eval \
  'JSON.stringify({
    name: app.vault.getName(),
    base: app.vault.adapter.basePath,
    restricted: !app.plugins.isEnabled(),
    plugins: Object.keys(app.plugins.plugins),
  })'
```

Expect:

```json
{
  "name": "plugin-sandbox-Obsidian",
  "base": "/home/ubuntu/plugin-sandbox-Obsidian",
  "restricted": false,
  "plugins": ["seek", "agent-client", "whisper"]
}
```

## Layout reference

| Path | Role |
| --- | --- |
| `$HOME/plugin-sandbox-Obsidian` | Synthetic vault |
| `$HOME/.obsidian-cloud-e2e-profile` | Isolated `--user-data-dir` (`obsidian.json` holds vaults + `"cli": true`) |
| `$HOME/.local/opt/obsidian` | Extracted AppImage (Obsidian 1.13.7) |
| `$HOME/.local/bin/obsidian` | Symlink → `obsidian-cli` |
| `$HOME/.local/bin/obsidian-app` | Symlink → Electron app |

## Restart / recovery

```bash
# Stop only the real Obsidian binary (do not pkill by argv substring — it can kill your shell)
BIN="$HOME/.local/opt/obsidian/squashfs-root/obsidian"
for pid in $(ls /proc | grep -E '^[0-9]+$'); do
  exe=$(readlink "/proc/$pid/exe" 2>/dev/null || true)
  [ "$exe" = "$BIN" ] && kill "$pid" 2>/dev/null || true
done
sleep 2
bash /agent/repos/obsidian-plugin-development/scripts/cloud-e2e/env-start.sh
```

## Secrets (optional for CLI / sample files)

CLI file ops and fixture notes need **no** API keys. Secret inject is only for
live Whisper / Agent Client features:

```bash
node /agent/repos/obsidian-plugin-development/scripts/cloud-e2e/cdp.mjs inject
node /agent/repos/obsidian-plugin-development/scripts/cloud-e2e/cdp.mjs probe   # lengths only
```

Never put keys in `data.json` or into `obsidian eval` / CDP strings that get logged.

## Related files

- Scripts overview: [`README.md`](./README.md)
- Skill: [`../../skills/obsidian-cloud-e2e/SKILL.md`](../../skills/obsidian-cloud-e2e/SKILL.md)
- Paths / overrides: [`paths.env`](./paths.env)

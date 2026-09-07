# Obsidian plugin dev — reference

Sources: https://docs.obsidian.md/Plugins/Getting+started/Build+a+plugin , https://obsidian.md/help/cli

## Build a plugin (summary)

1. Empty dev vault (not production).
2. Plugin under `.obsidian/plugins/<id>/`.
3. `npm install` → `npm run dev`.
4. Enable in Settings → Community plugins.

**Restart Obsidian** after `manifest.json` changes when `plugin:reload` is insufficient.

## CLI parameters

```
vault=<unique-name>    # FIRST arg for multi-vault
file=<name>            # wikilink-style
path=<exact/path.md>   # exact path
--copy                 # copy output to clipboard
```

## Developer commands

| Command | Purpose |
|---------|---------|
| `devtools` | Electron dev tools |
| `dev:debug on\|off` | CDP attach |
| `dev:errors` | Captured JS errors |
| `dev:screenshot path=<file>` | Screenshot |
| `dev:console` | Captured console |
| `dev:css selector=<sel>` | Inspect CSS |
| `dev:dom selector=<sel>` | Query DOM |
| `eval code=<javascript>` | Execute JS |

| Plugin command | Purpose |
|----------------|---------|
| `plugin:reload id=<id>` | Reload plugin |
| `plugin:enable/disable id=<id>` | Toggle |
| `reload vault=<name>` | Reload one vault window |
| `restart` | **Global** — all vaults |

## Plugin folder layout

```
.obsidian/plugins/<id>/
  main.js
  manifest.json
  styles.css       # optional
  data.json        # runtime — do not overwrite on deploy
```

## Verification recipes

```powershell
(gci repo\main.js).Length -eq (gci <vault>\.obsidian\plugins\<id>\main.js).Length
obsidian vault=<name> plugin id=<id>
obsidian vault=<name> eval code="String(app.plugins.plugins.<id>?.settings?.someKey)"
```

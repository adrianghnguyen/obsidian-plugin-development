# Machine profile (copy and customize locally)

Copy this file to your machine (e.g. `references/machine-profile.md`, gitignored) and fill in paths. Skills reference these placeholders instead of hardcoding one developer's layout.

| Placeholder | Example value | Used for |
|-------------|---------------|----------|
| `<sandbox-vault-name>` | `plugin-sandbox-Obsidian` | CLI `vault=` argument — must be a **unique** substring |
| `<sandbox-vault-path>` | `C:\plugin-sandbox-Obsidian` | Staging vault root; deploy target |
| `<production-vault-name>` | `Obsidian` | Production vault display name — **do not** use as `vault=` if it substring-matches the sandbox |
| `<production-vault-path>` | `C:\Obsidian` | Production vault root; shell cwd for production CLI |
| `<coding-projects>` | `C:\Coding_projects` | Out-of-vault plugin repos |
| `<promote-script>` | `C:\plugin-sandbox-Obsidian\Administrative\scripts\promote-plugin-to-main.ps1` | Optional promote helper |

## CLI targeting

```powershell
# Sandbox — unique vault= FIRST
obsidian vault=<sandbox-vault-name> plugin:reload id=<plugin-id>

# Production — cwd is the selector; omit vault=
Set-Location <production-vault-path>
obsidian plugin:reload id=<plugin-id>
```

**Never** `vault=<production-vault-name>` when the sandbox name contains that substring (e.g. `Obsidian` inside `plugin-sandbox-Obsidian`).

## Deploy paths

```
<sandbox-vault-path>/.obsidian/plugins/<plugin-id>/
<production-vault-path>/.obsidian/plugins/<plugin-id>/
```

## Companion skills (not vendored here)

- **powershell-agent** — Windows `obsidian eval` quoting and JSON CLI args. Install globally in `~/.cursor/skills/` if you develop on Windows.

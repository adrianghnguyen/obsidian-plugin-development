# Machine profile (copy and customize locally)

Copy this file to your machine (e.g. `references/machine-profile.md`, gitignored) and fill in paths. Skills reference these placeholders instead of hardcoding one developer's layout.

| Placeholder | Example value | Used for |
|-------------|---------------|----------|
| `<sandbox-vault-name>` | `plugin-sandbox-Obsidian` | `vault=` token (see `obsidian-vault-target-verify`) |
| `<sandbox-vault-path>` | `C:\plugin-sandbox-Obsidian` | Staging vault root; deploy target |
| Cloud E2E vault | `$HOME/plugin-sandbox-Obsidian` | Synthetic vault on Cursor Cloud Linux (see `scripts/cloud-e2e`) |
| `<production-vault-name>` | `Obsidian` | Identity-gate name only — **never** `vault=Obsidian` (see `obsidian-vault-target-verify`) |
| `<production-vault-path>` | `C:\Obsidian` | Production vault root |
| `<coding-projects>` | `C:\Coding_projects` | Out-of-vault plugin repos |
| `<promote-script>` | `C:\plugin-sandbox-Obsidian\Administrative\scripts\promote-plugin-to-main.ps1` | Optional promote helper |

## CLI targeting

Vault-target discovery is defined by the global rule `obsidian-vault-target-verify`. Fill in names/paths only.

| Role | `vault=` | Must print |
|------|----------|------------|
| Sandbox | `<sandbox-vault-name>` | name + `<sandbox-vault-path>` |
| Production | **omit** `vault=` (cwd `<production-vault-path>`) | name + `<production-vault-path>` |

```powershell
obsidian vault=<sandbox-vault-name> eval code="app.vault.getName()"
obsidian vault=<sandbox-vault-name> eval code="app.vault.adapter.basePath"
obsidian vault=<sandbox-vault-name> plugin:reload id=<plugin-id>

Set-Location <production-vault-path>
obsidian eval code="app.vault.getName()"
obsidian eval code="app.vault.adapter.basePath"
obsidian plugin:reload id=<plugin-id>
```

## Deploy paths

```
<sandbox-vault-path>/.obsidian/plugins/<plugin-id>/
<production-vault-path>/.obsidian/plugins/<plugin-id>/
```

## Companion skills (not vendored here)

- **powershell-agent** — Windows `obsidian eval` quoting and JSON CLI args. Install globally in `~/.cursor/skills/` if you develop on Windows.

# Agent notes

## Cursor plugin install (this repo)

- **Local `:latest`:** `~/.cursor/plugins/local/obsidian-plugin-development` should be a junction to this working tree (`C:\Coding_projects\obsidian-plugin-development`), not a pinned marketplace commit. After skill edits: **Developer: Reload Window**.
- **Marketplace unpin:** Personal `/add-plugin` installs pin to the first commit; `marketplace update` does not advance them. Use `powershell -File scripts/refresh-cursor-marketplace.ps1` (remove + wipe cache + re-add `--git-ref main`).
- **Post-push:** `scripts/git-hooks/post-push` runs that refresh after `git push`. Install once: `powershell -File scripts/git-hooks/install.ps1`. Reload Cursor after push.

## Cursor Cloud environment

This repo owns the Cloud Agent setup. Sibling plugin `main`s carry the same `.cursor/environment.json`; **script and id-map bodies live only here**.

- Pointer: `.cursor/environment.json` (`install` / `start` — identical on all four plugin repos)
- Scripts: `scripts/cloud-e2e/env-install.sh`, `env-start.sh`, `install-acp-agents.sh`, `paths.env`
- Walkthrough: `scripts/cloud-e2e/README.md`, `GETTING-STARTED.md`
- Secret **ids** (not values): plugin-owned `<plugin>/.cloud-e2e/secret-bindings.json` (agent-client, whisper). Fallbacks: `scripts/cloud-e2e/bindings/{agent-client,whisper,seek}.json`, merged by `load-bindings.mjs` (`cdp.mjs inject`)
- Identity gate is not a separate file: `env-start.sh` CDP eval; vault name/path from `paths.env` (`CLOUD_E2E_VAULT_NAME` / `CLOUD_E2E_VAULT`)

Project overview (do not copy): `/cursor/stores/bc-a8a2e9ee-3f2b-4d31-ae8c-85b3734c071e/docs/cursor-environment-docs.md`

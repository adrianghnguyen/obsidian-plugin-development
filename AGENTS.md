# Agent notes

## Cursor plugin install (this repo)

- **Local `:latest`:** `~/.cursor/plugins/local/obsidian-plugin-development` should be a junction to this working tree (`C:\Coding_projects\obsidian-plugin-development`), not a pinned marketplace commit. After skill edits: **Developer: Reload Window**.
- **Post-push refresh:** `scripts/git-hooks/post-push` runs `cursor-agent plugin marketplace update` after `git push`. Install once: `powershell -File scripts/git-hooks/install.ps1`.

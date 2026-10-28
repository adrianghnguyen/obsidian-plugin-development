#!/usr/bin/env bash
# Ensures /agent/repos/* checkouts exist before env-install.sh / env-start.sh.
# Cloud environment builds clone only the primary repo to /workspace; orchestrator-
# primary projects need a symlink, and sibling plugins may need shallow clones when
# repositoryDependencies are not materialized under /agent/repos yet.
set -euo pipefail

ROOT=/agent/repos
mkdir -p "$ROOT"
ORCH="$ROOT/obsidian-plugin-development"

link_workspace_orchestrator() {
  if [ -f /workspace/scripts/cloud-e2e/env-install.sh ]; then
    ln -sfn /workspace "$ORCH"
  fi
}

link_workspace_plugin() {
  local dir=$1
  local plugin_id=$2
  if [ -d "$ROOT/$dir" ] || [ ! -f /workspace/manifest.json ]; then
    return 0
  fi
  if grep -q "\"id\": \"${plugin_id}\"" /workspace/manifest.json 2>/dev/null; then
    ln -sfn /workspace "$ROOT/$dir"
  fi
}

clone_if_missing() {
  local dir=$1
  local url=$2
  local optional=${3:-}
  if [ -d "$ROOT/$dir" ]; then
    return 0
  fi
  if [ "$optional" = optional ]; then
    echo "bootstrap: skip optional clone $dir"
    return 0
  fi
  echo "bootstrap: clone $dir"
  git clone --depth 1 "$url" "$ROOT/$dir"
}

link_workspace_orchestrator
link_workspace_plugin obsidian-seek seek
link_workspace_plugin obsidian-agent-client agent-client
link_workspace_plugin whisper-obsidian-plugin whisper
link_workspace_plugin obsidian-book-search-plugin book-search

clone_if_missing obsidian-plugin-development \
  https://github.com/adrianghnguyen/obsidian-plugin-development.git
link_workspace_orchestrator

clone_if_missing obsidian-agent-client \
  https://github.com/adrianghnguyen/obsidian-agent-client.git
clone_if_missing obsidian-seek \
  https://github.com/adrianghnguyen/obsidian-seek.git
clone_if_missing whisper-obsidian-plugin \
  https://github.com/adrianghnguyen/whisper-obsidian-plugin.git
clone_if_missing obsidian-book-search-plugin \
  https://github.com/adrianghnguyen/obsidian-book-search-plugin.git optional

if [ ! -f "$ORCH/scripts/cloud-e2e/env-install.sh" ]; then
  echo "bootstrap: orchestrator scripts missing at $ORCH" >&2
  exit 1
fi

echo "bootstrap: ok ($ORCH)"

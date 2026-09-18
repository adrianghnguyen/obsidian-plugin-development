#!/usr/bin/env bash
set -euo pipefail

# Prefer a newer Node from nvm when present (jsdom/undici engine floors).
if [ -x "$HOME/.nvm/versions/node/v22.22.2/bin/node" ]; then
  export PATH="$HOME/.nvm/versions/node/v22.22.2/bin:$PATH"
fi

ROOT=""
if [ -d /agent/repos/obsidian-seek ]; then
  ROOT=/agent/repos
elif [ -d obsidian-seek ]; then
  ROOT="$PWD"
elif [ -d ../obsidian-seek ]; then
  ROOT="$(cd .. && pwd)"
else
  echo "Cannot find plugin repos (obsidian-seek)." >&2
  exit 1
fi
export CLOUD_E2E_REPOS="$ROOT"
DEV="$ROOT/obsidian-plugin-development"

for r in obsidian-agent-client obsidian-seek whisper-obsidian-plugin; do
  echo "install $r"
  (
    cd "$ROOT/$r"
    if [ -f pnpm-lock.yaml ] && command -v pnpm >/dev/null 2>&1; then
      pnpm install --frozen-lockfile
    elif [ -f package-lock.json ]; then
      npm ci || npm install --legacy-peer-deps
    else
      npm install --legacy-peer-deps
    fi
  )
done

if [ -x "$DEV/scripts/cloud-e2e/install-acp-agents.sh" ]; then
  bash "$DEV/scripts/cloud-e2e/install-acp-agents.sh"
fi

if [ -x "$DEV/scripts/cloud-e2e/install-obsidian.sh" ]; then
  bash "$DEV/scripts/cloud-e2e/install-obsidian.sh"
  bash "$DEV/scripts/cloud-e2e/materialize-vault.sh"
fi

for r in obsidian-agent-client obsidian-seek whisper-obsidian-plugin; do
  echo "build $r"
  (
    cd "$ROOT/$r"
    if [ -f pnpm-lock.yaml ] && command -v pnpm >/dev/null 2>&1; then
      pnpm run build
    else
      npm run build
    fi
  )
done

if [ -x "$DEV/scripts/cloud-e2e/materialize-vault.sh" ]; then
  bash "$DEV/scripts/cloud-e2e/materialize-vault.sh"
fi

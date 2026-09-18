#!/usr/bin/env bash
set -euo pipefail

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
  echo "npm install $r"
  (
    cd "$ROOT/$r"
    if [ -f package-lock.json ]; then
      npm ci || npm install --legacy-peer-deps
    else
      npm install --legacy-peer-deps
    fi
  )
done

if [ -x "$DEV/scripts/cloud-e2e/install-obsidian.sh" ]; then
  bash "$DEV/scripts/cloud-e2e/install-obsidian.sh"
  bash "$DEV/scripts/cloud-e2e/materialize-vault.sh"
fi

for r in obsidian-agent-client obsidian-seek whisper-obsidian-plugin; do
  echo "npm run build $r"
  (cd "$ROOT/$r" && npm run build)
done

if [ -x "$DEV/scripts/cloud-e2e/materialize-vault.sh" ]; then
  bash "$DEV/scripts/cloud-e2e/materialize-vault.sh"
fi

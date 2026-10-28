#!/usr/bin/env bash
set -euo pipefail

# Prefer a newer Node from nvm when present (jsdom/undici engine floors).
if [ -x "$HOME/.nvm/versions/node/v22.22.2/bin/node" ]; then
  export PATH="$HOME/.nvm/versions/node/v22.22.2/bin:$PATH"
fi

ROOT=""
if [ -n "${CLOUD_E2E_REPOS:-}" ] && [ -d "${CLOUD_E2E_REPOS}/obsidian-seek" ]; then
  ROOT=$CLOUD_E2E_REPOS
elif [ -d /agent/repos/obsidian-seek ]; then
  ROOT=/agent/repos
elif [ -d "$HOME/repos/obsidian-seek" ]; then
  ROOT=$HOME/repos
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

for r in obsidian-agent-client obsidian-seek whisper-obsidian-plugin obsidian-book-search-plugin; do
  if [ ! -d "$ROOT/$r" ]; then
    if [ "$r" = obsidian-book-search-plugin ]; then
      echo "skip $r (clone missing)"
      continue
    fi
    echo "missing required repo $r" >&2
    exit 1
  fi
  echo "install $r"
  if ! (
    cd "$ROOT/$r"
    if [ -f pnpm-lock.yaml ] && command -v pnpm >/dev/null 2>&1; then
      pnpm install --frozen-lockfile
    elif [ -f package-lock.json ]; then
      npm ci || npm install --legacy-peer-deps
    else
      npm install --legacy-peer-deps
    fi
  ); then
    if [ "$r" = obsidian-book-search-plugin ]; then
      echo "warn: optional install failed for $r; continuing" >&2
      continue
    fi
    exit 1
  fi
done

if [ -x "$DEV/scripts/cloud-e2e/install-acp-agents.sh" ]; then
  bash "$DEV/scripts/cloud-e2e/install-acp-agents.sh"
fi

if [ -x "$DEV/scripts/cloud-e2e/install-obsidian.sh" ]; then
  bash "$DEV/scripts/cloud-e2e/install-obsidian.sh"
  bash "$DEV/scripts/cloud-e2e/materialize-vault.sh"
fi

for r in obsidian-agent-client obsidian-seek whisper-obsidian-plugin obsidian-book-search-plugin; do
  if [ ! -d "$ROOT/$r" ]; then
    if [ "$r" = obsidian-book-search-plugin ]; then
      echo "skip build $r (clone missing)"
      continue
    fi
    echo "missing required repo $r" >&2
    exit 1
  fi
  echo "build $r"
  if ! (
    cd "$ROOT/$r"
    if [ -f pnpm-lock.yaml ] && command -v pnpm >/dev/null 2>&1; then
      pnpm run build
    else
      npm run build
    fi
  ); then
    if [ "$r" = obsidian-book-search-plugin ]; then
      echo "warn: optional build failed for $r; continuing" >&2
      continue
    fi
    exit 1
  fi
done

if [ -x "$DEV/scripts/cloud-e2e/materialize-vault.sh" ]; then
  bash "$DEV/scripts/cloud-e2e/materialize-vault.sh"
fi

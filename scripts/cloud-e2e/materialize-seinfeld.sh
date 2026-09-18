#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.env
source "$SCRIPT_DIR/paths.env"

VAULT="${CLOUD_E2E_VAULT:-$HOME/plugin-sandbox-Obsidian}"
DEST="$VAULT/Seinfeld/episodes"
CACHE="${CLOUD_E2E_SEINFELD_CACHE:-$HOME/.cache/cloud-e2e-seinfeld}"
REPO="${CLOUD_E2E_SEINFELD_REPO:-https://github.com/AI21Labs/multi-window-chunk-size.git}"
REF="${CLOUD_E2E_SEINFELD_REF:-master}"

mkdir -p "$DEST" "$CACHE"

if [ ! -d "$CACHE/.git" ]; then
  echo "Cloning Seinfeld trivia corpus (shallow)…"
  git clone --depth 1 --branch "$REF" "$REPO" "$CACHE"
else
  echo "Updating Seinfeld corpus cache…"
  git -C "$CACHE" fetch --depth 1 origin "$REF" 2>/dev/null || true
  git -C "$CACHE" checkout "$REF" 2>/dev/null || true
  git -C "$CACHE" pull --ff-only origin "$REF" 2>/dev/null || true
fi

SRC="$CACHE/seinfeld_trivia/documents_content"
if [ ! -d "$SRC" ]; then
  echo "Missing $SRC in AI21 repo" >&2
  exit 1
fi

cp -a "$SRC/." "$DEST/"
COUNT="$(find "$DEST" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
echo "Seinfeld episodes materialized: $COUNT files under $DEST"

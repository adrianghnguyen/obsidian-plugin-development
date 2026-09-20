#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.env
source "$SCRIPT_DIR/paths.env"

VAULT="${CLOUD_E2E_VAULT:-$HOME/plugin-sandbox-Obsidian}"
SEEK="${CLOUD_E2E_REPOS}/obsidian-seek"
EPISODES="$VAULT/Seinfeld (custom)/episodes"
LIMIT="${SEINFELD_SMOKE_LIMIT:-8}"

if [ ! -d "$EPISODES" ] || [ -z "$(find "$EPISODES" -maxdepth 1 -name '*.md' 2>/dev/null | head -1)" ]; then
  echo "Seinfeld corpus missing; running materialize-seinfeld.sh…" >&2
  bash "$SCRIPT_DIR/materialize-seinfeld.sh"
fi

export SEINFELD_EPISODES_DIR="$EPISODES"
export SEINFELD_SMOKE_LIMIT="$LIMIT"
export SEINFELD_EVAL_JSON="$SCRIPT_DIR/fixtures/seinfeld-eval.json"

TMP="$SEEK/.tmp-seinfeld-seek-smoke.test.ts"
cp "$SCRIPT_DIR/seinfeld-seek-smoke.test.ts" "$TMP"
trap 'rm -f "$TMP"' EXIT

cd "$SEEK"
npx vitest run "$TMP"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.env
source "$SCRIPT_DIR/paths.env"

VAULT="$CLOUD_E2E_VAULT"
FIXTURES="$SCRIPT_DIR/fixtures/vault"
REPOS="$CLOUD_E2E_REPOS"

mkdir -p "$VAULT/.obsidian/plugins" "$VAULT/Notes" "$VAULT/Attachments"

# Portable copy (Cloud VMs may lack rsync).
cp -a "$FIXTURES/." "$VAULT/"

copy_plugin() {
  local id="$1"
  local src="$2"
  local dest="$VAULT/.obsidian/plugins/$id"
  mkdir -p "$dest"
  for f in main.js manifest.json styles.css; do
    if [ -f "$src/$f" ]; then
      cp -f "$src/$f" "$dest/$f"
    fi
  done
}

copy_plugin seek "$REPOS/obsidian-seek"
copy_plugin whisper "$REPOS/whisper-obsidian-plugin"
copy_plugin agent-client "$REPOS/obsidian-agent-client"

if command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg -nostdin -hide_banner -loglevel error -y -f lavfi -i anullsrc=r=16000:cl=mono -t 1 "$VAULT/Attachments/synthetic-silence.wav" || true
fi

if [ -x "$SCRIPT_DIR/materialize-seinfeld.sh" ]; then
  bash "$SCRIPT_DIR/materialize-seinfeld.sh"
fi

echo "Vault materialized at $VAULT"
find "$VAULT/.obsidian/plugins" -maxdepth 2 -type f | sort

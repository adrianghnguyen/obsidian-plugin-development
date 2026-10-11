#!/usr/bin/env bash
# Real Needle WASM batch transcribe on a voice clip (not Vitest, not Obsidian UI).
# First run downloads ~17 MB from Hugging Face into WHISTLE_CACHE_DIR.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.env
source "$SCRIPT_DIR/paths.env"

WHISPER="${CLOUD_E2E_REPOS}/whisper-obsidian-plugin"
export WHISTLE_CACHE_DIR="${WHISTLE_CACHE_DIR:-$HOME/.whistle-smoke-cache}"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is required for Whistle smoke (decode audio to 16 kHz PCM)." >&2
  exit 1
fi

if [ ! -d "$WHISPER" ]; then
  echo "Whisper repo not found at $WHISPER (set CLOUD_E2E_REPOS)." >&2
  exit 1
fi

AUDIO="${1:-}"
if [ -n "$AUDIO" ]; then
  cd "$WHISPER"
  exec npm run smoke:whistle -- "$AUDIO"
fi

cd "$WHISPER"
exec npm run smoke:whistle

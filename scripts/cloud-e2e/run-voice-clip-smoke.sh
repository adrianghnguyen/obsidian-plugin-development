#!/usr/bin/env bash
# Run a plugin's offline voice-clip smoke (real audio in, transcript or equivalent out).
# Shared sandbox clip: fixtures/voice/smoke-hello.wav → vault Attachments/voice-smoke-hello.wav
#
# Usage:
#   run-voice-clip-smoke.sh <plugin-key> [path-to-audio]
#
# Registered keys: see voice-clip-smokes.sh (add one block per plugin).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.env
source "$SCRIPT_DIR/paths.env"
# shellcheck source=voice-clip-smokes.sh
source "$SCRIPT_DIR/voice-clip-smokes.sh"

PLUGIN="${1:-}"
if [ -z "$PLUGIN" ]; then
  echo "Usage: run-voice-clip-smoke.sh <plugin-key> [path-to-audio]" >&2
  echo "Registered keys: ${VOICE_CLIP_SMOKE_KEYS[*]}" >&2
  exit 1
fi

DEFAULT_CLIP="$SCRIPT_DIR/fixtures/voice/smoke-hello.wav"
export CLOUD_E2E_VOICE_CLIP="${CLOUD_E2E_VOICE_CLIP:-$DEFAULT_CLIP}"

AUDIO="${2:-$CLOUD_E2E_VOICE_CLIP}"
if [ ! -f "$AUDIO" ]; then
  echo "Voice clip not found: $AUDIO" >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg is required for voice-clip smokes (decode to PCM)." >&2
  exit 1
fi

voice_clip_smoke_run "$PLUGIN" "$AUDIO"

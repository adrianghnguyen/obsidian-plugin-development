#!/usr/bin/env bash
# Registry of voice-clip smoke runners (one entry per plugin / STT backend).
# Sourced by run-voice-clip-smoke.sh — do not execute directly.

VOICE_CLIP_SMOKE_KEYS=(whistle)

voice_clip_smoke_run() {
  local plugin="$1"
  local audio="$2"
  local repo

  case "$plugin" in
    whistle)
      repo="${CLOUD_E2E_REPOS}/whisper-obsidian-plugin"
      if [ ! -d "$repo" ]; then
        echo "Repo not found: $repo" >&2
        return 1
      fi
      export WHISTLE_CACHE_DIR="${WHISTLE_CACHE_DIR:-$HOME/.whistle-smoke-cache}"
      (
        cd "$repo"
        npm run smoke:voice-clip -- "$audio"
      )
      ;;
    *)
      echo "Unknown plugin key: $plugin" >&2
      echo "Registered: ${VOICE_CLIP_SMOKE_KEYS[*]}" >&2
      return 1
      ;;
  esac
}

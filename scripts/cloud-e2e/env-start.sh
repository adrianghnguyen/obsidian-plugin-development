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
  ROOT="$PWD"
fi
export CLOUD_E2E_REPOS="$ROOT"
DEV="$ROOT/obsidian-plugin-development"
START="$DEV/scripts/cloud-e2e/start-obsidian.sh"
CDP="$DEV/scripts/cloud-e2e/cdp.mjs"
PORT="${CLOUD_E2E_CDP_PORT:-9222}"

if [ ! -x "$START" ]; then
  echo "cloud-e2e start script missing; skip Obsidian (unit tests still work)."
  exit 0
fi

export DISPLAY="${DISPLAY:-:99}"
if ! command -v xdpyinfo >/dev/null 2>&1 || ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
  Xvfb "$DISPLAY" -screen 0 1920x1080x24 >/tmp/cloud-e2e-xvfb.log 2>&1 &
  echo $! > /tmp/cloud-e2e-xvfb.pid
  sleep 0.4
fi

if ! curl -sf -m 1 "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
  nohup bash "$START" >/tmp/cloud-e2e-obsidian.log 2>&1 &
  echo $! > /tmp/cloud-e2e-obsidian.pid
fi

for _ in $(seq 1 60); do
  if curl -sf -m 1 "http://127.0.0.1:${PORT}/json/version" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# Starter.html often has a CDP page whose Runtime.evaluate never returns.
# Bound these so environment `start` always terminates.
if [ -f "$CDP" ]; then
  timeout 12 node "$CDP" dismiss-starter || echo "dismiss-starter skipped-or-timed-out"
  timeout 20 node "$CDP" enable-plugins || echo "enable-plugins skipped-or-timed-out"
  timeout 20 node "$CDP" inject || echo "inject skipped-or-timed-out"
  # Identity gate: ensure sandbox vault is open (not Obsidian's empty default).
  identity="$(timeout 15 node "$CDP" eval 'JSON.stringify({name:app.vault.getName(),base:app.vault.adapter.basePath,plugins:Object.keys(app.plugins.plugins)})' 2>/dev/null || true)"
  echo "cloud-e2e-identity: ${identity:-unavailable}"
  if [ -n "$identity" ] && ! echo "$identity" | grep -q 'plugin-sandbox-Obsidian'; then
    echo "WARNING: expected vault plugin-sandbox-Obsidian; got $identity" >&2
  fi
fi

echo "cloud-e2e-start-ok"

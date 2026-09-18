#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.env
source "$SCRIPT_DIR/paths.env"

BIN="${CLOUD_E2E_OBSIDIAN_BIN:-$CLOUD_E2E_OBSIDIAN_ROOT/squashfs-root/obsidian}"
if [ ! -x "$BIN" ]; then
  echo "Obsidian binary missing. Run install-obsidian.sh first: $BIN" >&2
  exit 1
fi

mkdir -p "$CLOUD_E2E_PROFILE" "$CLOUD_E2E_VAULT"

# Isolated profile so Cloud E2E never touches a personal Obsidian config.
# Merge vault path; do not wipe a profile that already completed first-run.
python3 - "$CLOUD_E2E_PROFILE" "$CLOUD_E2E_VAULT" <<'PY'
import json, os, sys, time
profile, vault = sys.argv[1], sys.argv[2]
os.makedirs(profile, exist_ok=True)
cfg = os.path.join(profile, "obsidian.json")
data = {}
if os.path.isfile(cfg):
    try:
        with open(cfg, encoding="utf-8") as f:
            data = json.load(f) or {}
    except json.JSONDecodeError:
        data = {}
vaults = data.setdefault("vaults", {})
known = any(isinstance(v, dict) and v.get("path") == vault for v in vaults.values())
if not known:
    vaults["cloud-e2e"] = {"path": vault, "ts": int(time.time() * 1000)}
with open(cfg, "w", encoding="utf-8") as f:
    json.dump(data, f)
PY

export DISPLAY="${DISPLAY:-:99}"
if ! command -v xdpyinfo >/dev/null 2>&1 || ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
  Xvfb "$DISPLAY" -screen 0 1920x1080x24 >/tmp/cloud-e2e-xvfb.log 2>&1 &
  echo $! > /tmp/cloud-e2e-xvfb.pid
  sleep 0.4
fi

# Chromium basic password store: ephemeral profile, no gnome-keyring required.
# --no-sandbox is required in many Cloud Agent containers.
exec "$BIN" \
  --no-sandbox \
  --disable-gpu \
  --disable-dev-shm-usage \
  --password-store=basic \
  --remote-debugging-port="$CLOUD_E2E_CDP_PORT" \
  --user-data-dir="$CLOUD_E2E_PROFILE" \
  "$CLOUD_E2E_VAULT"

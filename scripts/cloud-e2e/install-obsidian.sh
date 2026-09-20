#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=paths.env
source "$SCRIPT_DIR/paths.env"

VERSION="$CLOUD_E2E_OBSIDIAN_VERSION"
ROOT="$CLOUD_E2E_OBSIDIAN_ROOT"
IMG="$ROOT/Obsidian-${VERSION}.AppImage"
URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${VERSION}/Obsidian-${VERSION}.AppImage"

mkdir -p "$ROOT"
if [ ! -f "$IMG" ]; then
  echo "Downloading Obsidian ${VERSION} AppImage…"
  curl -fL --retry 4 --retry-delay 4 -o "$IMG.partial" "$URL"
  mv "$IMG.partial" "$IMG"
  chmod +x "$IMG"
fi

if [ ! -x "$ROOT/squashfs-root/obsidian" ]; then
  echo "Extracting AppImage (no FUSE)…"
  (
    cd "$ROOT"
    rm -rf squashfs-root
    "$IMG" --appimage-extract
  )
fi

mkdir -p "$HOME/.local/bin"
ln -sfn "$ROOT/squashfs-root/obsidian" "$HOME/.local/bin/obsidian-app"
if [ -x "$ROOT/squashfs-root/obsidian-cli" ]; then
  ln -sfn "$ROOT/squashfs-root/obsidian-cli" "$HOME/.local/bin/obsidian"
fi
echo "Obsidian binary: $ROOT/squashfs-root/obsidian"
file "$ROOT/squashfs-root/obsidian"

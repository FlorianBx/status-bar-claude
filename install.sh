#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { printf "${GREEN}✓${NC} %s\n" "$1"; }
err()  { printf "${RED}✗${NC} %s\n" "$1" >&2; }
warn() { printf "${YELLOW}!${NC} %s\n" "$1"; }

install_pkg() {
  local pkg=$1
  if command -v apt &>/dev/null; then
    sudo apt update && sudo apt install -y "$pkg"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$pkg"
  elif command -v yum &>/dev/null; then
    sudo yum install -y "$pkg"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$pkg"
  elif command -v apk &>/dev/null; then
    sudo apk add "$pkg"
  elif command -v brew &>/dev/null; then
    brew install "$pkg"
  else
    err "No supported package manager found. Install $pkg manually."
    exit 1
  fi
}

for dep in jq git bash; do
  if ! command -v "$dep" &>/dev/null; then
    warn "Missing: $dep — attempting to install..."
    install_pkg "$dep"
    if ! command -v "$dep" &>/dev/null; then
      err "Failed to install $dep. Install it manually."
      exit 1
    fi
    ok "Installed $dep"
  fi
done
ok "All dependencies found"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="$SCRIPT_DIR/statusline-command.sh"
DEST_DIR="$HOME/.claude"
DEST="$DEST_DIR/statusline-command.sh"
SETTINGS="$DEST_DIR/settings.json"

if [[ ! -f "$SOURCE" ]]; then
    err "statusline-command.sh not found in $SCRIPT_DIR"
    exit 1
fi

mkdir -p "$DEST_DIR"
cp "$SOURCE" "$DEST"
chmod +x "$DEST"
ok "Installed $DEST"

if [[ ! -f "$SETTINGS" ]]; then
    echo '{}' > "$SETTINGS"
    warn "Created $SETTINGS"
fi

UPDATED="$(jq '. + {"statusLine": {"type": "command", "command": "bash ~/.claude/statusline-command.sh"}}' "$SETTINGS")"
echo "$UPDATED" > "$SETTINGS"
ok "Updated $SETTINGS"

printf "\n${GREEN}Installation complete.${NC} Restart Claude Code to activate the status bar.\n"

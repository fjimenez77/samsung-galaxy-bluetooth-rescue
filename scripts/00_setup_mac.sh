#!/usr/bin/env bash
# 00_setup_mac.sh — Phase 0: install/verify the tools needed for diagnosis.
source "$(dirname "$0")/lib.sh"

c_bold "== Phase 0: Mac setup =="

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  c_yellow "Homebrew not found."
  echo "Install it from https://brew.sh then re-run this script:"
  echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi
c_green "Homebrew present: $(brew --version | head -1)"

# android-platform-tools (adb)
if ! command -v adb >/dev/null 2>&1; then
  c_yellow "Installing android-platform-tools (provides adb)..."
  brew install android-platform-tools
else
  c_green "adb present: $(adb --version | head -1)"
fi

echo
c_bold "Tools for the LAST-RESORT rollback (NOT installed automatically):"
echo "  - Firmware downloader: samloader (Python) or samfirm.js (Node)"
echo "  - Flasher: Heimdall ('brew install heimdall', macOS, unreliable) or"
echo "             Odin (Windows, recommended). See notes/rollback-guide.md."
echo
c_green "Setup check complete. Next: scripts/01_connect_check.sh"

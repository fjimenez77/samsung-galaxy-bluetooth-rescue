#!/usr/bin/env bash
# lib.sh — shared helpers for the Z Fold 5 rescue scripts.
# Source this from the other scripts:  source "$(dirname "$0")/lib.sh"

set -uo pipefail

LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/logs"
mkdir -p "$LOG_DIR"

c_red()   { printf '\033[31m%s\033[0m\n' "$*"; }
c_green() { printf '\033[32m%s\033[0m\n' "$*"; }
c_yellow(){ printf '\033[33m%s\033[0m\n' "$*"; }
c_bold()  { printf '\033[1m%s\033[0m\n'  "$*"; }

need_adb() {
  if ! command -v adb >/dev/null 2>&1; then
    c_red "adb not found. Run scripts/00_setup_mac.sh first."
    exit 1
  fi
}

# Ensure exactly one authorized device is connected.
need_device() {
  need_adb
  adb start-server >/dev/null 2>&1
  local state
  state="$(adb get-state 2>/dev/null || true)"
  if [ "$state" != "device" ]; then
    c_red "No authorized device detected (adb state: '${state:-none}')."
    c_yellow "Checklist:"
    echo "  1. USB cable connected (try a different cable/port if flaky)."
    echo "  2. On phone: Settings > About phone > Software info >"
    echo "     tap 'Build number' 7x to unlock Developer options."
    echo "  3. Settings > Developer options > enable 'USB debugging'."
    echo "  4. Re-plug, then tap 'Allow' on the RSA prompt on the phone."
    echo "  5. If it shows 'unauthorized', accept that prompt and re-run."
    exit 1
  fi
  c_green "Device connected and authorized."
}

confirm() {
  # confirm "Question?"  -> returns 0 if user types y/Y
  local prompt="${1:-Are you sure?}"
  read -r -p "$prompt [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

stamp() { date +"%Y%m%d-%H%M%S"; }

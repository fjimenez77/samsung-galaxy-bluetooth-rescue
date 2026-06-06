#!/usr/bin/env bash
# 02_capture_logcat.sh — Phase 3: capture a Bluetooth logcat while the user
# toggles Bluetooth, to see WHY the stack drops or the address is missing.
source "$(dirname "$0")/lib.sh"

c_bold "== Phase 3: Bluetooth logcat capture =="
need_device

OUT="$LOG_DIR/bt-logcat-$(stamp).txt"

echo "Clearing the log buffer..."
adb logcat -c

c_yellow "ACTION REQUIRED:"
echo "  In ~3 seconds, capture starts. On the phone, toggle Bluetooth"
echo "  OFF then ON a couple of times, and try a pairing if you can."
echo "  Press Ctrl+C here when done (about 20-30 seconds is plenty)."
sleep 3

c_green "Capturing... (Ctrl+C to stop)"
# Capture broadly, then we keep BT-relevant lines too. Trap Ctrl+C to finish cleanly.
trap 'echo; c_green "Stopped."' INT
adb logcat -v time \
  | grep --line-buffered -iE "bluetooth|bt_|btif|hci|bta_|gatt|a2dp|avrcp|stack" \
  | tee "$OUT"
trap - INT

echo
c_green "Saved Bluetooth log to: $OUT"
echo "Also grab the adapter dump for the address/state:"
echo "  adb shell dumpsys bluetooth_manager | tee \"$LOG_DIR/dumpsys-$(stamp).txt\""
echo
c_yellow "Interpreting: look for repeated crashes/aborts in the BT stack, or"
echo "'address 00:00:00:00:00:00' / 'read address failed' — that points to a"
echo "radio/EFS problem rather than a fixable software glitch."

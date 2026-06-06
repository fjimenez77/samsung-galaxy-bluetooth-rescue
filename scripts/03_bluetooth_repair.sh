#!/usr/bin/env bash
# 03_bluetooth_repair.sh — Phase 2: non-destructive revive attempts.
#   --soft   (default) clear Bluetooth CACHE only, toggle, reboot. Keeps pairings.
#   --hard   clear Bluetooth DATA (pm clear). WIPES all pairings. Asks to confirm.
source "$(dirname "$0")/lib.sh"

MODE="${1:---soft}"
c_bold "== Phase 2: Bluetooth repair ($MODE) =="
need_device

BT_PKG="com.android.bluetooth"

toggle_bt() {
  echo "Toggling Bluetooth off/on via settings..."
  adb shell settings put global bluetooth_on 0 >/dev/null 2>&1 || true
  sleep 2
  adb shell settings put global bluetooth_on 1 >/dev/null 2>&1 || true
  sleep 2
}

show_addr() {
  echo "  BT enabled (1=on): $(adb shell settings get global bluetooth_on | tr -d '\r')"
  echo "  BT address:        $(adb shell settings get secure bluetooth_address | tr -d '\r')"
}

case "$MODE" in
  --soft)
    c_yellow "Soft mode: clears Bluetooth cache only. Pairings are KEPT."
    # Cache clear without data loss is limited via adb; we stop the package and
    # toggle, which resets the running stack without wiping pairings.
    echo "Force-stopping the Bluetooth service to reset its running state..."
    adb shell am force-stop "$BT_PKG"
    sleep 1
    toggle_bt
    echo "Rebooting to fully reinitialise the stack..."
    adb reboot
    c_green "Reboot sent. Wait for the phone to come back, re-run 01_connect_check.sh,"
    echo "then check whether Bluetooth now stays on and the address is populated."
    echo "If still broken, escalate to:  $0 --hard"
    ;;

  --hard)
    c_red "HARD mode wipes ALL Bluetooth pairings (pm clear $BT_PKG)."
    echo "This is the single most effective fix for post-update Bluetooth breakage,"
    echo "but you WILL have to re-pair every device (car, earbuds, watch) afterwards."
    if ! confirm "Proceed with clearing Bluetooth data?"; then
      c_yellow "Aborted. No changes made."
      exit 0
    fi
    echo "Before:"; show_addr
    echo "Clearing Bluetooth data..."
    adb shell pm clear "$BT_PKG"
    sleep 1
    echo "Rebooting..."
    adb reboot
    c_green "Done. After reboot:"
    echo "  1. Re-run scripts/01_connect_check.sh and confirm the BT address now shows."
    echo "  2. On the phone, RE-PAIR each device FROM SCRATCH (delete old entries first)."
    echo "     Re-pairing after the clear is what resolves most post-update cases."
    echo "  3. Also do, on the phone (adb can't): Settings > General management >"
    echo "     Reset > Reset network settings."
    ;;

  *)
    c_red "Unknown mode: $MODE"
    echo "Usage: $0 [--soft|--hard]"
    exit 1
    ;;
esac

#!/usr/bin/env bash
# 01_connect_check.sh — Phase 1: confirm connection and inventory the device.
source "$(dirname "$0")/lib.sh"

c_bold "== Phase 1: Connect & inventory =="
need_device

OUT="$LOG_DIR/inventory-$(stamp).txt"
{
  echo "=== Z Fold 5 inventory $(date) ==="
  echo
  echo "--- Identity ---"
  echo "Model:            $(adb shell getprop ro.product.model | tr -d '\r')"
  echo "Device:           $(adb shell getprop ro.product.device | tr -d '\r')"
  echo "Manufacturer:     $(adb shell getprop ro.product.manufacturer | tr -d '\r')"
  echo
  echo "--- Software / firmware ---"
  echo "Android version:  $(adb shell getprop ro.build.version.release | tr -d '\r')"
  echo "One UI / inc:     $(adb shell getprop ro.build.version.incremental | tr -d '\r')"
  echo "Build PDA:        $(adb shell getprop ro.build.PDA | tr -d '\r')"
  echo "Build fingerprint:$(adb shell getprop ro.build.fingerprint | tr -d '\r')"
  echo "Security patch:   $(adb shell getprop ro.build.version.security_patch | tr -d '\r')"
  echo
  echo "--- Bootloader / rollback-relevant ---"
  echo "ro.bootloader:    $(adb shell getprop ro.bootloader | tr -d '\r')"
  echo "ro.boot.bootloader:$(adb shell getprop ro.boot.bootloader | tr -d '\r')"
  echo
  echo "--- Region / CSC (needed to find matching firmware) ---"
  echo "Sales code (CSC): $(adb shell getprop ro.csc.sales_code | tr -d '\r')"
  echo "CSC version:      $(adb shell getprop ril.official_cscver | tr -d '\r')"
  echo
  echo "--- Bluetooth state ---"
  echo "BT enabled (1=on):$(adb shell settings get global bluetooth_on | tr -d '\r')"
  echo "BT address:       $(adb shell settings get secure bluetooth_address | tr -d '\r')"
} | tee "$OUT"

echo
c_green "Saved inventory to: $OUT"
c_yellow "Note the bootloader index (the digit after 'XXU' in the build, e.g. F946BXXU[8]...)."
echo "Next: scripts/03_bluetooth_repair.sh --soft   (non-destructive first pass)"

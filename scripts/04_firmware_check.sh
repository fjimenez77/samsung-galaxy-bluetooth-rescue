#!/usr/bin/env bash
# 04_firmware_check.sh — Phase 4: NON-destructive rollback feasibility check.
# Reads firmware + bootloader index and explains whether a downgrade is allowed.
source "$(dirname "$0")/lib.sh"

c_bold "== Phase 4: Rollback feasibility (read-only) =="
need_device

MODEL="$(adb shell getprop ro.product.model | tr -d '\r')"
INC="$(adb shell getprop ro.build.version.incremental | tr -d '\r')"
PDA="$(adb shell getprop ro.build.PDA | tr -d '\r')"
BL="$(adb shell getprop ro.bootloader | tr -d '\r')"
CSC="$(adb shell getprop ro.csc.sales_code | tr -d '\r')"
ANDROID="$(adb shell getprop ro.build.version.release | tr -d '\r')"

echo "Model:           $MODEL"
echo "Android:         $ANDROID"
echo "Build (inc):     $INC"
echo "Build PDA:       $PDA"
echo "Bootloader:      $BL"
echo "CSC (region):    $CSC"
echo

# The bootloader index is the single digit immediately BEFORE the trailing
# 4-char OS/date block (<OSgen><year><month><minor>), i.e. the 5th char from the
# end of the build code. This is robust for both formats:
#   F946BXXU[8]DXK1 -> 8   and   F946U1UES[8]GZE8 -> 8
# (The old regex '[US][0-9]' wrongly matched the 'U1' in the model name F946U1.)
SRC="${PDA:-$BL}"
IDX="${SRC: -5:1}"
printf '%s' "$IDX" | grep -qE '^[0-9]$' || IDX=""
if [ -n "${IDX:-}" ]; then
  c_bold "Detected bootloader index: $IDX"
else
  c_yellow "Could not auto-detect the bootloader index from '$PDA' / '$BL'."
  echo "Read it manually: it's the digit after 'U'/'S' in the build code"
  echo "(e.g. F946BXXU[8]B... = index 8)."
fi

cat <<EOF

--- What this means (ANTI-ROLLBACK / ARB) ---
Samsung enforces a one-way bootloader counter. You may ONLY flash a firmware
whose bootloader index is GREATER THAN OR EQUAL TO the current one ($IDX).

  * To roll back OFF One UI 8.5, you need an older Fold 5 build that still
    carries bootloader index $IDX (or higher). If 8.5 bumped the index, every
    pre-8.5 build will be BLOCKED and Odin/Heimdall will fail. No tool bypasses
    this on a locked Samsung bootloader.

--- Your search target for an older build ---
  Model:  $MODEL
  CSC:    $CSC
  Want:   a pre-8.5 build for this model+CSC with bootloader index >= $IDX

Use samloader / samfirm.js to list available builds for $MODEL / $CSC and
compare their bootloader index to $IDX. Steps: notes/rollback-guide.md.

--- Decision ---
  If a compatible older build exists  -> rollback is POSSIBLE (last resort,
      back up first, brick risk). Proceed per notes/rollback-guide.md.
  If only higher-index builds exist   -> rollback is BLOCKED. If Bluetooth is
      still dead and the address is "Unavailable", treat as a likely hardware/
      EFS fault and book a Samsung service centre.
EOF

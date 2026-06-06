# Same-Version Reflash — the recommended next step

**Device:** SM-F946U1 (Z Fold 5, US unlocked) · CSC **ATT** (multi-CSC OYM)
**Current/target build:** **F946U1UES8GZE8** (Android 16 / One UI 8.5) · bootloader index **8**

## Why this, not a rollback
Every adb-reachable software fix failed (soft reboot, wipe cache, network reset, `pm clear`).
The Bluetooth **controller fails to initialize at the firmware/HAL layer** (`vendor.bluetooth_init_fail`
keeps climbing; vendor HAL crash-loops; Wi-Fi on the same chip works). The most likely fixable cause
is a **corrupted BT firmware/vendor partition from the One UI 8.5 OTA**. Re-flashing the **same build**
reinstalls BL/AP/CP/CSC — including the vendor + firmware partitions — cleanly.

- **ARB-safe:** same build = bootloader index 8 = no anti-rollback gate (you are not downgrading).
- **Strictly better than a rollback here:** rollback is ARB-risky (needs a pre-8.5 build with index ≥ 8),
  usually force-wipes, and per CLAUDE.md §5.5 may not fix a radio/NV fault anyway.
- **It is also the decisive hardware test:** if a clean same-version flash does NOT restore BT, the
  fault is the BT core of the WCN "hastings" combo chip → Samsung service centre.

> ⚠️ adb CANNOT flash (hard constraint). This is a manual Odin/Heimdall step. A failed/interrupted
> flash can hard-brick. Device is already backed up — keep it that way.

## Tooling — you are on a Mac
- **Strongly preferred:** a **Windows PC + Odin** (most reliable for Samsung Folds). Borrow/dual-boot one.
- **Mac-only fallback:** **Heimdall** (`brew install heimdall`) — fiddly and unreliable on recent Folds;
  higher brick risk. Use only if no Windows machine is reachable.

## 1. Download the firmware — DO THIS ON WINDOWS (reliable)
Confirmed target build for this device (verified against Samsung's servers 2026-06-06):
```
Model:  SM-F946U1     Region/CSC: ATT
PDA (AP):  F946U1UES8GZE8
CSC:       F946U1OYM8GZE8     (multi-CSC; gives you the HOME_CSC + CSC files)
MODEM(CP): F946U1UES8GZE8
```

**Recommended — Frija (Windows GUI):** download Frija, enter Model `SM-F946U1` + Region `ATT`
(or use auto), click Check Update → it should show **F946U1UES8GZE8**, then Download. It fetches
and decrypts to a single firmware .zip. (Alternative Windows GUI: "Samsung Firmware Downloader".)

Unzip the result → you get **BL_*, AP_*, CP_*, CSC_*** and **HOME_CSC_*** `.tar.md5` files.

> NOTE: the Mac downloaders (`samfirm`, `samloader`) were tried 2026-06-06 and FAIL on the
> current Node 24 / OpenSSL 3 / Python 3.14 toolchain (samfirm reached Samsung and confirmed the
> build above, then crashed with `ERR_OSSL_BAD_DECRYPT` on auth-nonce rotation). Use Frija on
> Windows instead — don't burn time on the Mac downloaders.

## 2. Enter Download (Odin) mode
1. Power the phone **off**.
2. Hold **Volume Up + Volume Down together**, then plug the USB cable in while holding.
3. At the warning screen, press **Volume Up** to enter Download mode.

## 3. Flash (Odin, Windows)
1. Open Odin; confirm a blue/added ID:COM box appears (device detected).
2. Load files into slots: **BL→BL, AP→AP, CP→CP**, and for CSC:
   - **Try `HOME_CSC` first** — reinstalls partitions while *keeping your data*. Since this is a
     same-version flash, HOME_CSC should not force a wipe — best first attempt.
   - If BT is still dead after that, redo the flash with the **plain `CSC`** file (this **wipes**
     the device) for a fully clean partition set.
3. **Options:** leave **Re-Partition unchecked**.
4. Press **Start**. Do **not** touch the cable until it shows **PASS** and the phone reboots.

Heimdall (Mac) equivalent: unzip the tar.md5 files, `heimdall print-pit` to get partition names,
then `heimdall flash --BL ... --AP ... --CP ... --CSC ...`. Expect trial-and-error.

## 4. After the flash
1. First boot can take 5–15 min — leave it alone.
2. Reconnect USB, re-run `scripts/01_connect_check.sh`, then check the controller:
   ```
   adb shell getprop vendor.bluetooth_init_fail        # want: 0 (and not climbing)
   adb shell dumpsys bluetooth_manager | head -6       # want: enabled: true / state: ON / real address
   ```
3. **If BT now initializes and stays on → fixed.** Then **disable auto-update** for One UI until
   Samsung ships a corrected build, so the bad OTA doesn't reapply.
4. **If `init_fail` still climbs and the address stays Unavailable after the HOME_CSC flash**,
   repeat with the full **CSC (wipe)** flash. If it *still* fails → **BT-core hardware fault** →
   Samsung service centre (bring `logs/FINDINGS.md`).

## 5. If it bricks
- Re-enter Download mode and re-flash the **same/current** official build (always ARB-allowed).
  This recovers most soft-bricks.
- If it won't enter Download mode at all → hard-brick → Samsung service.

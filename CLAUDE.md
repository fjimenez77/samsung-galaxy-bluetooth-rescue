# CLAUDE.md — Galaxy Z Fold 5 Bluetooth Rescue

This file is your operating context. Read it fully before running anything.
You are helping the user diagnose and (if possible) repair Bluetooth on a
**Samsung Galaxy Z Fold 5**, connected to this Mac over USB via `adb`.

---

## 1. The situation

- **Device:** Samsung Galaxy Z Fold 5 (model family `SM-F946x`).
- **Symptoms reported by user:**
  - Bluetooth, when toggled ON, does **not stay on**.
  - Under **Settings → About phone → Status**, the **Bluetooth address** reads
    **"Unavailable"** (no MAC shown).
  - User states it **worked fine before** and broke after the **One UI 8.5**
    update — i.e. a suspected firmware regression (a real, widely-reported
    pattern on Z Fold devices).
- **Goal, in priority order:**
  1. **Revive Bluetooth non-destructively** (cache/data clears, re-pair, resets).
  2. If that fails, **diagnose** whether this is software or a dead/uninitialised
     radio (the "Unavailable" address is the key tell).
  3. **Only as a last resort**, assess and prepare a **firmware rollback** off
     One UI 8.5 — see hard constraints in §5.

---

## 2. Operating principles (read these — they are guardrails)

- **Never flash firmware through `adb`.** It cannot, and pretending it can will
  brick the device. Firmware flashing is an external manual step (Odin/Heimdall).
  Your job for rollback is **feasibility + preparation only**.
- **Do not root the device.** Rooting trips Samsung Knox, voids warranty, and is
  unnecessary for everything in Phases 1–4.
- **Back up before anything destructive.** `pm clear` wipes Bluetooth pairings;
  a factory reset or flash wipes everything. Confirm the user has backed up.
- **Always confirm with the user before a destructive step.** Pausing to ask is
  correct behaviour, not a failure.
- **Work the phases in order.** Do not jump to rollback. Most of these cases are
  fixed in Phase 2–3 by clearing Bluetooth data and re-pairing from scratch.
- **Capture evidence as you go.** Save logs to `./logs/` so we can compare and
  so the user has something to show a service centre if it's hardware.

---

## 3. Tools needed on the Mac

Run `scripts/00_setup_mac.sh` to install/verify. Summary:

| Tool | Purpose | Install |
|------|---------|---------|
| Homebrew | package manager | https://brew.sh |
| `android-platform-tools` | provides `adb` (connect, diagnose, repair) | `brew install android-platform-tools` |
| (rollback only) firmware downloader | pull an older Fold 5 build | `samloader` (Python) or `samfirm.js` (Node) — see `notes/rollback-guide.md` |
| (rollback only) `heimdall` | flash firmware on macOS (flaky; Windows+Odin preferred) | `brew install heimdall` — verify current availability |

`adb` is the only tool needed for Phases 1–4. The rest are for the
last-resort rollback and are documented in the notes, not auto-installed.

---

## 4. The phased plan

### Phase 0 — Setup
`scripts/00_setup_mac.sh` → install/verify Homebrew + `adb`.

### Phase 1 — Connect & inventory
`scripts/01_connect_check.sh`
- Confirm the phone shows under `adb devices` (user must enable Developer
  options → USB debugging, and tap "Allow" on the phone).
- Record model, Android/One UI build, firmware string, bootloader index, CSC.
- Pull the current Bluetooth state and the "Bluetooth address" value.

### Phase 2 — Non-destructive revive
`scripts/03_bluetooth_repair.sh` (run with `--soft` first)
- Clear Bluetooth **cache** then **data** (`pm clear com.android.bluetooth`)
  — this is the single most effective fix and removes all pairings.
- Toggle the radio, reboot, re-check the Bluetooth address.
- **STOP and tell the user to re-pair every device from scratch** — re-pairing
  after the clear is what resolves most post-update cases.

### Phase 3 — Deeper revive (still non-destructive to user files)
- Capture a Bluetooth `logcat` while the user toggles BT: `scripts/02_capture_logcat.sh`.
- Read `dumpsys bluetooth_manager` for the adapter state and address.
- Interpret: **does the address populate after a clear+reboot, or stay
  "Unavailable"?** See decision tree §6.
- Suggest the user-side steps `adb` can't do: **Settings → General management →
  Reset → Reset network settings**, and a boot into **Safe mode** to rule out a
  third-party app.

### Phase 4 — Rollback feasibility check (NON-destructive)
`scripts/04_firmware_check.sh`
- Read the **bootloader index** (the bolded digit in e.g. `F946BXXU`**`8`**`...`).
- Explain the **anti-rollback (ARB)** rule: you can only flash a firmware whose
  bootloader index is **≥** the current one. If One UI 8.5 raised it, an older
  build is **blocked** and no tool gets around it.
- Output the exact model + CSC the user needs to search for a candidate older
  build, and state plainly whether rollback looks possible.

### Phase 5 — Rollback (EXTERNAL, manual, last resort)
- Do **not** attempt from here. Hand the user `notes/rollback-guide.md`, which
  covers downloading the firmware (samloader/samfirm.js) and flashing via
  Odin (Windows, preferred) or Heimdall (macOS, unreliable).
- Reiterate: back up first, downgrade often forces a wipe, a failed flash can
  hard-brick.

---

## 5. Hard constraints on rollback (do not let the user skip these)

1. **ARB gate:** if the current bootloader index > target firmware's, rollback
   is physically blocked. Check this FIRST (Phase 4) before downloading anything.
2. **`adb` cannot flash.** Flashing = Odin (Windows) or Heimdall (macOS).
3. **Data loss:** a downgrade typically wipes the device.
4. **Brick risk:** an interrupted/failed flash can permanently disable the phone.
5. **The "Unavailable" address may not be fixed by a downgrade** — if it's a
   corrupted/uninitialised radio (EFS) issue, a flash of a different OS version
   may not restore it. Weigh a service-centre visit against the brick risk.

---

## 6. Decision tree (use after Phase 2–3)

```
Did the Bluetooth address populate after clear-data + reboot + re-pair?
├─ YES, and BT now stays on .................... DONE. Stop. No rollback needed.
├─ YES address shows, but BT still drops ....... software/app conflict →
│                                                Safe mode test + network reset.
└─ NO, address still "Unavailable" ............. radio/EFS likely. Run Phase 4.
        │
        Is bootloader index of an older build ≥-compatible (ARB allows it)?
        ├─ YES ... rollback is *possible* → hand user notes/rollback-guide.md
        │          (last resort, back up, brick risk).
        └─ NO .... rollback BLOCKED → recommend Samsung service centre;
                   an "Unavailable" radio address is commonly a hardware/EFS fault.
```

---

## 7. Notes for you, Claude Code

- Prefer the provided scripts; they have safety checks. Read a script before
  running it so you can explain what it does.
- Everything in `scripts/` is non-destructive **except** `03_bluetooth_repair.sh`
  in `--hard` mode (clears data → wipes pairings). Always confirm first.
- Log everything to `./logs/` (scripts create it).
- If `adb devices` shows the device as `unauthorized`, tell the user to accept
  the RSA prompt on the phone screen.

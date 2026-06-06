# AGENTS.md

This repository is an **`adb`-driven Bluetooth diagnostic & rescue toolkit** for Samsung
Galaxy **Z Fold** phones whose Bluetooth won't stay on / shows address "Unavailable" after an
update. If you are an AI coding agent (Claude Code, ChatGPT Codex, Cursor, etc.), **this file
is your entry point.**

## Read first
**[CLAUDE.md](CLAUDE.md)** is the authoritative operating context — the phased plan, the hard
safety constraints, and the decision tree. Read it fully before running anything. This
`AGENTS.md` is a short pointer; `CLAUDE.md` wins on any detail.

## Your job
Diagnose, and where safe repair, Bluetooth on the connected device over `adb`. Drive the user
to a clear verdict: software/config fault (fix locally), firmware/radio fault (guided
same-version reflash), or hardware fault (service centre with evidence).

## Non-negotiable guardrails
- **NEVER flash firmware via `adb`** — it cannot, and pretending it can will brick the device.
  Firmware reinstall/rollback is an **external, manual** step (Odin / Heimdall / Thor).
- **Do NOT root** the device.
- **Work the phases in order (0 → 4).** Do not jump to rollback.
- Everything in `scripts/` is non-destructive **except** `03_bluetooth_repair.sh --hard`
  (clears pairings). **Always confirm with the user before any destructive step.**
- **Capture evidence to `./logs`** as you go. **Never commit `./logs`** — it holds the serial
  and Bluetooth MAC (it's gitignored).

## Quick path
1. `scripts/00_setup_mac.sh` — verify/install adb
2. `scripts/01_connect_check.sh` — inventory + Bluetooth state
3. `scripts/03_bluetooth_repair.sh --soft` — non-destructive reset (keeps pairings)
4. `scripts/02_capture_logcat.sh` — capture a Bluetooth logcat
5. `scripts/04_firmware_check.sh` — read-only anti-rollback (ARB) / reflash feasibility

Then interpret with the **decision tree in [CLAUDE.md](CLAUDE.md)**. The key tell: a stuck
`BLE_TURNING_ON` with a climbing `vendor.bluetooth_init_fail` and a crash-looping vendor HAL
(while Wi-Fi on the same chip works) is a **firmware/HAL controller-init failure** — not
corrupted pairings — so `pm clear` won't fix it; a **same-version reflash** is the next step.
See [`examples/`](examples/) for a redacted real capture of that signature.

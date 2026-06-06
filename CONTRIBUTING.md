# Contributing

Thanks for helping other Z Fold owners triage a frustrating, poorly-documented failure.

## The most valuable contributions

**Data points.** Open an issue (or PR a row into a future `examples/cases.md`) with:

- **Model + CSC** (e.g. `SM-F946U1` / `ATT`) and the **firmware build** (`F946U1UES8GZE8`).
- The **symptom** and **what fixed it** (soft reset / `--hard` clear / same-version reflash /
  rollback / service centre / still unsolved).
- The key signals: `vendor.bluetooth_init_fail` value, the `dumpsys bluetooth_manager`
  `state:` line, and whether **Wi-Fi on the same chip** worked.

This is the data that lets the decision tree tell "OTA corruption" from "dead radio" with
confidence — every confirmed case helps.

## 🔒 Redact before you post

Logs contain personal identifiers. **Before sharing anything**, remove:

- **Serial number** (e.g. `RxxxXXXXXXX`) → `R…` or `[REDACTED]`
- **Bluetooth / Wi-Fi MAC** → `XX:XX:XX:XX:XX:XX`
- **IMEI**, and any **paired-device names** in a `dumpsys` dump

See `examples/` for the expected redaction style. Never commit anything under `logs/`
(it's gitignored for this reason).

## Code / script PRs

- Keep scripts **POSIX-ish bash**, sourced from `scripts/lib.sh`, and **non-destructive by
  default** — anything that clears data or reboots must prompt/confirm and be clearly labeled.
- Don't add anything that flashes firmware, roots, or bypasses anti-rollback. Out of scope
  and dangerous.
- Test on a real device if you can, and say which model/build in the PR.

## Conduct

Be kind and practical. People arrive here stressed about a possibly-bricked $1,800 phone.

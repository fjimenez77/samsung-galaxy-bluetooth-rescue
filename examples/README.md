# Examples — what a firmware/HAL Bluetooth-init failure looks like

These are **real captures from a Galaxy Z Fold 5 (SM-F946U1)** after a One UI 8.5 update,
**redacted** (serial and Bluetooth MAC removed). They show the hardest case to recognize:
the Settings UI just says *"Bluetooth address: Unavailable,"* but `adb` reveals the radio's
**vendor HAL / controller is crash-looping at init** — *not* corrupted pairings.

| File | What it shows |
|---|---|
| `sample-inventory.txt` | `01_connect_check.sh` output — model, build, CSC, bootloader index, BT state |
| `sample-dumpsys-key-lines.txt` | the `BLE_TURNING_ON` stall, the `Reason is CRASH` loop, the HAL "service not declared / not found" failure, and the tell-tale `vendor.*` props |
| `sample-findings-dead-radio.md` | the full written diagnosis + recommendation ladder |

## The signature to look for

1. `dumpsys bluetooth_manager` is stuck at `state: BLE_TURNING_ON`, `enabled: false`, and the
   crash counter keeps climbing.
2. logcat shows `Bluetooth AIDL HAL service not declared` → falls back to HIDL →
   `Unable to get a Bluetooth service ... start the HAL before starting Bluetooth` → the
   `com.android.bluetooth` process dies and restarts.
3. `getprop vendor.bluetooth_init_fail` is **nonzero and climbing**, and
   `sys.init.updatable_crashing_process_name` names the **vendor bluetooth HAL**.
4. **Wi-Fi on the same combo chip still works** — so the chip isn't fully dead; the *Bluetooth*
   firmware/NV path specifically is failing.

If that's your phone: clearing Bluetooth data (`pm clear`) will **not** fix it — the fault is
below that layer. Go to a **same-version reflash** (`../notes/reflash-same-version.md`). If a
clean reflash still fails, it's a hardware/EFS fault → service centre.

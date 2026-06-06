# Example diagnosis — firmware/HAL Bluetooth-init failure (REDACTED)

A worked, real case so you can compare against your own device. Personal identifiers
(serial, MAC) are redacted.

**Device:** Samsung Galaxy Z Fold 5, **SM-F946U1** (US unlocked, Snapdragon)
**Firmware:** F946U1UES8GZE8 (Android 16 / One UI 8.5), security patch 2026-05-05
**CSC:** ATT (multi-CSC OYM), bootloader index **8**

## Symptom
Bluetooth will not stay on; Settings → Status shows Bluetooth address "Unavailable".
Started after the One UI 8.5 update.

## Root cause (confirmed via adb)
The Bluetooth **controller/HAL fails to initialize at the firmware/chip layer** — NOT
corrupted pairings or app data.

- `dumpsys bluetooth_manager`: stuck `state: BLE_TURNING_ON`, `enabled: false`, thousands of crashes.
- Crash loop: `[BluetoothSystemServer] requested to [Disable]. Reason is CRASH` every ~0.7s.
- logcat: `AIDL HAL service not declared` → HIDL fallback → `Unable to get a Bluetooth service
  after 500ms` → `com.android.bluetooth` dies and restarts.
- Props: `sys.init.updatable_crashing_process_name = vendor.bluetooth-1-1-qti`,
  `vendor.bluetooth_init_fail` nonzero & climbing, SoC `hastings` (Qualcomm WCN combo).
- App data healthy (`StorageModule started`, DB within limit) → `pm clear` won't help.
- **Wi-Fi (same chip) works** → chip powered; BT firmware/NV path specifically failing.

## What was tried — and failed (all adb software fixes)
1. Soft reset (`03_bluetooth_repair.sh --soft`: force-stop + toggle + reboot; pairings kept).
2. Wipe cache partition (recovery).
3. Reset network settings.
4. `pm clear com.android.bluetooth` (`--hard`) + reboot.

After each, identical: `init_fail` climbs, adapter oscillates OFF↔BLE_TURNING_ON, never ON.

## Anti-rollback (ARB)
Bootloader index **8**. A same-version reflash (F946U1UES8GZE8) is index 8 = **ARB-safe**.
A rollback off 8.5 would need a pre-8.5 build with index ≥ 8 (likely blocked) and may not fix
a radio/NV fault anyway — so a same-version reflash is the better next step.

## Recommendation ladder (least → most invasive)
1. Soft reset — done, no change.
2. On-phone: wipe cache partition / reset network settings / safe-mode — done/n.a., no change.
3. `pm clear` (BT data) — done, no change.
4. **Same-version Odin reflash (F946U1UES8GZE8)** — reinstalls BT firmware/vendor partitions
   cleanly; HOME_CSC first (keeps data) → plain CSC (wipe) if still broken.
5. If a clean reflash still leaves BT dead → **BT-core hardware fault** → Samsung service centre.

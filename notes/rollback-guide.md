# Firmware Rollback Guide — LAST RESORT ONLY

Read this only after Phases 1–4 have failed to revive Bluetooth **and**
`04_firmware_check.sh` says a compatible older build exists (ARB allows it).

> ⚠️ A downgrade typically **wipes all data**, and an interrupted/failed flash
> can **permanently brick** the phone. Back up everything first. `adb` cannot
> flash — this is a manual process with external tools.

---

## 0. The non-negotiable check first

Re-confirm with `scripts/04_firmware_check.sh`: the older firmware you intend to
flash must have a **bootloader index ≥ your current index**. If One UI 8.5 raised
the index, **stop** — rollback is blocked at the bootloader and no tool bypasses
it. Pursue a Samsung service centre instead.

---

## 1. Download the older firmware (macOS-friendly options)

You need the full 4-file set for your exact **model** (`SM-F946x`) and **CSC**
(region) as reported by `01_connect_check.sh`: **BL, AP, CP, CSC**.

**Option A — samloader (Python):**
```
pip3 install samloader        # or: pipx install samloader
# Check the latest version available for your model/region:
samloader -m SM-F946B -r <CSC> checkupdate
# Download + decrypt a specific older version (find one with a compatible index):
samloader -m SM-F946B -r <CSC> download -v <FIRMWARE/VERSION/STRING> -O ./fw
samloader -m SM-F946B -r <CSC> decrypt  -v <FIRMWARE/VERSION/STRING> \
  -i ./fw/<file>.enc4 -o ./fw/firmware.zip
```

**Option B — samfirm.js (Node):**
```
npm i -g samfirm
samfirm -m SM-F946B -r <CSC>
```

Tool availability changes over time — if one fails, search for the current
maintained Samsung firmware downloader. Verify the downloaded build's bootloader
index against your device before flashing.

---

## 2. Choose your flashing tool

| Platform | Tool | Notes |
|----------|------|-------|
| **Windows** (recommended) | **Odin** | Most reliable for Samsung. Borrow/dual-boot a Windows machine if you can. |
| macOS / Linux | **Heimdall** (`brew install heimdall`) or **Thor** | Works in principle but is unreliable on recent Folds. Higher brick risk. |

---

## 3. Enter Download (Odin) mode

1. Power the phone off.
2. Hold **Volume Up + Volume Down together**, then plug in the USB cable while
   holding. The Download/Odin warning screen appears.
3. Press Volume Up to continue into Download mode.

---

## 4. Flash (Odin example)

1. Open Odin on Windows. Confirm it shows a connected COM/ID (blue/added box).
2. Load the four files into their slots:
   - **BL** → BL
   - **AP** → AP
   - **CP** → CP
   - **CSC** → use **HOME_CSC** to *attempt* to keep data; use plain **CSC** to
     wipe (a downgrade often forces a wipe regardless).
3. In **Options**, leave **Re-Partition unchecked**.
4. Press **Start**. Do **not** touch the cable until it reports **PASS** and the
   phone reboots.

Heimdall equivalent: unzip the firmware, then flash each partition with
`heimdall flash --BOOTLOADER ... --AP ... --MODEM ... --CSC ...`. The exact
partition names come from `heimdall print-pit`. This path is fiddly — only if no
Windows machine is available.

---

## 5. After flashing

- First boot can take 5–15 minutes — leave it alone.
- Re-check the Bluetooth address (`scripts/01_connect_check.sh`). If it now shows
  and Bluetooth stays on, the downgrade fixed it. **Then disable auto-update for
  One UI 8.5** until Samsung ships a fix.
- If the address is still "Unavailable" after a successful downgrade, this was a
  hardware/EFS fault all along — book a service centre.

---

## 6. If it bricks

- Boot to Download mode again and re-flash the **current/newer** official build
  (its index is always allowed). This usually recovers a soft-brick.
- If it won't enter Download mode at all, it's a hard-brick → Samsung service.

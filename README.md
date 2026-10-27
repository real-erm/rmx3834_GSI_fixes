# Realme Note 50 (RMX3834) GSI Fixes

Fixes common bugs when running Generic System Images (GSI / Phh Treble / LineageOS / PixelExperience / Android 14/15/16) on the **Realme Note 50** (Unisoc Tiger T612 / `UMS9230`, Device: `RMX3834` / `RE5C9F`).

---

## ⚡ What Does This Fix?

- **📞 VoLTE & VoWiFi**:
  - Fixes missing call timer during active calls.
  - Fixes incoming calls not ringing or reaching the phone.
  - Fixes calls getting stuck on a bugged "connecting" state when the other party hangs up.
  - Restores VoLTE / VoWiFi toggles in Settings and status bar indicators.
- **☀️ Brightness & Backlight**:
  - Fixes the brightness slider dead zone (where brightness wouldn't dim below 50–60%). Gives smooth, linear 0%–100% control across the entire physical 12-bit backlight range (`1..4095`).
  - Fixes Auto-Brightness (adaptive brightness) failing or crushing down to pitch black indoors.
- **🚀 90Hz Display**:
  - Restores the 90Hz peak refresh rate profile.

---

## 🛠️ How It Works (Short Summary)

We dumped the stock Realme Note 50 Android 15 firmware (`super` partition) and analyzed it against AOSP GSI behavior. During testing, three main issues were identified:

1. **Missing Carrier Config**: AOSP doesn't ship VoLTE configurations for many regional carriers (e.g., Vodafone, WE, Orange, Etisalat). Even though the Unisoc IMS modem placed calls, AOSP Telecom never attached the call listener because it assumed the carrier didn't support VoLTE, breaking the call timer and remote hang-up signals.
2. **Brightness Curve Mismatch**: Stock firmware used non-standard resource names (`_lcd0` suffix) that AOSP ignored, while AOSP's quadratic gamma formula squeezed 50% of the slider travel into just 8% of the panel's backlight.
3. **Kernel OverlayFS on f2fs**: Kernel 5.15 on f2fs blocks KernelSU's default module overlay on `/data`.

**The Solution:**
- `treble-overlay-carrierconfig.apk`: Overlays carrier configs to force VoLTE/VoWiFi availability.
- `treble-overlay-realme-rmx3834.apk`: Standardizes backlight arrays, light sensor, and 90Hz display profiles for AOSP.
- **KernelSU / Magisk Module**: Injects early linear brightness properties at boot (`post-fs-data.sh`) and cleanly mounts overlays and the Unisoc IMS bridge via tmpfs.

---

## ⚠️ Known Issues / Limitations

- **Root Required**: Requires KernelSU, Magisk, or APatch to mount the IMS bridge and bypass kernel f2fs overlay restrictions.
- **Carrier Provisioning**: VoWiFi availability still depends on whether your mobile carrier allows Wi-Fi Calling on your specific SIM / APN profile.
- **SELinux**: If running Enforcing mode on a custom GKI kernel, make sure your kernel allows `sepolicy.rule` loading (already bundled in the module).

---

## 📦 How to Install

1. Grab **`realme_note_50_gsi_fix_module.zip`** from this repository (or [Releases](https://github.com/real-erm/rmx3834_GSI_fixes/releases)).
2. Open **KernelSU**, **Magisk**, or **APatch** on your phone.
3. Tap **Modules** -> **Install from storage** -> select `realme_note_50_gsi_fix_module.zip`.
4. Reboot your device.

---

## 🔍 Verification

After booting, run these commands in ADB or a root shell to confirm the fixes are active:

```bash
adb shell su -c "dumpsys carrier_config | grep -E 'carrier_volte|carrier_wfc'"
# Output:
# carrier_volte_available_bool = true
# carrier_wfc_ims_available_bool = true

adb shell su -c "dumpsys overlay | grep -E 'realme\.rmx3834|carrierconfig'"
# Output:
# mState: STATE_ENABLED for both overlays

adb shell su -c "dumpsys display | grep mBrightnessReason"
# Output:
# mBrightnessReason=automatic (when adaptive brightness is on) or manual
```

---

## 📄 License

This repository is licensed under the [BSD 3-Clause License](LICENSE).
Proprietary stock firmware files and blobs remain the property of Realme / Unisoc and are provided strictly for device interoperability.

# Realme Note 50 (RMX3834 / UMS9230) GSI Hardware Fixes Guide

This directory contains extracted data, hardware configurations, ready-to-use overlay APKs, and a complete flashable Magisk/KernelSU module to fix **Brightness Scaling**, **Auto-Brightness**, **VoLTE / VoWiFi Calling (Call Timer, Incoming & Outgoing Calls)**, and **90Hz Refresh Rate** when running Generic System Images (GSI) on the **Realme Note 50 (RMX3834 / RE5C9F)**.

---

## 1. Device Hardware Profile (Extracted from Stock Android 15 Dump)

- **Marketing Name**: realme Note 50
- **Model Number**: `RMX3834` (`ro.product.vendor.model=RMX3834`, Device: `RE5C9F`)
- **Firmware Version**: Android 15 (`AP3A.240905.015.A2`) / Realme UI T-Edition
- **SoC / Chipset**: Unisoc Tiger T612 (`UMS9230` / `qogirl6` / `sharkl6`)
- **Display Panel**: `lcd_icnl9916c_inx_mipi_hd` (720x1600 HD+, 90Hz, Chipone ICNL9916C controller + Innolux panel)
- **Backlight Controller**: `/vendor/bin/hw/vendor.sprd.hardware.lights-service`
- **Backlight Sysfs Node**: `/sys/class/backlight/sprd_backlight/brightness`
  - Min brightness: `1`
  - Max brightness: `4095` (`0xfff`)
  - Stock default brightness: `1306` (`0x51a`)
- **Ambient Light Sensor**: `light_mn7891x` on platform `sensorhub`
- **Modem / Telephony**: Unisoc LTE modem (`ro.vendor.radio.modemtype=l`), Dual SIM DSDS

---

## 2. Issues Diagnosed & Technical Root Causes

### A. Brightness Issues: "Below 60% it doesn't get dimmer" & "Autobrightness fails"
1. **Missing Framework Resource Suffix Mismatch**:
   - The stock vendor overlay (`unisoc_overlay_power_qogirl6.apk`) defined brightness tables with a device-specific `_lcd0` suffix:
     `config_autoBrightnessDisplayValuesNits_lcd0`, `config_autoBrightnessLevels_lcd0`, `config_screenBrightnessBacklight_lcd0`, `config_screenBrightnessNits_lcd0`.
   - AOSP's `framework-res` only looks for the standard names without `_lcd0`, resulting in `failed to find resource` errors in `idmap2`. AOSP fell back to dummy defaults, breaking auto-brightness and creating massive non-linear dead zones.
   - **Fix**: `treble-overlay-realme-rmx3834.apk` maps the exact stock nits, lux levels, and 12-bit backlight steps (1..4095) to the standard AOSP resource names.
2. **SystemUI Cubic Gamma Curve vs Linear Backlight**:
   - By default, SystemUI applies a cubic gamma curve in `BrightnessUtils.java`. Between 0% and 50% physical slider travel, the output was compressed to less than 8.3% (340 / 4095), appearing completely flat on this panel.
   - **Fix**: Setting `persist.sys.phh.linear_brightness=true` along with `persist.sys.brightness.disable_gamma_conversion=true` and `sys.brightness.disable_gamma_conversion=true` activates true linear lerp mapping (`MathUtils.lerp(min, max, p)`), scaling smoothly from backlight 80 at 0% up to 4095 at 100%.

### B. VoLTE / VoWiFi Issues: "No Call Timer, Call Doesn't Disconnect, Incoming Calls Don't Ring"
1. **AOSP CarrierConfig Missing Carrier Overrides**:
   - In AOSP, `/system_ext/priv-app/CarrierConfig/CarrierConfig.apk` has no configuration files for Vodafone Egypt (`60202` / `676`), WE Egypt (`60204` / `60201`), or Etisalat Egypt (`60203`).
   - AOSP defaulted to `carrier_volte_available_bool = false` and `carrier_wfc_ims_available_bool = false`.
   - Even though the Unisoc modem and `com.spreadtrum.ims` placed the call over IMS, Android Telecom refused to attach the IMS call listener because it believed the carrier did not support VoLTE. Consequently, calls never transitioned to `CALL_STATE_ACTIVE` in UI (no timer), disconnect events from the remote party were ignored, and incoming calls could not be routed to the dialer.
   - **Fix**: `treble-overlay-carrierconfig.apk` (signed with APK Signature Scheme v3 and 4-byte aligned) overlays `res/xml/vendor.xml` in `com.android.carrierconfig`, setting:
     - `carrier_volte_available_bool = true`
     - `carrier_wfc_ims_available_bool = true`
     - `carrier_default_wfc_ims_enabled_bool = true`
     - `enhanced_4g_lte_on_by_default_bool = true`
     - `hide_enhanced_4g_lte_bool = false` (exposing the VoLTE toggle in Settings)
     - `show_volte_icon = true`
2. **SELinux Policy Denials in Enforcing Mode**:
   - `com.spreadtrum.ims` was blocked from `find` on `ext_radio_service` (`vendor.unisoc.hardware.radio.ims.IImsRadio/slot1`, `slot2`) and `hal_extRadio_hwservice`, as well as `binder { call transfer }` with `rild` and `hal_telephony_default`.
   - **Fix**: `sepolicy.rule` provides exact allow rules loaded early by KernelSU.
3. **KernelSU f2fs OverlayFS Incompatibility**:
   - The device kernel (5.15) on f2fs rejects overlayfs with lowerdir on `/data` (`overlayfs: filesystem on '/data/adb/modules/...' not supported`).
   - **Fix**: `post-fs-data.sh` copies payloads to `/dev/imsfix/up` (tmpfs) during early boot and mounts overlayfs directly over `/system/system_ext/priv-app`, `bin`, `lib64`, `etc/permissions`, and `/system/product/overlay`.

---

## 3. Contents of this Directory

```text
realme_note_50_gsi_fixes/
├── README.md                                  # This documentation
├── realme_note_50_gsi_fix_module.zip          # Flashable KernelSU / Magisk / APatch module
├── treble-overlay-realme-rmx3834.apk          # Backlight (1-4095), auto-brightness curve & 90Hz overlay
├── treble-overlay-carrierconfig.apk           # VoLTE, VoWiFi & carrier configuration overlay
├── treble_overlay_source/                     # Realme hardware overlay source code
├── magisk_module/                             # Module workspace tree
│   ├── module.prop                            # Module metadata
│   ├── system.prop                            # System properties
│   ├── sepolicy.rule                          # SELinux Enforcing rules for Unisoc IMS
│   ├── post-fs-data.sh                        # Early boot tmpfs overlayfs injector
│   ├── service.sh                             # Boot service (modem wait, restart IMS, brightness props)
│   ├── skip_mount                             # Disables broken KernelSU built-in f2fs overlay
│   └── system/                                # System binaries, overlays, libs, and permissions
└── extracted_assets/                          # Stock ROM dumps
```

---

## 4. How to Apply the Fixes

### Method 1: Flash via KernelSU / Magisk / APatch (Recommended)
1. Transfer `realme_note_50_gsi_fix_module.zip` to the phone:
   ```bash
   adb push realme_note_50_gsi_fix_module.zip /sdcard/
   ```
2. Open the **KernelSU** (or Magisk) app on the phone.
3. Go to **Modules** -> **Install from storage** -> Select `realme_note_50_gsi_fix_module.zip`.
4. Reboot the phone.

### Verification After Boot
Verify that all fixes are active:
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

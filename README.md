# Realme Note 50 (RMX3834) GSI Hardware Fixes

A flashable Magisk / KernelSU / APatch module to fix common GSI bugs on the **Realme Note 50 (`RMX3834` / `RE5C9F`, Unisoc T612)**.

---

## 📱 What Does It Fix?

### 1. VoLTE & VoWiFi
* **Call Timer Working**: Fixes the bug where outgoing calls never show a timer.
* **Call Disconnect Fixed**: If the other party hangs up, the call now disconnects immediately instead of staying stuck on "Connecting..." or hanging indefinitely.
* **Incoming Calls**: Phone actually rings and receives incoming calls properly.
* **Carrier Config**: Exposes VoLTE / VoWiFi toggles in Settings for unsupported carriers (tested on WE, Vodafone, and Etisalat).

### 2. Brightness
* **Proper Slider Scaling**: Fixes the dead zone where the slider did nothing below 50–60%. Brightness now scales smoothly and linearly from 0% to 100%.
* **Auto-Brightness**: Restores proper lux-to-backlight mapping so adaptive brightness doesn't clamp your screen to pitch black indoors.

### 3. Display Refresh Rate
* Unlocks the native **90Hz** smooth display mode on GSI.

---

## ⚠️ Known Issues / Caveats

* **Requires Root**: Needs KernelSU, Magisk, or APatch to mount system overlays and run the IMS bridge service.
* **First Boot Delay**: After booting, the IMS bridge waits for your SIM card to initialize before hooking up (~5 to 10 seconds after unlocking).
* **KernelSU f2fs Quirk**: The stock Realme Note 50 kernel rejects standard KernelSU overlays on f2fs. This module works around it by mounting via tmpfs, so no kernel modifications are needed.

---

## 🚀 How to Install

1. Download [`realme_note_50_gsi_fix_module.zip`](./realme_note_50_gsi_fix_module.zip).
2. Open **KernelSU**, **Magisk**, or **APatch**.
3. Go to **Modules** ➔ **Install from storage** ➔ Pick the zip.
4. Reboot your phone.

---

## 📄 License

Original code and scripts are licensed under the [BSD 3-Clause License](./LICENSE).  
Extracted vendor binaries and overlays are property of Realme / Unisoc and are included solely for hardware interoperability.

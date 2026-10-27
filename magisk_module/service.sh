#!/system/bin/sh
MODDIR=${0%/*}
LOG=/data/local/tmp/imsfix.log

# Detach so init does not kill us together with the ksud service process group.
if [ "$1" != "child" ]; then
    setsid sh "$0" child >/dev/null 2>&1 < /dev/null &
    exit 0
fi

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
echo "service.sh boot_completed $(date)" >> $LOG

# Brightness: 12-bit HAL scale + linear slider without SystemUI gamma dead zone
setprop persist.sys.qcom-brightness 4095
setprop persist.sys.phh.linear_brightness true
setprop persist.sys.brightness.disable_gamma_conversion true
setprop sys.brightness.disable_gamma_conversion true
setprop persist.sys.phh.backlight.min 1
setprop persist.sys.phh.backlight.max 4095
setprop persist.sys.phh.backlight.scale 1
chmod 0666 /sys/class/backlight/sprd_backlight/brightness

# Ensure SystemUI reloads BrightnessUtils with sDisableGammaConversion = true
killall com.android.systemui

# Let the real IMS stack decide VoLTE/VoWiFi
setprop persist.vendor.sys.volte.enable true
setprop persist.vendor.sys.single.imsstack true
setprop persist.ims.apn ims
setprop persist.sys.phh.ims.flavour unisoc
setprop persist.sys.phh.ims.unisoc true

settings put global hidden_api_policy 1

# Enable custom device and carrier overlays
cmd overlay enable me.phh.treble.overlay.realme.rmx3834 >> $LOG 2>&1
cmd overlay enable me.phh.treble.overlay.carrierconfig >> $LOG 2>&1
cmd overlay enable me.phh.treble.overlay.sprdims_telephony >> $LOG 2>&1

if ! pidof ims_bridged >/dev/null 2>&1; then
    export LD_LIBRARY_PATH=/system_ext/lib64:/system/system_ext/lib64:$LD_LIBRARY_PATH
    /system_ext/bin/ims_bridged >> $LOG 2>&1 &
fi

# The IMS app starts before the modem/RIL is up and never retries (RADIO_NOT_AVAILABLE).
# Wait for the SIM stack, then restart it; telephony rebinds it automatically.
n=0
while [ $n -lt 60 ]; do
    case "$(getprop gsm.sim.state)" in *LOADED*|*READY*) break;; esac
    sleep 2; n=$((n+1))
done
sleep 10
am force-stop com.spreadtrum.ims
echo "service.sh restarted ims app after sim ready ($(getprop gsm.sim.state))" >> $LOG
echo "service.sh done: ims pkg=$(pm path com.spreadtrum.ims) bridged=$(pidof ims_bridged)" >> $LOG

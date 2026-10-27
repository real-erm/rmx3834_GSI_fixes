#!/system/bin/sh
# Runs BEFORE system_server, so PackageManager scans com.spreadtrum.ims at boot.
# KernelSU's own module overlay fails on this kernel (f2fs /data as overlay lower
# is "not supported"), so copy the payload into /dev (tmpfs) and overlay from there.
MODDIR=${0%/*}
SRC=$MODDIR/system/system_ext
T=/dev/imsfix
LOG=/data/local/tmp/imsfix.log

echo "post-fs-data start $(date)" > $LOG

# Ensure linear brightness in SystemUI from the very first frame of boot
setprop sys.brightness.disable_gamma_conversion true
setprop persist.sys.brightness.disable_gamma_conversion true
setprop persist.sys.phh.linear_brightness true
setprop persist.sys.qcom-brightness 4095
chmod 0666 /sys/class/backlight/sprd_backlight/brightness 2>/dev/null

mkdir -p $T/up/priv-app $T/up/bin $T/up/lib64 $T/up/perm $T/up/overlay \
         $T/wk/priv-app $T/wk/bin $T/wk/lib64 $T/wk/perm $T/wk/overlay

cp -a $SRC/priv-app/ims          $T/up/priv-app/
cp -a $SRC/bin/ims_bridged       $T/up/bin/
cp -a $SRC/lib64/libimsbrd.so    $T/up/lib64/
cp -a $SRC/lib64/libn3am_jni.so  $T/up/lib64/
cp -a $SRC/etc/permissions/com.spreadtrum.ims.xml $T/up/perm/

# Product overlays (auto-brightness, backlight curve, and carrierconfig)
if [ -d $MODDIR/system/product/overlay ]; then
    cp -a $MODDIR/system/product/overlay/* $T/up/overlay/
fi

chmod 0755 $T/up/bin/ims_bridged
chcon -R u:object_r:system_file:s0 $T/up

ovl() { # <name> <target>
    mount -t overlay overlay \
        -o lowerdir=$2,upperdir=$T/up/$1,workdir=$T/wk/$1 $2 >> $LOG 2>&1 \
        && echo "mounted $2" >> $LOG || echo "FAILED $2" >> $LOG
}
ovl priv-app /system/system_ext/priv-app
ovl bin      /system/system_ext/bin
ovl lib64    /system/system_ext/lib64
ovl perm     /system/system_ext/etc/permissions
ovl overlay  /system/product/overlay

SKIPUNZIP=0

ui_print "***********************************************"
ui_print "       Realme Note 50 (RMX3834) GSI Fixes     "
ui_print "  Brightness / VoLTE / VoWiFi / 90Hz / Camera  "
ui_print "***********************************************"

# Set permissions
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/system/system_ext/bin/ims_bridged" 0 0 0755

ui_print "- Overlay: treble-overlay-realme-rmx3834 installed"
ui_print "- CarrierConfig: treble-overlay-carrierconfig installed"
ui_print "- IMS Stack: com.spreadtrum.ims + ims_bridged installed"
ui_print "- SELinux: Enforcing sepolicy rules applied"
ui_print "- Brightness: Linear 1-4095 curve + auto-brightness configured"
ui_print " "
ui_print "- Installation complete! Please reboot your device."

#!/system/bin/sh
# Sourced by Magisk's installer after the archive has been extracted.
. "$MODPATH/profile.env" || abort '! Missing compatibility profile'
[ "$ARCH" = arm64 ] || abort '! This module requires arm64'
[ "$(getprop ro.product.device)" = "$EXPECTED_DEVICE" ] || abort '! Wrong device'
[ "$(getprop ro.lineage.version)" = "$EXPECTED_LINEAGE" ] || abort '! Wrong LineageOS build'
[ "$(uname -r)" = "$EXPECTED_KERNEL" ] || abort '! Wrong kernel'
[ -r /proc/config.gz ] || abort '! Kernel configuration is unavailable'
actual_config=$(sha256sum /proc/config.gz | cut -d' ' -f1)
[ "$actual_config" = "$EXPECTED_CONFIG_SHA256" ] || abort '! Kernel configuration differs'
actual_module=$(sha256sum "$MODPATH/ntsync.ko" | cut -d' ' -f1)
[ "$actual_module" = "$EXPECTED_MODULE_SHA256" ] || abort '! Module checksum mismatch'
set_perm "$MODPATH/ntsync.ko" 0 0 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/status.sh" 0 0 0755
ui_print '- NTSync compatibility verified; the module will load after reboot.'

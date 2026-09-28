#!/system/bin/sh
# Magisk late_start service; avoid delaying boot on an incompatible system.
MODDIR=${0%/*}
LOG="$MODDIR/service.log"
. "$MODDIR/profile.env" || exit 1
log() { printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$LOG"; }
if [ "$(getprop ro.product.device)" != "$EXPECTED_DEVICE" ] ||
   [ "$(getprop ro.lineage.version)" != "$EXPECTED_LINEAGE" ] ||
   [ "$(uname -r)" != "$EXPECTED_KERNEL" ]; then
  log 'FAIL: device or build mismatch; module was not loaded'
  exit 1
fi
config_hash=$(sha256sum /proc/config.gz 2>/dev/null | cut -d' ' -f1)
module_hash=$(sha256sum "$MODDIR/ntsync.ko" 2>/dev/null | cut -d' ' -f1)
if [ "$config_hash" != "$EXPECTED_CONFIG_SHA256" ] ||
   [ "$module_hash" != "$EXPECTED_MODULE_SHA256" ]; then
  log 'FAIL: configuration or module checksum mismatch'
  exit 1
fi
if [ ! -d /sys/module/ntsync ]; then
  if ! /system/bin/insmod "$MODDIR/ntsync.ko" 2>> "$LOG"; then
    log 'FAIL: insmod rejected ntsync.ko'
    exit 1
  fi
  log 'PASS: kernel module loaded'
else
  log 'INFO: ntsync already loaded'
fi
count=0
while [ ! -r /sys/class/misc/ntsync/dev ] && [ "$count" -lt 10 ]; do
  sleep 1
  count=$((count + 1))
done
if [ ! -r /sys/class/misc/ntsync/dev ]; then
  log 'FAIL: ntsync misc device was not registered'
  exit 1
fi
if [ ! -e /dev/ntsync ]; then
  numbers=$(cat /sys/class/misc/ntsync/dev)
  major=${numbers%%:*}
  minor=${numbers#*:}
  if ! mknod /dev/ntsync c "$major" "$minor"; then
    log 'FAIL: unable to create /dev/ntsync'
    exit 1
  fi
fi
if [ ! -c /dev/ntsync ]; then
  log 'FAIL: /dev/ntsync is not a character device'
  exit 1
fi
if ! chmod 0666 /dev/ntsync; then
  log 'FAIL: unable to set /dev/ntsync permissions'
  exit 1
fi
log 'PASS: /dev/ntsync ready (0666)'

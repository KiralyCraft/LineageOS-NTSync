#!/system/bin/sh
MODDIR=${0%/*}
printf 'kernel: %s\n' "$(uname -r)"
if [ -d /sys/module/ntsync ]; then
  echo 'module: loaded'
else
  echo 'module: absent'
fi
if [ -r /sys/class/misc/ntsync/dev ]; then
  printf 'registered device: %s\n' "$(cat /sys/class/misc/ntsync/dev)"
else
  echo 'registered device: absent'
fi
if [ -e /dev/ntsync ]; then
  ls -lZ /dev/ntsync
else
  echo '/dev/ntsync: absent'
fi
if [ -f "$MODDIR/service.log" ]; then
  tail -n 10 "$MODDIR/service.log"
fi

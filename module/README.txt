LineageOS-NTSync for Sony XQ-DQ72, LineageOS 22.2-20250608 and the pinned
5.15.176-gd00ba216ccda kernel. Install through Magisk, then reboot manually.
Check /data/adb/modules/lineageos_ntsync/status.sh and service.log.
Disable this module in Magisk and reboot to stop loading ntsync.
The module does not alter the boot image or the HDMI installation.

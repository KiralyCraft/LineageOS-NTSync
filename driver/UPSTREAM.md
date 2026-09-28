Driver and UAPI source: Linux stable v6.18.54, gregkh/linux.
Tag object: f3a1796a1e25fb7f8acc3b14ffb80bf9c67819df.
Source paths: drivers/misc/ntsync.c and include/uapi/linux/ntsync.h.
Original SHA-256 values are in profiles/current-install.json.
Compatibility changes to the imported driver must be kept in a documented
patch and update that profile's source integrity fields only for a new import.

Backport change for this kernel: `ntsync_timens_ktime_to_host()` reproduces
`do_timens_ktime_to_host(CLOCK_MONOTONIC, ...)` from the pinned Sony kernel
without importing its non-exported `init_time_ns` or helper. This conversion
uses the current namespace offset, including the initial namespace's zero
offset. The imported v6.18.54 driver SHA-256 before this change is
`0a2d3494ed59783ea988a4b607db49e1413ab9815a5097440decb3c899e1dcb0`.
The profile records the SHA-256 of the build input after this backport.

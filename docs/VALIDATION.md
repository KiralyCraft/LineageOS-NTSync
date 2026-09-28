# Manual device validation

The ZIP is delivered to `/sdcard/Download/` for installation in Magisk. The
user installs it and performs any required reboot. No build or upload command
installs or loads the module.

Before Magisk installation, a manually loaded `.ko` may be tested through
upstream selftests and the existing NieR Wine prefix after its game and Wine
server have exited. This is recorded separately;
the release tag remains gated on a successful Magisk service startup.

After installation:

1. Confirm Magisk lists `lineageos_ntsync` and inspect `service.log`.
2. Verify the kernel module, misc registration, device permissions, and device
   accessibility from the chroot user.
3. Run the imported Linux ntsync selftests as that user. Check dmesg for
   `ntsync`, module signature, CFI, and SELinux failures.
4. Start GE-Proton11-6 in the NieR prefix with a short built-in command.
   Confirm `ntsync: up and running.` and that the test process exits.
5. Compare NieR frame presentation only after the user manually restarts it.

Do not interpret a present `/dev/ntsync` as proof that ioctls or Wine work.
Backend validation and gameplay performance are separate results.

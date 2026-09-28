# LineageOS NTSync for Sony XQ-DQ72

A Magisk package for the kernel ntsync misc driver, built for one pinned
LineageOS kernel. It provides `/dev/ntsync` to Wine/Proton without modifying
boot images, the HDMI module, Proton, or game files.

## Supported installation

- Sony XQ-DQ72 with LineageOS `22.2-20250608-NIGHTLY-pdx234`
- Kernel `5.15.176-gd00ba216ccda`, commit
  `d00ba216ccda5d4fcc0d864729ae69d5b63d860c`
- Kernel configuration SHA-256 (compressed `/proc/config.gz`):
  `3a571c2ddb2b56fca395037a32d12b2df4e81b928d053b88edcc7b2800db3b48`

The installer checks all of these before accepting the package. A differently
built kernel requires a new compatibility profile, rebuild, and validation.

## Build

`make server-preflight` checks the existing build server
`root@192.168.104.201`. The build uses the exact Sony kernel checkout and
Android Clang r536225 already cached under `/bigdata/hdmi-los-build/cache/`.
All NTSync outputs go under `/bigdata/ntsync-los-build`.

The baseline kernel build must produce `kernel-out/vmlinux` and
`kernel-out/Module.symvers` from the captured `/proc/config.gz` before an
external module can be built. On the server, run the documented
`run-kernel-baseline.sh` in a named tmux shell. Then run:

```sh
make test
make zip
make verify
```

The ZIP and companion artifacts appear in `dist/`. `make zip` syncs source to
an isolated build-server directory, builds the module, packages it, downloads
the artifacts, and verifies them. A local dirty tree is recorded in the build
manifest; release publication requires a clean commit.

`make stage-release` commits verified assets to a private Git branch for the
manual installation handoff. It does not invoke GitHub Actions or an API.

Upstream source and licensing are recorded in `driver/UPSTREAM.md` and `LICENSE`.
The driver and UAPI header were imported from Linux stable v6.18.54. Any
compatibility changes must be kept narrow and documented.

## Installation and test

Install `lineageos-ntsync-current-install-v0.1.0-rc.1-magisk.zip` through the
Magisk app and reboot manually. The service loads `ntsync.ko` once and ensures
`/dev/ntsync` exists with mode `0666`, the upstream driver's default mode.

After installation, inspect
`/data/adb/modules/lineageos_ntsync/service.log`, run its `status.sh`, and run
`make device-test` from this repository. That test copies upstream ntsync
selftests to a temporary directory on the phone and executes them as the
chroot user. It also exercises GE-Proton in the existing NieR prefix after
the game and its Wine server exit. A game performance comparison requires a
separate launch.

If installation or boot loading fails, disable this module in Magisk and
reboot. The package does not change the boot image or any other module.
Avoid force-unloading ntsync while any process holds it open.

## Publication

The source repository is private. A staging branch holds the ZIP, standalone
`.ko`, build manifest, and checksums. After manual installation and native/Wine
validation, `make publish` creates a validated branch and annotated tag. This
process uses Git only, with no GitHub Actions storage. Gameplay results are
reported separately.

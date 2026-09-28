# Baseline build and compatibility

The exact kernel source is
`/bigdata/hdmi-los-build/cache/lineage-22.2-display/kernel/sony/sm8550`
at `d00ba216ccda5d4fcc0d864729ae69d5b63d860c`. The compiler is
`prebuilts/clang/host/linux-x86/clang-r536225/bin/clang` from the same cached
LineageOS tree. The target's compressed configuration is saved as
`/bigdata/ntsync-los-build/target-config.gz`.

The build server bootstrap is:

```sh
work=/bigdata/ntsync-los-build
src=/bigdata/hdmi-los-build/cache/lineage-22.2-display/kernel/sony/sm8550
llvm=/bigdata/hdmi-los-build/cache/lineage-22.2-display/prebuilts/clang/host/linux-x86/clang-r536225/bin
pahole_dir=/bigdata/hdmi-los-build/cache/lineage-22.2-display/prebuilts/kernel-build-tools/linux-x86/bin
mkdir -p "$work/kernel-out" "$work/logs"
gzip -dc "$work/target-config.gz" > "$work/kernel-out/.config"
export PATH="$llvm:$pahole_dir:$PATH" ARCH=arm64 LLVM=1 LLVM_IAS=1
make -C "$src" O="$work/kernel-out" olddefconfig
make -j24 -C "$src" O="$work/kernel-out" vmlinux
```

The baseline must include complete `Module.symvers` because
`CONFIG_MODVERSIONS=y`; `modules_prepare` alone is insufficient. Compare the
generated configuration with the target's and investigate any changed symbol.
The pinned target also uses full Clang LTO and Clang CFI. Do not bypass either
feature or force-load a module. On a different device build, capture a new
profile and rebuild with its exact source and compiler.

`build-support/build-remote.sh` checks the source revision, upstream import
hashes, and baseline artifacts, then uses kernel kbuild for the external
module. The fetched ZIP is checked by `scripts/verify-dist.py`.

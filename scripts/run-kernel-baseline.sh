#!/usr/bin/env bash
set -Eeuo pipefail
work=/bigdata/ntsync-los-build
src=/bigdata/hdmi-los-build/cache/lineage-22.2-display/kernel/sony/sm8550
llvm=/bigdata/hdmi-los-build/cache/lineage-22.2-display/prebuilts/clang/host/linux-x86/clang-r536225/bin
pahole_dir=/bigdata/hdmi-los-build/cache/lineage-22.2-display/prebuilts/kernel-build-tools/linux-x86/bin
export PATH="$llvm:$pahole_dir:$PATH"
export ARCH=arm64 LLVM=1 LLVM_IAS=1
printf 'source=%s\n' "$(git -C "$src" rev-parse HEAD)"
printf 'compiler=%s\n' "$(clang --version | head -1)"
make -C "$src" O="$work/kernel-out" olddefconfig
cp "$work/kernel-out/.config" "$work/kernel-config-generated"
make -j24 -C "$src" O="$work/kernel-out" vmlinux
make -C "$src" O="$work/kernel-out" modules_prepare
test -s "$work/kernel-out/vmlinux.symvers"
# The vmlinux target emits the complete built-in export table under this name.
# External-module kbuild expects the same table as Module.symvers.
cp "$work/kernel-out/vmlinux.symvers" "$work/kernel-out/Module.symvers"
sha256sum "$work/kernel-out/Module.symvers" "$work/kernel-out/vmlinux" "$work/kernel-config-generated" > "$work/kernel-baseline-sha256"

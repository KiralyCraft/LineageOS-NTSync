#!/usr/bin/env bash
set -Eeuo pipefail
source_root=${1:?source root}
work=/bigdata/ntsync-los-build
kernel=/bigdata/hdmi-los-build/cache/lineage-22.2-display/kernel/sony/sm8550
llvm=/bigdata/hdmi-los-build/cache/lineage-22.2-display/prebuilts/clang/host/linux-x86/clang-r536225/bin
pahole_dir=/bigdata/hdmi-los-build/cache/lineage-22.2-display/prebuilts/kernel-build-tools/linux-x86/bin
export PATH="$llvm:$pahole_dir:$PATH"
export ARCH=arm64 LLVM=1 LLVM_IAS=1
expected=d00ba216ccda5d4fcc0d864729ae69d5b63d860c
actual=$(git -C "$kernel" rev-parse HEAD)
[ "$actual" = "$expected" ] || { echo "Wrong kernel source: $actual" >&2; exit 1; }
[ -s "$work/kernel-out/Module.symvers" ] || { echo 'Baseline kernel build incomplete' >&2; exit 1; }
[ -s "$work/kernel-out/vmlinux" ] || { echo 'Baseline vmlinux missing' >&2; exit 1; }
python3 - "$source_root" <<'PY'
import hashlib,json,pathlib,sys
source=pathlib.Path(sys.argv[1])
profile=json.loads((source/'profiles/current-install.json').read_text())
for name,field in [('driver/ntsync.c','ntsync_driver_sha256'),('driver/include/uapi/linux/ntsync.h','ntsync_uapi_sha256')]:
 value=hashlib.sha256((source/name).read_bytes()).hexdigest()
 if value!=profile[field]:raise SystemExit(f'{name}: upstream integrity mismatch')
PY
make -j8 -C "$kernel" O="$work/kernel-out" M="$source_root/driver" modules
module="$source_root/driver/ntsync.ko"
test -s "$module"
llvm-readelf -h "$module" | grep -q 'AArch64'
llvm-nm -u "$module" | tee "$work/logs/imported-symbols.txt"
python3 "$source_root/build-support/package.py" "$source_root" "$module" "$work/output" "${SOURCE_COMMIT:-unknown}" "$work"

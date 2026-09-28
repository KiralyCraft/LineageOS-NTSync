#!/usr/bin/env bash
set -Eeuo pipefail
root=$(git rev-parse --show-toplevel)
server=${SERVER:-root@192.168.104.201}
work=/bigdata/ntsync-los-build
case "${1:-}" in
  preflight)
    ssh -F /dev/null "$server" "test -d '$work/kernel-out' && test -x /bigdata/hdmi-los-build/cache/lineage-22.2-display/prebuilts/clang/host/linux-x86/clang-r536225/bin/clang && df -h /bigdata"
    exit
    ;;
  zip) ;;
  *) echo 'Usage: remote-build.sh preflight|zip' >&2; exit 2 ;;
esac
ssh -F /dev/null "$server" "mkdir -p '$work/source' '$work/output' '$work/logs'"
rsync -a --delete --exclude=.git --exclude=dist --exclude=.build --exclude='*.o' --exclude='*.ko' --exclude='*.mod*' --exclude=Module.symvers --exclude=modules.order \
  -e 'ssh -F /dev/null' "$root/" "$server:$work/source/"
commit=$(git -C "$root" rev-parse HEAD 2>/dev/null || printf uncommitted)
if [ -n "$(git -C "$root" status --porcelain --untracked-files=normal)" ]; then
  commit="$commit-dirty"
fi
ssh -F /dev/null "$server" "SOURCE_COMMIT='$commit' bash '$work/source/build-support/build-remote.sh' '$work/source'" | tee "$root/.build-remote.log"
mkdir -p "$root/dist"
rsync -a --delete -e 'ssh -F /dev/null' "$server:$work/output/" "$root/dist/"
python3 "$root/scripts/verify-dist.py" "$root/dist"

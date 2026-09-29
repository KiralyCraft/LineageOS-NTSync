#!/usr/bin/env bash
set -Eeuo pipefail
root=$(git rev-parse --show-toplevel)
target=${DEVICE:-root@192.168.5.144}
ssh -F /dev/null "$target" 'test -d /sys/module/ntsync && test -c /dev/ntsync && test "$(stat -c %a /dev/ntsync)" = 666'
ssh -F /dev/null "$target" 'mkdir -p /tmp/ntsync-los-validation'
tar -C "$root" -cf - driver/include/uapi tests/upstream scripts/proton-app | ssh -F /dev/null "$target" 'tar -xf - -C /tmp/ntsync-los-validation'
ssh -F /dev/null "$target" bash -s <<'REMOTE'
set -Eeuo pipefail
work=/tmp/ntsync-los-validation
gcc -O2 -pthread -I"$work/driver/include/uapi" \
  "$work/tests/upstream/drivers/ntsync/ntsync.c" -o "$work/ntsync-selftest"
timeout 120 runuser -u kiraly -- "$work/ntsync-selftest"
prefix=/mnt/usbssd/winprefixes/nier
if pgrep -u kiraly -f 'NieRAutomata.exe' >/dev/null ||
   pgrep -u kiraly -x wineserver >/dev/null; then
  echo 'The NieR process or its Wine server is still running; stop it before backend selection' >&2
  exit 1
fi
test -d "$prefix/pfx"
touch "$work/wine-start.marker"
timeout 120 runuser -u kiraly -- env HOME=/home/kiraly \
  WINPREFIX_ROOT=/mnt/usbssd/winprefixes PROTON_LOG=1 \
  "$work/scripts/proton-app" nier --runinprefix cmd /c exit \
  > "$work/wine-smoke.log" 2>&1
if ! grep -F -q 'ntsync: up and running.' "$work/wine-smoke.log" &&
   ! find "$prefix/logs" -type f -newer "$work/wine-start.marker" \
      -exec grep -F -l 'ntsync: up and running.' {} + | grep -q .; then
  cat "$work/wine-smoke.log"
  echo 'Wine did not confirm ntsync backend' >&2
  exit 1
fi
printf 'Native ntsync selftests and NieR-prefix Wine backend: PASS\n'
REMOTE
magisk_install=PENDING
if ssh -F /dev/null "$target" 'test -f /data/adb/modules/lineageos_ntsync/service.log && grep -q "PASS: /dev/ntsync ready" /data/adb/modules/lineageos_ntsync/service.log'; then
  magisk_install=PASS
fi
python3 - "$root" "$magisk_install" <<'PY'
import datetime
import json
import pathlib
import subprocess
import sys

root = pathlib.Path(sys.argv[1])
magisk_install = sys.argv[2]
info = json.loads(next((root / 'dist').glob('*-build-info.json')).read_text())
receipt = {
    'validated_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'source_commit': subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip(),
    'module_sha256': info['module_sha256'],
    'native_selftests': 'PASS',
    'wine_backend': 'PASS',
    'wine_prefix': '/mnt/usbssd/winprefixes/nier',
    'magisk_install': magisk_install,
    'gameplay': 'PENDING_USER_RESTART',
}
(root / 'dist/device-validation.json').write_text(json.dumps(receipt, indent=2, sort_keys=True) + '\n')
PY

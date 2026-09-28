#!/usr/bin/env bash
set -Eeuo pipefail
root=$(git rev-parse --show-toplevel)
target=${DEVICE:-root@192.168.5.144}
ssh -F /dev/null "$target" 'test -d /sys/module/ntsync && test -c /dev/ntsync && test "$(stat -c %a /dev/ntsync)" = 666'
ssh -F /dev/null "$target" 'mkdir -p /tmp/ntsync-los-validation'
tar -C "$root" -cf - driver/include/uapi tests/upstream | ssh -F /dev/null "$target" 'tar -xf - -C /tmp/ntsync-los-validation'
ssh -F /dev/null "$target" bash -s <<'REMOTE'
set -Eeuo pipefail
work=/tmp/ntsync-los-validation
gcc -O2 -pthread -I"$work/driver/include/uapi" \
  "$work/tests/upstream/drivers/ntsync/ntsync.c" -o "$work/ntsync-selftest"
timeout 120 runuser -u kiraly -- "$work/ntsync-selftest"
validation=/tmp/ntsync-los-wine-validation
mkdir -p "$validation"
chown 4000:60000 "$validation"
timeout 120 runuser -u kiraly -- env WINPREFIX_ROOT="$validation" PROTON_LOG=1 \
  /usr/local/bin/proton-app ntsync-smoke --runinprefix cmd /c exit \
  > "$work/wine-smoke.log" 2>&1
if ! grep -R -F -q 'ntsync: up and running.' "$work/wine-smoke.log" "$validation/ntsync-smoke/logs" 2>/dev/null; then
  cat "$work/wine-smoke.log"
  echo 'Wine did not confirm ntsync backend' >&2
  exit 1
fi
printf 'Native ntsync selftests and isolated Wine smoke: PASS\n'
REMOTE
python3 - "$root" <<'PY'
import datetime
import json
import pathlib
import subprocess
import sys

root = pathlib.Path(sys.argv[1])
info = json.loads(next((root / 'dist').glob('*-build-info.json')).read_text())
receipt = {
    'validated_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'source_commit': subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip(),
    'module_sha256': info['module_sha256'],
    'native_selftests': 'PASS',
    'wine_backend': 'PASS',
    'gameplay': 'PENDING_USER_RESTART',
}
(root / 'dist/device-validation.json').write_text(json.dumps(receipt, indent=2, sort_keys=True) + '\n')
PY

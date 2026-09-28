#!/usr/bin/env bash
set -Eeuo pipefail
root=$(git rev-parse --show-toplevel)
cd "$root"
test -f dist/device-validation.json || { echo 'Native and Wine device validation is required before publication' >&2; exit 1; }
python3 scripts/verify-dist.py dist
python3 - <<'PY'
import json
import pathlib
import subprocess

root = pathlib.Path.cwd()
receipt = json.loads((root / 'dist/device-validation.json').read_text())
info = json.loads(next((root / 'dist').glob('*-build-info.json')).read_text())
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
assert receipt['native_selftests'] == 'PASS'
assert receipt['wine_backend'] == 'PASS'
assert receipt['magisk_install'] == 'PASS'
assert receipt['module_sha256'] == info['module_sha256']
assert receipt['source_commit'] == info['source_commit'] == head
PY
branch=release/rc1-publish
if git ls-remote --exit-code origin "refs/heads/$branch" >/dev/null 2>&1; then
  echo "Remote publication branch already exists: $branch" >&2
  exit 1
fi
worktree=$(mktemp -d -t ntsync-publish.XXXXXXXX)
trap 'git worktree remove --force "$worktree" >/dev/null 2>&1 || true; rmdir "$worktree" >/dev/null 2>&1 || true' EXIT
git fetch origin release/rc1-staging
git worktree add -b "$branch" "$worktree" FETCH_HEAD
cp dist/device-validation.json "$worktree/release-assets/device-validation.json"
cat > "$worktree/release-assets/RELEASE_NOTES.md" <<'NOTES'
Sony XQ-DQ72, LineageOS 22.2-20250608, kernel 5.15.176-gd00ba216ccda.
The user installed this Magisk package manually. Native ntsync selftests and
isolated GE-Proton11-6 backend selection passed; see device-validation.json.
NieR gameplay performance is pending the user's manual game restart.
NOTES
git -C "$worktree" add release-assets
git -C "$worktree" commit -m 'Publish NTSync candidate after device validation'
git -C "$worktree" push -u origin "$branch"
git -C "$worktree" tag -a v0.1.0-rc.1 -m 'Validated NTSync candidate for XQ-DQ72'
git -C "$worktree" push origin v0.1.0-rc.1

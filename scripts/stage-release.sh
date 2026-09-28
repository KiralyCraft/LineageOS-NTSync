#!/usr/bin/env bash
set -Eeuo pipefail
root=$(git rev-parse --show-toplevel)
cd "$root"
test -z "$(git status --porcelain --untracked-files=normal)" || { echo 'Commit the source before staging release' >&2; exit 1; }
python3 scripts/verify-dist.py dist
source_commit=$(git rev-parse HEAD)
base=lineageos-ntsync-current-install-v0.1.0-rc.1
expected="$source_commit"
actual=$(python3 -c 'import json; print(json.load(open("dist/lineageos-ntsync-current-install-v0.1.0-rc.1-build-info.json"))["source_commit"])')
[ "$actual" = "$expected" ] || { echo "Build commit mismatch: $actual" >&2; exit 1; }
python3 - <<'PY'
import json
import pathlib
import subprocess

receipt_path = pathlib.Path('dist/device-validation.json')
assert receipt_path.is_file(), 'Run make device-test before staging'
receipt = json.loads(receipt_path.read_text())
info = json.loads(pathlib.Path('dist/lineageos-ntsync-current-install-v0.1.0-rc.1-build-info.json').read_text())
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
assert receipt['source_commit'] == info['source_commit'] == head
assert receipt['module_sha256'] == info['module_sha256']
assert receipt['native_selftests'] == receipt['wine_backend'] == 'PASS'
PY
branch=release/rc1-staging
if git ls-remote --exit-code origin "refs/heads/$branch" >/dev/null 2>&1; then
  echo "Remote release branch already exists: $branch" >&2
  exit 1
fi
worktree=$(mktemp -d -t ntsync-release.XXXXXXXX)
trap 'git worktree remove --force "$worktree" >/dev/null 2>&1 || true; rmdir "$worktree" >/dev/null 2>&1 || true' EXIT
git worktree add -b "$branch" "$worktree" "$source_commit"
mkdir -p "$worktree/release-assets"
cp "dist/$base-magisk.zip" "dist/$base-ntsync.ko" "dist/$base-build-info.json" dist/SHA256SUMS "$worktree/release-assets/"
cp dist/device-validation.json "$worktree/release-assets/"
printf '%s\n' "$source_commit" > "$worktree/release-assets/SOURCE_COMMIT"
cat > "$worktree/release-assets/RELEASE_NOTES.md" <<'NOTES'
Candidate for Sony XQ-DQ72, LineageOS 22.2-20250608, kernel 5.15.176-gd00ba216ccda.

Kernel module and archive passed build/package checks. Manual insertion on the
phone, all 11 native ntsync selftests, and Wine backend selection in the NieR
prefix passed. See device-validation.json. Magisk installation, boot loading,
and NieR performance remain pending. Install only on the pinned device/build;
the package checks this.
NOTES
git -C "$worktree" add release-assets
git -C "$worktree" commit -m 'Stage verified NTSync release candidate'
git -C "$worktree" push -u origin "$branch"

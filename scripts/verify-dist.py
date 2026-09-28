#!/usr/bin/env python3
import hashlib
import json
import pathlib
import struct
import sys
import zipfile

folder = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'dist')
profile = json.loads(pathlib.Path('profiles/current-install.json').read_text())
release = json.loads(pathlib.Path('release.json').read_text())
base = f"lineageos-ntsync-{profile['id']}-v{release['version']}"
checksums = folder / 'SHA256SUMS'
assert checksums.is_file()
for line in checksums.read_text().splitlines():
    digest, name = line.split('  ', 1)
    asset = folder / name
    assert asset.is_file() and hashlib.sha256(asset.read_bytes()).hexdigest() == digest, name
info = json.loads((folder / f'{base}-build-info.json').read_text())
module = (folder / f'{base}-ntsync.ko').read_bytes()
assert module[:4] == b'\x7fELF' and module[4] == 2 and struct.unpack_from('<H', module, 18)[0] == 183
assert info['module_sha256'] == hashlib.sha256(module).hexdigest()
assert info['profile'] == profile and info['release'] == release
assert profile['kernel_release'].encode() in module
with zipfile.ZipFile(folder / f'{base}-magisk.zip') as zf:
    assert zf.testzip() is None
    expected = {'module.prop', 'profile.env', 'ntsync.ko', 'customize.sh', 'service.sh', 'status.sh', 'skip_mount', 'README.txt'}
    assert set(zf.namelist()) == expected, zf.namelist()
    assert zf.read('ntsync.ko') == module
    for script in ('customize.sh', 'service.sh', 'status.sh'):
        assert (zf.getinfo(script).external_attr >> 16) & 0o111
    assert f"EXPECTED_MODULE_SHA256='{info['module_sha256']}'" in zf.read('profile.env').decode()
print('Distribution verification: PASS')

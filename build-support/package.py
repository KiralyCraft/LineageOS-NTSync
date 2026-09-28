#!/usr/bin/env python3
"""Build a deterministic Magisk ZIP from a verified kernel module."""
import hashlib
import json
import os
import pathlib
import shutil
import sys
import tempfile
import zipfile

source = pathlib.Path(sys.argv[1]).resolve()
module_binary = pathlib.Path(sys.argv[2]).resolve()
output_dir = pathlib.Path(sys.argv[3]).resolve()
commit = sys.argv[4]
kernel_work = pathlib.Path(sys.argv[5]).resolve() if len(sys.argv) > 5 else None
profile = json.loads((source / 'profiles/current-install.json').read_text())
release = json.loads((source / 'release.json').read_text())
module_sha = hashlib.sha256(module_binary.read_bytes()).hexdigest()
version = release['version']
base = f"lineageos-ntsync-{profile['id']}-v{version}"
output_dir.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='ntsync-package-') as tmp:
    stage = pathlib.Path(tmp)
    for item in (source / 'module').iterdir():
        if item.is_file():
            shutil.copy2(item, stage / item.name)
    shutil.copy2(module_binary, stage / 'ntsync.ko')
    (stage / 'module.prop').write_text(
        f"id={release['module_id']}\n"
        "name=LineageOS NTSync\n"
        f"version={version}-{profile['id']}\n"
        f"versionCode={release['version_code']}\n"
        "author=KiralyCraft\n"
        "description=NT synchronization driver for the pinned Sony LineageOS kernel\n")
    (stage / 'profile.env').write_text(
        f"EXPECTED_DEVICE='{profile['device']}'\n"
        f"EXPECTED_LINEAGE='{profile['lineage']}'\n"
        f"EXPECTED_KERNEL='{profile['kernel_release']}'\n"
        f"EXPECTED_CONFIG_SHA256='{profile['kernel_config_gz_sha256']}'\n"
        f"EXPECTED_MODULE_SHA256='{module_sha}'\n")
    for script in ('customize.sh', 'service.sh', 'status.sh'):
        (stage / script).chmod(0o755)
    manifest = {
        'module_sha256': module_sha,
        'source_commit': commit,
        'profile': profile,
        'release': release,
    }
    if kernel_work is not None:
        compiler = pathlib.Path('/bigdata/hdmi-los-build/cache/lineage-22.2-display/prebuilts/clang/host/linux-x86/clang-r536225/bin/clang')
        pahole = pathlib.Path('/bigdata/hdmi-los-build/cache/lineage-22.2-display/prebuilts/kernel-build-tools/linux-x86/bin/pahole')
        config = kernel_work / 'kernel-out/.config'
        symvers = kernel_work / 'kernel-out/Module.symvers'
        manifest['build'] = {
            'kernel_config_sha256': hashlib.sha256(config.read_bytes()).hexdigest(),
            'module_symvers_sha256': hashlib.sha256(symvers.read_bytes()).hexdigest(),
            'clang_sha256': hashlib.sha256(compiler.read_bytes()).hexdigest(),
            'pahole_sha256': hashlib.sha256(pahole.read_bytes()).hexdigest(),
            'baseline_command': 'make ARCH=arm64 LLVM=1 LLVM_IAS=1 O=kernel-out vmlinux',
            'module_command': 'make ARCH=arm64 LLVM=1 LLVM_IAS=1 O=kernel-out M=source/driver modules',
        }
    (output_dir / f'{base}-build-info.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
    zip_path = output_dir / f'{base}-magisk.zip'
    with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for item in sorted(stage.iterdir()):
            info = zipfile.ZipInfo(item.name, date_time=(2026, 9, 28, 18, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = (item.stat().st_mode & 0xFFFF) << 16
            zf.writestr(info, item.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    (output_dir / f'{base}-ntsync.ko').write_bytes(module_binary.read_bytes())
    assets = sorted(output_dir.glob(f'{base}-*'))
    with (output_dir / 'SHA256SUMS').open('w') as checksums:
        for item in assets:
            checksums.write(f'{hashlib.sha256(item.read_bytes()).hexdigest()}  {item.name}\n')

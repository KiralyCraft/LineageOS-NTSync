import hashlib
import json
import pathlib
import shutil
import subprocess
import tempfile
import unittest
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]


class PackageTests(unittest.TestCase):
    def test_repeatable_magisk_archive_and_integrity(self):
        with tempfile.TemporaryDirectory() as temp:
            temp = pathlib.Path(temp)
            fake_module = temp / 'ntsync.ko'
            fake_module.write_bytes(b'ELF module test payload')
            outputs = []
            for index in (1, 2):
                output = temp / f'out{index}'
                subprocess.run(
                    ['python3', str(ROOT / 'build-support/package.py'),
                     str(ROOT), str(fake_module), str(output), 'test-commit'],
                    check=True,
                )
                zip_file = next(output.glob('*-magisk.zip'))
                outputs.append(zip_file.read_bytes())
                manifest = json.loads(next(output.glob('*-build-info.json')).read_text())
                self.assertEqual(manifest['module_sha256'], hashlib.sha256(fake_module.read_bytes()).hexdigest())
                with zipfile.ZipFile(zip_file) as zf:
                    self.assertEqual(zf.testzip(), None)
                    self.assertEqual(zf.read('ntsync.ko'), fake_module.read_bytes())
                    self.assertIn(b'0666 /dev/ntsync', zf.read('service.sh'))
            self.assertEqual(outputs[0], outputs[1])

    def test_profile_import_hashes_match_pinned_upstream(self):
        profile = json.loads((ROOT / 'profiles/current-install.json').read_text())
        for path, key in (
            ('driver/ntsync.c', 'ntsync_driver_sha256'),
            ('driver/include/uapi/linux/ntsync.h', 'ntsync_uapi_sha256'),
        ):
            digest = hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
            self.assertEqual(digest, profile[key])


if __name__ == '__main__':
    unittest.main()

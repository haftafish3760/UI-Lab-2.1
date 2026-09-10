import plistlib
from pathlib import Path
import tempfile
import unittest

from run_ios_restore_qa import QA_BUNDLE, verify_build, verify_bundle


class IOSRestoreIdentityTests(unittest.TestCase):
    def test_stale_copied_or_compiled_app_cannot_pass_preflight(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            for platform in ['iphoneos', 'iphonesimulator']:
                compiled = output / f'Debug-{platform}' / 'Runner.app'
                copied = output / platform / 'Runner.app'
                for app in [compiled, copied]:
                    app.mkdir(parents=True)
                for identities in [
                    ('com.maintainiac.uiLab21', QA_BUNDLE),
                    (QA_BUNDLE, 'com.maintainiac.uiLab21'),
                ]:
                    for app, identity in zip([compiled, copied], identities):
                        (app / 'Info.plist').write_bytes(plistlib.dumps(
                            {'CFBundleIdentifier': identity}))
                    with self.assertRaises(RuntimeError):
                        verify_build(output, platform)
                for app in [compiled, copied]:
                    (app / 'Info.plist').write_bytes(plistlib.dumps(
                        {'CFBundleIdentifier': QA_BUNDLE}))
                verify_build(output, platform)

    def test_normal_missing_and_malformed_identities_cannot_launch(self):
        with tempfile.TemporaryDirectory() as directory:
            app = Path(directory)
            for identity in ['com.maintainiac.uiLab21', 'com.maintainiac', None]:
                payload = {} if identity is None else {'CFBundleIdentifier': identity}
                (app / 'Info.plist').write_bytes(plistlib.dumps(payload))
                with self.assertRaises(RuntimeError):
                    verify_bundle(app)
            (app / 'Info.plist').write_bytes(b'not a plist')
            with self.assertRaises(plistlib.InvalidFileException):
                verify_bundle(app)
            (app / 'Info.plist').write_bytes(
                plistlib.dumps({'CFBundleIdentifier': QA_BUNDLE})
            )
            verify_bundle(app)


if __name__ == '__main__':
    unittest.main()

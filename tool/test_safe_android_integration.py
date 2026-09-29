import unittest
import subprocess
from unittest.mock import patch

from safe_android_integration import commands, require_qa_package, QA_PACKAGE, main


class DeviceRunnerSafetyTest(unittest.TestCase):
    def test_normal_or_unreadable_package_is_rejected(self):
        for output in ['', "package: name='com.tameyourbiz.app' versionCode='1'"]:
            with self.assertRaises(RuntimeError):
                require_qa_package(output)

    def test_verified_qa_identity_is_accepted(self):
        require_qa_package(f"package: name='{QA_PACKAGE}' versionCode='1'")

    def test_both_phases_use_qa_and_cleanup_is_disabled(self):
        build, test = commands('integration_test/example.dart', 'authorized-serial', ['FEATURE=true'])
        self.assertIn('--dart-define=STORAGE_QA=true', build)
        self.assertIn('--dart-define=STORAGE_QA=true', test)
        self.assertIn('--no-uninstall', test)
        self.assertEqual(test[test.index('-d') + 1], 'authorized-serial')

    def test_qa_override_and_malformed_defines_are_rejected(self):
        for value in ['STORAGE_QA=false', 'STORAGE_QA=true', 'bad']:
            with self.assertRaises(ValueError):
                commands('integration_test/example.dart', 'serial', [value])

    def invoke(self, outputs, failures=None):
        args = ['runner', 'integration_test/estimate_evidence_runtime_test.dart',
                '--device', 'test-serial', '--aapt', '/mock/aapt']
        with patch('sys.argv', args), patch(
            'safe_android_integration.subprocess.check_output', side_effect=outputs,
        ), patch('safe_android_integration.subprocess.run', side_effect=failures) as run:
            try:
                main()
            finally:
                self.invocations = [call.args[0] for call in run.call_args_list]

    def test_wrong_apk_never_reaches_device_test(self):
        with self.assertRaises(RuntimeError):
            self.invoke(['package:com.tameyourbiz.app\n',
                         "package: name='com.tameyourbiz.app'"])
        self.assertEqual(len(self.invocations), 1)
        self.assertEqual(self.invocations[0][:3], ['flutter', 'build', 'apk'])

    def test_failed_build_never_starts_device_test(self):
        with self.assertRaises(subprocess.CalledProcessError):
            self.invoke(['package:com.tameyourbiz.app\n'],
                        [subprocess.CalledProcessError(1, ['flutter', 'build'])])
        self.assertEqual(len(self.invocations), 1)

    def test_successful_run_keeps_cleanup_disabled(self):
        self.invoke(['package:com.tameyourbiz.app\n',
                     f"package: name='{QA_PACKAGE}'", 'package:com.tameyourbiz.app\n'])
        self.assertEqual(len(self.invocations), 2)
        self.assertIn('--no-uninstall', self.invocations[1])

    def test_missing_normal_package_is_reported_without_reinstall(self):
        with self.assertRaisesRegex(RuntimeError, 'Normal package disappeared'):
            self.invoke(['package:com.tameyourbiz.app\n',
                         f"package: name='{QA_PACKAGE}'", ''])
        self.assertEqual(len(self.invocations), 2)


if __name__ == '__main__':
    unittest.main()

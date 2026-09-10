import json
from pathlib import Path
import tempfile
import unittest
from run_storage_qa import evaluate_log, select_paths, fingerprint

class ReportEvidenceTests(unittest.TestCase):
    def evaluate(self, *, result='success', skip=False, done=True, done_success=True, finish=True, start=True, suite=True):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'events.jsonl'
            test = Path(folder) / 'example_test.dart'
            events = []
            if suite:
                events.append({'type': 'suite', 'suite': {'path': str(test)}})
            if start:
                events.append({'type': 'testStart', 'test': {'id': 1}})
            if finish:
                events.append({'type': 'testDone', 'testID': 1, 'result': result, 'skipped': skip, 'hidden': False})
            if done:
                events.append({'type': 'done', 'success': done_success})
            path.write_text('\n'.join(map(json.dumps, events)))
            return evaluate_log(path, [test.resolve()])

    def test_complete_executed_suite_passes(self):
        self.assertTrue(self.evaluate()['passed'])

    def test_terminal_failure_is_complete_but_not_successful(self):
        result = self.evaluate(done_success=False)
        self.assertTrue(result['protocol_completed'])
        self.assertFalse(result['protocol_success'])
        self.assertFalse(result['passed'])

    def test_false_green_signals_do_not_pass(self):
        for changes in ({'done': False}, {'result': 'failure'}, {'skip': True},
                        {'finish': False}, {'start': False}, {'suite': False},
                        {'finish': False, 'start': False}):
            with self.subTest(changes=changes):
                self.assertFalse(self.evaluate(**changes)['passed'])

class FingerprintTests(unittest.TestCase):
    def test_platform_entry_point_changes_invalidate_evidence(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for name in ('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml',
                         'tooling/storage_qa/suites.json', 'tooling/storage_qa/run_storage_qa.py'):
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.touch()
            target = root / 'integration_test' / 'runtime_test.dart'
            target.parent.mkdir()
            target.write_text('initial runtime check')
            before = fingerprint(root)
            target.write_text('changed runtime check')
            after = fingerprint(root)
            self.assertNotEqual(before['sha256'], after['sha256'])
            self.assertEqual(before['files'], after['files'])
            android = root / 'android/app/build.gradle.kts'
            android.parent.mkdir(parents=True)
            android.write_text('isolated test package configuration')
            self.assertNotEqual(after['sha256'], fingerprint(root)['sha256'])
            native = root / 'third_party/image_picker_android/android/src/main/Journal.java'
            native.parent.mkdir(parents=True)
            native.write_text('initial journal')
            baseline = fingerprint(root)
            native.write_text('changed journal')
            self.assertNotEqual(baseline['sha256'], fingerprint(root)['sha256'])
            probe = root / 'android/app/src/storageQa/java/Probe.java'
            probe.parent.mkdir(parents=True)
            probe.write_text('initial instrumentation')
            baseline = fingerprint(root)
            probe.write_text('changed instrumentation')
            self.assertNotEqual(baseline['sha256'], fingerprint(root)['sha256'])

class TestInventoryTests(unittest.TestCase):
    def test_all_discovers_nested_tests_and_excludes_helpers(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'test' / 'nested').mkdir(parents=True)
            for name in ['one_test.dart', 'nested/two_test.dart', 'nested/helper.dart']:
                (root / 'test' / name).touch()
            found = select_paths(root, {'suites': {}}, all_tests=True)
            self.assertEqual({p.name for p in found['all']}, {'one_test.dart', 'two_test.dart'})
            with self.assertRaises(ValueError):
                select_paths(root, {'suites': {}}, ['core'], all_tests=True)

    def test_empty_and_outside_test_inventory_fail_closed(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'test').mkdir()
            with self.assertRaises(ValueError):
                select_paths(root, {'suites': {}}, all_tests=True)
            (root / 'outside.dart').touch()
            (root / 'test' / 'escape_test.dart').symlink_to(root / 'outside.dart')
            with self.assertRaises(ValueError):
                select_paths(root, {'suites': {}}, all_tests=True)

if __name__ == '__main__':
    unittest.main()

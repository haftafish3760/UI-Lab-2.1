import json
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import unittest
from capture_android_database import CaptureError, CaptureOptions, capture, digest


class FakeAdb:
    def __init__(self, files, *, running_at=None, mutate_repeat=False, secondary=False):
        self.files = files
        self.secondary = secondary
        self.running_at = running_at
        self.mutate_repeat = mutate_repeat
        self.pid_checks = 0
        self.reads = {}

    def __call__(self, command, *, stdout, stderr, timeout, check):
        args = command[3:]
        status, data = 0, b''
        if args == ['get-state']:
            data = b'device\n'
        elif args[:2] == ['shell', 'pidof']:
            self.pid_checks += 1
            if self.pid_checks == self.running_at:
                data = b'2345\n'
            else:
                status = 1
        elif args[:2] == ['shell', 'ps']:
            data = b'NAME\ninit\n'
            if self.secondary:
                data += b'com.maintainiac.ui_lab_2_1:worker\n'
        elif args[:2] == ['shell', 'run-as']:
            data = ('\n'.join(self.files) + '\n').encode()
        elif args[:2] == ['exec-out', 'run-as']:
            name = args[-1].split('/')[-1]
            self.reads[name] = self.reads.get(name, 0) + 1
            data = self.files[name]
            if self.mutate_repeat and self.reads[name] > 1:
                data += b'changed'
        else:
            raise AssertionError('Unexpected ADB command: ' + repr(args))
        if stdout != subprocess.PIPE:
            stdout.write(data)
            data = None
        return subprocess.CompletedProcess(command, status, stdout=data, stderr=b'')


class AndroidCaptureTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.connection = sqlite3.connect(self.root / 'source.sqlite')
        self.connection.execute('PRAGMA journal_mode=WAL')
        self.connection.execute('PRAGMA wal_autocheckpoint=0')
        self.connection.execute('PRAGMA user_version=1')
        self.connection.execute('CREATE TABLE draft(value TEXT)')
        self.connection.execute("INSERT INTO draft VALUES ('unfinished 7.')")
        self.connection.commit()
        self.options = CaptureOptions(serial='emulator-test', output=self.root / 'capture')
        self.files = {
            'maintainiac.sqlite' + suffix: (self.root / ('source.sqlite' + suffix)).read_bytes()
            for suffix in ('', '-wal', '-shm')
        }

    def tearDown(self):
        self.connection.close()
        self.temporary.cleanup()

    def report(self):
        return json.loads((self.options.output / 'capture-report.json').read_text())

    def test_valid_wal_capture_preserves_exact_raw_files(self):
        result = capture(self.options, FakeAdb(self.files))
        self.assertTrue(result['capture_valid'])
        self.assertEqual(result['sqlite']['integrity_check'], 'ok')
        raw = self.options.output / 'raw'
        for name, expected in self.files.items():
            self.assertEqual((raw / name).read_bytes(), expected)
            self.assertEqual(digest(raw / name), result['files'][name])
        # Read another copy so this assertion also preserves the evidence set.
        proof = self.root / 'proof'
        proof.mkdir()
        for name in self.files:
            (proof / name).write_bytes((raw / name).read_bytes())
        with sqlite3.connect(proof / 'maintainiac.sqlite') as connection:
            self.assertEqual(connection.execute('SELECT value FROM draft').fetchall(), [('unfinished 7.',)])

    def test_running_app_refused_before_any_file_read(self):
        adb = FakeAdb(self.files, running_at=1)
        with self.assertRaises(CaptureError):
            capture(self.options, adb)
        self.assertEqual(adb.reads, {})
        self.assertFalse(self.report()['capture_valid'])

    def test_secondary_app_process_refused_before_file_read(self):
        adb = FakeAdb(self.files, secondary=True)
        with self.assertRaises(CaptureError):
            capture(self.options, adb)
        self.assertEqual(adb.reads, {})
        self.assertFalse(self.report()['capture_valid'])

    def test_restart_after_first_read_cannot_pass(self):
        with self.assertRaises(CaptureError):
            capture(self.options, FakeAdb(self.files, running_at=2))
        self.assertFalse(self.report()['capture_valid'])

    def test_changed_bytes_cannot_pass(self):
        with self.assertRaises(CaptureError):
            capture(self.options, FakeAdb(self.files, mutate_repeat=True))
        self.assertFalse(self.report()['capture_valid'])
        self.assertIn('changed', self.report()['error'])

    def test_corrupt_sqlite_cannot_pass(self):
        with self.assertRaises(sqlite3.DatabaseError):
            capture(self.options, FakeAdb({'maintainiac.sqlite': b'not a database'}))
        self.assertFalse(self.report()['capture_valid'])

    def test_foreign_key_violation_cannot_pass(self):
        self.connection.execute('CREATE TABLE parent(id INTEGER PRIMARY KEY)')
        self.connection.execute('CREATE TABLE child(parent_id INTEGER REFERENCES parent(id))')
        self.connection.execute('INSERT INTO child VALUES (99)')
        self.connection.commit()
        files = {
            'maintainiac.sqlite' + suffix: (self.root / ('source.sqlite' + suffix)).read_bytes()
            for suffix in ('', '-wal', '-shm')
        }
        with self.assertRaises(CaptureError):
            capture(self.options, FakeAdb(files))
        self.assertFalse(self.report()['capture_valid'])
        self.assertIn('foreign-key', self.report()['error'])

    def test_wrong_schema_cannot_pass(self):
        options = CaptureOptions(serial='device', output=self.options.output, expected_schema=2)
        with self.assertRaises(CaptureError):
            capture(options, FakeAdb(self.files))
        self.assertFalse(self.report()['capture_valid'])

    def test_previous_evidence_is_not_overwritten(self):
        self.options.output.mkdir()
        marker = self.options.output / 'capture-report.json'
        marker.write_text('previous evidence')
        with self.assertRaises(FileExistsError):
            capture(self.options, FakeAdb(self.files))
        self.assertEqual(marker.read_text(), 'previous evidence')

    def test_remote_shell_expressions_and_path_escape_are_rejected(self):
        for path in ('../other', '/data/system', 'files/$(id)', 'files;id'):
            with self.subTest(path=path), self.assertRaises(CaptureError):
                capture(CaptureOptions(serial='device', output=self.options.output, remote_directory=path), FakeAdb(self.files))
        self.assertFalse(self.options.output.exists())


if __name__ == '__main__':
    unittest.main()

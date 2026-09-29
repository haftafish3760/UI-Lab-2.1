from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from host_test_lease import HostTestLease


class HostTestLeaseTests(unittest.TestCase):
    def test_competing_process_is_refused_and_release_allows_retry(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'host.lock'
            script = (
                'from host_test_lease import HostTestLease\n'
                'import sys\n'
                'with HostTestLease(sys.argv[1]):\n'
                '    print("acquired")\n')
            def attempt():
                return subprocess.run(
                    [sys.executable, '-c', script, str(path)],
                    cwd=Path(__file__).parent, capture_output=True, text=True,
                    timeout=10)
            with HostTestLease(path):
                denied = attempt()
                self.assertNotEqual(denied.returncode, 0)
                self.assertNotIn('acquired', denied.stdout)
            self.assertEqual(attempt().returncode, 0)

    def test_process_death_does_not_leave_stale_lock(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'host.lock'
            script = (
                'from host_test_lease import HostTestLease\n'
                'import os, sys\n'
                'with HostTestLease(sys.argv[1]):\n'
                '    os._exit(0)\n')
            result = subprocess.run(
                [sys.executable, '-c', script, str(path)],
                cwd=Path(__file__).parent, timeout=10)
            self.assertEqual(result.returncode, 0)
            with HostTestLease(path):
                self.assertTrue(path.exists())

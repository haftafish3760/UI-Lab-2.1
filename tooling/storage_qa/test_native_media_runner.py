from pathlib import Path
import tempfile
import unittest
from run_native_media_qa import evaluate_junit


class NativeEvidenceTests(unittest.TestCase):
    def evaluate(self, xml, expected=('ExampleTest',)):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'TEST-ExampleTest.xml').write_text(xml)
            return evaluate_junit(root, expected)

    def test_complete_result(self):
        self.assertTrue(self.evaluate('<testsuite name="ExampleTest" tests="1"><testcase name="works"/></testsuite>')['passed'])

    def test_failed_or_skipped_case_rejected(self):
        for kind in ('failure', 'error', 'skipped'):
            count = {'failure': 'failures', 'error': 'errors', 'skipped': 'skipped'}[kind]
            xml = f'<testsuite name="ExampleTest" tests="1" {count}="1"><testcase><{kind}/></testcase></testsuite>'
            self.assertFalse(self.evaluate(xml)['passed'])

    def test_missing_class_rejected(self):
        self.assertFalse(self.evaluate('<testsuite name="ExampleTest" tests="1"><testcase/></testsuite>', ('ExampleTest', 'AbsentTest'))['passed'])

    def test_empty_malformed_and_false_counts_rejected(self):
        for xml in ('bad xml', '<testsuite name="ExampleTest" tests="0"/>',
                    '<testsuite name="ExampleTest" tests="2"><testcase/></testsuite>'):
            self.assertFalse(self.evaluate(xml)['passed'])


if __name__ == '__main__':
    unittest.main()

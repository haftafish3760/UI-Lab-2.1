import unittest

from tool.catalog_engine.run_qa import account, run


class QAAccountingTests(unittest.TestCase):
    def test_missing_skipped_failed_or_ambiguous_evidence_cannot_pass(self):
        requirements = [{"id": "R1", "tests": ["test_rule"]}]
        for outcomes in [{}, {"suite.test_rule": {"status": "skipped"}},
                         {"suite.test_rule": {"status": "failed"}},
                         {"a.test_rule": {"status": "passed"}, "b.test_rule": {"status": "passed"}}]:
            self.assertEqual(account(requirements, outcomes)[0]["status"], "incomplete")
        row = account(requirements, {"a.test_rule": {"status": "passed"}})[0]
        self.assertEqual(row["status"], "partial_evidence_passed")
        self.assertFalse(row["fully_verified"])

    def test_real_execution_captures_subtest_failures_and_skips(self):
        class Example(unittest.TestCase):
            def test_good(self):
                self.assertEqual(2 + 2, 4)

            def test_bad(self):
                with self.subTest(case="injected"):
                    self.assertEqual(2 + 2, 5)

            @unittest.skip("deliberately not verified")
            def test_skipped(self):
                pass

        report, _ = run(unittest.defaultTestLoader.loadTestsFromTestCase(Example), [])
        self.assertEqual(report["tests_run"], 3)
        self.assertEqual({x["status"] for x in report["tests"].values()}, {"passed", "failed", "skipped"})
        self.assertFalse(report["tests_passed"])
        self.assertFalse(report["release_ready"])

    def test_empty_suite_is_not_success(self):
        report, _ = run(unittest.TestSuite(), [])
        self.assertFalse(report["tests_passed"])

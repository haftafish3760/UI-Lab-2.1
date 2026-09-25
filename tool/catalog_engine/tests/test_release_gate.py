import copy
import unittest

from tool.catalog_engine.release_gate import evaluate


class ReleaseGateTests(unittest.TestCase):
    def setUp(self):
        self.policy = {"version": 1, "review_state": "approved", "checks": [
            {"id": "identity", "requirement_ids": ["REQ-ID"], "tier": "fast", "subjects": ["item-a", "item-b"]},
            {"id": "recovery", "requirement_ids": ["REQ-RECOVERY"], "tier": "release", "subjects": ["kill-after-write"]}]}
        self.binding = {"artifact_sha256": "a" * 64, "source_sha256": {"validator.py": "b" * 64}}
        self.reports = [{"check_id": c["id"], "status": "passed", **self.binding,
                         "subjects": c["subjects"], "findings": []} for c in self.policy["checks"]]

    def result(self):
        return evaluate(self.policy, self.reports, **self.binding)

    def test_complete_bound_evidence_can_pass_and_is_order_independent(self):
        first = self.result()
        self.assertTrue(first["release_ready"])
        self.reports.reverse()
        self.policy["checks"].reverse()
        self.assertEqual(first, self.result())

    def test_missing_tier_or_skipped_result_blocks(self):
        self.reports.pop()
        self.assertFalse(self.result()["release_ready"])
        self.assertIn("evidence.missing", {x["rule"] for x in self.result()["problems"]})
        for status in ["skipped", "unknown", "review", "expected_failure", "failed"]:
            self.reports[0]["status"] = status
            self.assertIn("evidence.not_passed", {x["rule"] for x in self.result()["problems"]})

    def test_green_report_for_wrong_artifact_or_code_is_stale(self):
        for field, value in [("artifact_sha256", "c" * 64), ("source_sha256", {"old.py": "b" * 64})]:
            original = self.reports[0][field]
            self.reports[0][field] = value
            self.assertFalse(self.result()["release_ready"])
            self.reports[0][field] = original

    def test_partial_duplicate_and_extra_subjects_are_not_full_coverage(self):
        for subjects in [["item-a"], ["item-a", "item-a"], ["item-a", "item-b", "item-c"], None]:
            self.reports[0]["subjects"] = subjects
            self.assertFalse(self.result()["release_ready"])

    def test_conflicting_reports_cannot_overwrite_failure(self):
        failed = copy.deepcopy(self.reports[0])
        failed["status"] = "failed"
        self.reports.insert(0, failed)
        self.assertFalse(self.result()["release_ready"])

    def test_unknown_policy_or_review_cannot_be_green(self):
        self.policy["review_state"] = "draft"
        self.assertFalse(self.result()["release_ready"])
        self.policy["review_state"] = "approved"
        for severity in ["error", "review", "unknown", None]:
            self.reports[0]["findings"] = [{"severity": severity, "resolved": True}]
            self.assertFalse(self.result()["release_ready"])
        self.reports[0]["findings"] = [{"severity": "warning"}]
        self.assertTrue(self.result()["release_ready"])

    def test_empty_checks_and_missing_requirement_links_are_rejected(self):
        self.policy["checks"][0]["requirement_ids"] = []
        self.assertFalse(self.result()["release_ready"])
        self.policy["checks"] = []
        self.reports = []
        self.assertFalse(self.result()["release_ready"])

    def test_staging_artifact_cannot_pass_actual_release_policy(self):
        from pathlib import Path
        import tempfile
        from tool.catalog_engine.generate import build
        from tool.catalog_engine.verify_release import assess
        root = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as directory:
            artifact = Path(directory) / "pack.sqlite"
            build(root / "definitions/families.json", root / "fixtures/candidates.json", artifact)
            result = assess(artifact)
            self.assertTrue(result["artifact_validation"]["structural_pass"])
            self.assertFalse(result["gate"]["release_ready"])
            missing = {p["subject"] for p in result["gate"]["problems"] if p["rule"] == "evidence.missing"}
            self.assertIn("inventory_persistence", missing)
            self.assertIn("parser_accuracy", missing)
            self.assertIn("oracle_independence", missing)

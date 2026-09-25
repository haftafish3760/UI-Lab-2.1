"""Run tests and account for missing requirement evidence without claiming release.

Reports come from unittest events, not a manually populated 'passed' list. They
bind to source fingerprints and retain skipped/expected-failure/untested states.
This development report is not an authorization signature or factual oracle.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
REPO = ROOT.parent
TRACEABILITY = REPO / "docs/inventory_migration/catalog_requirements_traceability.json"


class EvidenceResult(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.outcomes = {}

    def startTest(self, test):
        super().startTest(test)
        self.outcomes[test.id()] = {"status": "running"}

    def addSuccess(self, test):
        super().addSuccess(test)
        if self.outcomes[test.id()]["status"] == "running":
            self.outcomes[test.id()] = {"status": "passed"}

    def addFailure(self, test, err):
        super().addFailure(test, err)
        self.outcomes[test.id()] = {"status": "failed", "detail": self._exc_info_to_string(err, test)}

    def addError(self, test, err):
        super().addError(test, err)
        self.outcomes[test.id()] = {"status": "error", "detail": self._exc_info_to_string(err, test)}

    def addSkip(self, test, reason):
        super().addSkip(test, reason)
        self.outcomes[test.id()] = {"status": "skipped", "detail": reason}

    def addExpectedFailure(self, test, err):
        super().addExpectedFailure(test, err)
        self.outcomes[test.id()] = {"status": "expected_failure"}

    def addUnexpectedSuccess(self, test):
        super().addUnexpectedSuccess(test)
        self.outcomes[test.id()] = {"status": "unexpected_success"}

    def addSubTest(self, test, subtest, err):
        super().addSubTest(test, subtest, err)
        if err is not None:
            self.outcomes[test.id()] = {"status": "failed", "detail": str(subtest)}


def account(requirements, outcomes):
    """Unmapped, ambiguous, skipped and failing evidence never become passes."""
    rows = []
    for requirement in requirements:
        matches = {}
        for name in requirement["tests"]:
            ids = [test_id for test_id in outcomes if test_id == name or test_id.endswith("." + name)]
            matches[name] = (outcomes[ids[0]]["status"] if len(ids) == 1 else
                             "not_executed" if not ids else "ambiguous_test_name")
        rows.append({"id": requirement["id"], "mapped_evidence": matches,
                     "status": "partial_evidence_passed" if matches and
                     all(s == "passed" for s in matches.values()) else "incomplete",
                     "fully_verified": False})
    return rows


def run(suite, requirements):
    stream = io.StringIO()
    result = unittest.TextTestRunner(stream=stream, verbosity=2, resultclass=EvidenceResult).run(suite)
    rows = account(requirements, result.outcomes)
    return {"format_version": 1, "tests_run": result.testsRun,
            "tests_passed": result.wasSuccessful() and result.testsRun > 0 and
            all(x["status"] == "passed" for x in result.outcomes.values()),
            "release_ready": False, "tests": dict(sorted(result.outcomes.items())),
            "requirements": rows,
            "coverage": {"requirements_total": len(rows), "requirements_fully_verified": 0,
                         "requirements_with_some_passing_evidence": sum(
                             r["status"] == "partial_evidence_passed" for r in rows),
                         "requirements_without_mapped_tests": sum(not r["mapped_evidence"] for r in rows)}}, stream.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    requirements = json.loads(TRACEABILITY.read_text(encoding="utf-8"))["requirements"]
    def fingerprints():
        paths = sorted(p for p in (ROOT / "catalog_engine").rglob("*")
                       if p.suffix in {".py", ".json"}) + [TRACEABILITY]
        return {str(p.relative_to(REPO)).replace("\\", "/"):
                hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}

    before = fingerprints()
    loader = unittest.TestLoader()
    suite = loader.discover(str(ROOT / "catalog_engine/tests"), top_level_dir=str(REPO))
    report, log = run(suite, requirements)
    report["source_sha256"] = before
    report["inputs_unchanged_during_run"] = before == fingerprints()
    report["tests_passed"] &= report["inputs_unchanged_during_run"]
    # Exclusive report creation retains past runs and prevents accidental loss.
    args.report.parent.mkdir(parents=True, exist_ok=True)
    with args.report.open("x", encoding="utf-8") as output:
        json.dump(report, output, indent=2, ensure_ascii=False)
        output.write("\n")
    print(log)
    print(json.dumps(report["coverage"]))
    return 0 if report["tests_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())

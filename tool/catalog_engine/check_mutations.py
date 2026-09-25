"""Deliberately disable selected validator rules in disposable copies only."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

MUTANTS = [
    ("duplicate_check_disabled", 'issue("identity.duplicate", item_id, identities[key], "One row per canonical identity")',
     "pass", "test_duplicate_disguised_by_fraction_format_is_detected"),
    ("stable_identity_check_disabled", 'issue("identity.stable_id", item_id, item_id, expected_id)',
     "pass", "test_mutated_dimension_breaks_stable_identity"),
    ("scope_check_disabled", 'issue("scope.missing_family", trade, family, "Declared family has reachable candidates")',
     "pass", "test_missing_whole_family_is_not_hidden_by_valid_remaining_rows"),
    ("scope_contract_disabled", 'issue("scope.contract", "pack", scope, expected_scope)',
     "pass", "test_pack_cannot_hide_missing_family_by_rewriting_its_scope"),
    ("sqlite_schema_contract_disabled", 'check_schema(db)',
     "pass", "test_removed_foreign_key_constraints_cannot_bypass_integrity_check"),
]


def check():
    results = []
    source = Path(__file__).resolve().parent
    for name, old, new, test in MUTANTS:
        with tempfile.TemporaryDirectory(prefix="catalog-mutation-") as directory:
            root = Path(directory)
            destination = root / "tool/catalog_engine"
            shutil.copytree(source, destination, ignore=shutil.ignore_patterns("__pycache__"))
            validator = destination / "validate.py"
            original = validator.read_text(encoding="utf-8")
            if original.count(old) != 1:
                raise ValueError(f"Mutation target changed: {name}")
            command = [sys.executable, "-m", "unittest",
                       "tool.catalog_engine.tests.test_engine.CatalogEngineeringTests." + test]
            baseline = subprocess.run(command, cwd=root, capture_output=True, text=True, timeout=30)
            validator.write_text(original.replace(old, new), encoding="utf-8")
            mutant = subprocess.run(command, cwd=root, capture_output=True, text=True, timeout=30)
            # An import error or crash is not accepted as the expected assertion failure.
            killed = baseline.returncode == 0 and mutant.returncode != 0 and "AssertionError" in mutant.stderr and "FAILED (failures=1)" in mutant.stderr
            results.append({"mutation": name, "test": test, "baseline_pass": baseline.returncode == 0,
                            "detected": killed, "failure_output": mutant.stderr})
    return {"scope": "targeted validator mutants; not exhaustive mutation coverage",
            "all_detected": all(r["detected"] for r in results), "results": results}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    result = check()
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"Detected {sum(r['detected'] for r in result['results'])}/{len(result['results'])} validator mutations")
    raise SystemExit(0 if result["all_detected"] else 1)

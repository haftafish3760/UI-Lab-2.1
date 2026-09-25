import copy
import json
from pathlib import Path
import tempfile
import unittest

from tool.catalog_engine.compare import compare
from tool.catalog_engine.generate import build

ROOT = Path(__file__).resolve().parents[1]


class ComparisonTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.source = json.loads((ROOT / "fixtures/candidates.json").read_text())
        self.before = self.make(self.source, "before")

    def make(self, source, name):
        path = self.directory / (name + ".json")
        path.write_text(json.dumps(source), encoding="utf-8")
        output = self.directory / (name + ".sqlite")
        build(ROOT / "definitions/families.json", path, output)
        return output

    def test_reordering_is_not_a_semantic_change_and_comparison_is_read_only(self):
        self.source["candidates"].reverse()
        after = self.make(self.source, "after")
        original = (self.before.read_bytes(), after.read_bytes())
        report = compare(self.before, after)
        self.assertEqual(report["changes"], [])
        self.assertEqual(report["blockers"], [])
        self.assertEqual(original, (self.before.read_bytes(), after.read_bytes()))
        self.assertEqual(report, compare(self.before, after))

    def test_alias_and_category_rename_preserve_identity(self):
        self.source["candidates"][0]["aliases"].append("owner-independent spelling")
        self.source["nodes"][3]["label"] = "Pipe fittings"
        report = compare(self.before, self.make(self.source, "after"))
        self.assertEqual(report["summary"]["added"], 0)
        self.assertEqual(report["summary"]["removed"], 0)
        self.assertEqual({c["kind"] for c in report["changes"]}, {"item_aliases", "nodes_changed"})

    def test_branch_replacement_requires_migration_and_triggers_blast_radius(self):
        self.source["candidates"][2]["ports"]["branch"]["size"] = "7/8"
        report = compare(self.before, self.make(self.source, "after"))
        self.assertEqual(report["summary"]["removed"], 1)
        self.assertEqual(report["summary"]["added"], 1)
        self.assertEqual({b["rule"] for b in report["blockers"]},
                         {"update.migration_required", "update.blast_radius"})

    def test_losing_shared_trade_does_not_look_like_harmless_label_change(self):
        # Keep HVAC tee coverage but move it from the shared reducing tee to the
        # equal tee: whole-family coverage alone would miss this stock risk.
        self.source["candidates"][1]["paths"] = ["p_fittings"]
        self.source["candidates"][3]["paths"].append("h_fittings")
        report = compare(self.before, self.make(self.source, "after"))
        self.assertIn("update.trade_loss", {b["rule"] for b in report["blockers"]})
        self.assertEqual(report["summary"]["removed"], 0)

    def test_provenance_change_is_high_risk_even_with_unchanged_items(self):
        self.source["sources"][0]["note"] = "Changed evidence statement"
        report = compare(self.before, self.make(self.source, "after"))
        self.assertEqual(report["summary"]["high_risk_changes"], 1)
        self.assertEqual(report["changes"][0]["kind"], "sources_changed")

    def test_invalid_artifact_cannot_be_baseline(self):
        bad = self.directory / "bad.sqlite"
        bad.write_bytes(b"bad")
        with self.assertRaises(ValueError):
            compare(bad, self.before)

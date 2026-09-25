import copy
from contextlib import closing
import hashlib
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest

from tool.catalog_engine.generate import build
from tool.catalog_engine.variants import expand_recipe
from tool.catalog_engine.validate import validate

ROOT = Path(__file__).resolve().parents[1]


class VariantTests(unittest.TestCase):
    def setUp(self):
        source = json.loads((ROOT / "fixtures/candidates.json").read_text())
        self.recipe = {"format_version": 1, "source": source, "variant_batches": [{
            "template": copy.deepcopy(source["candidates"][0]),
            "columns": ["ports.run_a.size", "ports.run_b.size", "ports.branch.size"],
            "rows": [["1", "3/4", "1/2"], ["3/4", "1", "1/2"], ["1", "3/4", "3/4"]]}]}

    def test_expansion_emits_only_explicit_rows_without_mutating_recipe(self):
        before = copy.deepcopy(self.recipe)
        output = expand_recipe(self.recipe)
        self.assertEqual(len(output["candidates"]), 9)
        self.assertEqual([r["ports"]["branch"]["size"] for r in output["candidates"][-3:]],
                         ["1/2", "1/2", "3/4"])
        self.assertEqual(self.recipe, before)

    def test_recipe_build_deduplicates_reversal_and_retains_recipe_fingerprint(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "recipe.json"
            source.write_text(json.dumps(self.recipe))
            artifact = Path(directory) / "recipe.sqlite"
            result = build(ROOT / "definitions/families.json", source, artifact, recipe=True)
            self.assertEqual(result["canonical_count"], 7)
            self.assertTrue(validate(artifact)["structural_pass"])
            with closing(sqlite3.connect(artifact)) as db:
                fingerprint = db.execute("SELECT value FROM metadata WHERE key='inputs_sha256'").fetchone()[0]
            self.assertEqual(fingerprint, hashlib.sha256(source.read_bytes()).hexdigest())

    def test_recipe_cannot_execute_code_or_override_provenance(self):
        for column in ["source", "__class__", "ports.branch.size.__class__", "attributes.unknown",
                       "__import__('os').system('anything')"]:
            recipe = copy.deepcopy(self.recipe)
            recipe["variant_batches"][0]["columns"][0] = column
            with self.assertRaises(ValueError):
                expand_recipe(recipe)

    def test_expansion_bound_and_ambiguous_table_rejected(self):
        with self.assertRaises(ValueError):
            expand_recipe(self.recipe, maximum_candidates=8)
        for columns, rows in [(["ports.run_a.size"] * 2, [["1", "2"]]),
                              (["ports.run_a.size"], [["1", "2"]]),
                              (["ports.run_a.size"], [])]:
            recipe = copy.deepcopy(self.recipe)
            recipe["variant_batches"][0].update(columns=columns, rows=rows)
            with self.assertRaises(ValueError):
                expand_recipe(recipe)

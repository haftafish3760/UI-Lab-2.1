import copy
import json
from pathlib import Path
import tempfile
import unittest

from tool.catalog_engine.generate import build
from tool.catalog_engine.input_contract import check_definitions, check_source, load_json

ROOT = Path(__file__).resolve().parents[1]


class InputContractTests(unittest.TestCase):
    def setUp(self):
        self.definitions = load_json(ROOT / "definitions/families.json")
        self.source = load_json(ROOT / "fixtures/candidates.json")

    def test_overlap_unknown_and_degenerate_symmetries_are_rejected(self):
        for groups in [[["run_a", "run_b"], ["run_b", "branch"]],
                       [["run_a", "missing"]], [["run_a"]], [["run_a", "run_a"]]]:
            with self.subTest(groups=groups):
                value = copy.deepcopy(self.definitions)
                value["families"][0]["interchangeable_ports"] = groups
                with self.assertRaises(ValueError):
                    check_definitions(value)

    def test_unknown_private_field_is_rejected_at_every_input_boundary(self):
        for target in [self.source, self.source["nodes"][0], self.source["sources"][0],
                       self.source["candidates"][0], self.source["candidates"][0]["ports"]["branch"]]:
            target["customer_email"] = "private@example.test"
            with self.assertRaises(ValueError):
                check_source(self.source)
            del target["customer_email"]

    def test_duplicate_json_keys_are_not_silently_last_value_wins(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "input.json"
            path.write_text('{"version":1,"version":2}')
            with self.assertRaises(ValueError):
                load_json(path)

    def test_corrupt_unicode_and_alias_shape_rejected_before_output_exists(self):
        for aliases in ["not-a-list", [], ["bad\ud800"], ["a" * 201], ["hidden\x00suffix"]]:
            with self.subTest(aliases=repr(aliases)), tempfile.TemporaryDirectory() as directory:
                self.source["candidates"][0]["aliases"] = aliases
                path = Path(directory) / "source.json"
                path.write_text(json.dumps(self.source))
                output = Path(directory) / "artifact.sqlite"
                with self.assertRaises(ValueError):
                    build(ROOT / "definitions/families.json", path, output)
                self.assertFalse(output.exists())

    def test_forged_verification_rejected_before_generation(self):
        self.source["sources"][0]["verification"] = "verified"
        with self.assertRaises(ValueError):
            check_source(self.source)

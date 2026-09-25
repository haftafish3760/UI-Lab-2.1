import copy
from contextlib import closing
import hashlib
import json
from pathlib import Path
import random
import sqlite3
import subprocess
import sys
import tempfile
import unittest

from tool.catalog_engine.generate import build, canonical, dimension
from tool.catalog_engine.validate import validate

ROOT = Path(__file__).resolve().parents[1]
DEFINITIONS = ROOT / "definitions/families.json"
CANDIDATES = ROOT / "fixtures/candidates.json"


class CatalogEngineeringTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.db = self.directory / "catalog.sqlite"
        self.source = json.loads(CANDIDATES.read_text(encoding="utf-8"))
        self.family = json.loads(DEFINITIONS.read_text())["families"][0]

    def generate(self, source=None, name="catalog.sqlite"):
        candidate = self.directory / (name + ".json")
        candidate.write_text(json.dumps(source or self.source), encoding="utf-8")
        target = self.directory / name
        build(DEFINITIONS, candidate, target)
        return target

    def rules(self, path=None):
        return {i["rule"] for i in validate(path or self.db)["issues"]}

    def mutate(self, sql, parameters=()):
        with closing(sqlite3.connect(self.db)) as db, db:
            db.execute(sql, parameters)

    def test_valid_fixture_structural_pass_is_not_release_pass(self):
        self.generate()
        report = validate(self.db)
        self.assertTrue(report["structural_pass"], report)
        self.assertFalse(report["release_ready"])
        self.assertEqual(report["coverage"]["items_examined"], 5)
        self.assertEqual(report["coverage"]["associations_examined"], 6)
        self.assertEqual(report["coverage"]["factual_items_verified"], 0)
        self.assertIn("inventory_persistence", report["coverage"]["unimplemented_release_gates"])

    def test_reversed_run_deduplicates_but_branch_change_does_not(self):
        self.generate()
        with closing(sqlite3.connect(self.db)) as db, db:
            tees = [json.loads(r[0]) for r in db.execute("SELECT identity FROM items")
                    if json.loads(r[0])["family"] == "pressure_tee"]
        self.assertEqual(len(tees), 3)
        signatures = {(t["ports"]["run_a"]["size"], t["ports"]["run_b"]["size"],
                       t["ports"]["branch"]["size"]) for t in tees}
        # Hand-specified expectations from the owner's run/run/branch example.
        self.assertEqual(signatures, {("1/2", "3/4", "1/2"),
                                      ("1/2", "3/4", "3/4"),
                                      ("1/2", "1/2", "1/2")})

    def test_metadata_order_aliases_do_not_change_identity(self):
        row = copy.deepcopy(self.source["candidates"][0])
        first = canonical(row, self.family)[0]
        row["paths"] = ["other-navigation"]
        row["aliases"] = ["renamed"]
        row["attributes"]["material"] = " COPPER "
        row["ports"]["run_a"]["size"] = "0.75"
        self.assertEqual(canonical(row, self.family)[0], first)
        row["ports"]["branch"]["size"] = "1"
        self.assertNotEqual(canonical(row, self.family)[0], first)

    def test_connections_travel_with_run_sizes(self):
        row = copy.deepcopy(self.source["candidates"][0])
        row["ports"]["run_a"]["connection"] = "male_thread"
        key = canonical(row, self.family)[0]
        row["ports"]["run_a"], row["ports"]["run_b"] = row["ports"]["run_b"], row["ports"]["run_a"]
        self.assertEqual(key, canonical(row, self.family)[0])
        row["ports"]["run_a"]["size"], row["ports"]["run_b"]["size"] = row["ports"]["run_b"]["size"], row["ports"]["run_a"]["size"]
        self.assertNotEqual(key, canonical(row, self.family)[0])

    def test_seeded_run_reversal_property(self):
        randomizer = random.Random(918)
        for _ in range(120):
            row = copy.deepcopy(self.source["candidates"][0])
            for port in row["ports"].values():
                port["size"] = randomizer.choice(["1/8", "1/4", "1/2", "3/4", "1", "1 1/4"])
            first = canonical(row, self.family)[0]
            row["ports"]["run_a"], row["ports"]["run_b"] = row["ports"]["run_b"], row["ports"]["run_a"]
            self.assertEqual(first, canonical(row, self.family)[0], "seed=918")

    def test_numeric_boundary_and_malformed_inputs(self):
        for value in ["0", "-1", "1/0", "NaN", "1e2", "1/2/3", "10001", "", "1" * 33]:
            with self.subTest(value=value), self.assertRaises((ValueError, ZeroDivisionError)):
                dimension(value)
        self.assertEqual(dimension("1 1/4"), "5/4")

    def test_nominal_and_actual_never_collapse(self):
        row = copy.deepcopy(self.source["candidates"][0])
        first = canonical(row, self.family)[0]
        for port in row["ports"].values():
            port["basis"] = "actual"
        self.assertNotEqual(first, canonical(row, self.family)[0])

    def test_actual_lengths_convert_exactly_but_nominal_sizes_do_not(self):
        inch = copy.deepcopy(self.source["candidates"][0])
        metric = copy.deepcopy(inch)
        # Literal exact metric counterparts, not calculated by production code.
        for row in (inch, metric):
            for port in row["ports"].values():
                port["basis"] = "actual"
        for role, size in [("run_a", "19.05"), ("run_b", "12.7"), ("branch", "12.7")]:
            metric["ports"][role]["size"] = size
            metric["ports"][role]["unit"] = "mm"
        self.assertEqual(canonical(inch, self.family)[0], canonical(metric, self.family)[0])
        for row in (inch, metric):
            for port in row["ports"].values():
                port["basis"] = "nominal"
        self.assertNotEqual(canonical(inch, self.family)[0], canonical(metric, self.family)[0])

    def test_metric_equivalence_does_not_hide_duplicate_in_external_artifact(self):
        # Keep original nominal rows to maintain declared scope; add an actual
        # engineering example, then inject a disguised imperial duplicate.
        row = copy.deepcopy(self.source["candidates"][0])
        for port in row["ports"].values():
            port["basis"] = "actual"
        self.source["candidates"].append(row)
        self.generate()
        with closing(sqlite3.connect(self.db)) as db, db:
            raw = db.execute("SELECT identity FROM items WHERE identity LIKE '%actual%' LIMIT 1").fetchone()[0]
            identity = json.loads(raw)
            for port in identity["ports"].values():
                port["size"] = "3/4" if port["size"] == "381/20" else "1/2"
                port["unit"] = "in"
            db.execute("INSERT INTO items VALUES (?,?)", ("disguised-inch", json.dumps(identity)))
        self.assertIn("identity.duplicate", self.rules())

    def test_actual_length_budget_applies_after_conversion(self):
        row = copy.deepcopy(self.source["candidates"][0])
        for port in row["ports"].values():
            port.update(size="400", basis="actual", unit="in")
        with self.assertRaises(ValueError):
            canonical(row, self.family)

    def test_rows_reordered_produce_same_identities(self):
        first = self.generate()
        reordered = copy.deepcopy(self.source)
        reordered["candidates"].reverse()
        reordered["nodes"].reverse()
        second = self.generate(reordered, "second.sqlite")
        with closing(sqlite3.connect(first)) as a, closing(sqlite3.connect(second)) as b:
            for table in ["items", "associations", "aliases", "evidence"]:
                self.assertEqual(sorted(a.execute(f"SELECT * FROM {table}")), sorted(b.execute(f"SELECT * FROM {table}")))

    def test_duplicate_disguised_by_fraction_format_is_detected(self):
        self.generate()
        with closing(sqlite3.connect(self.db)) as db, db:
            raw = db.execute("SELECT identity FROM items WHERE identity LIKE '%pressure_tee%' LIMIT 1").fetchone()[0]
            changed = json.loads(raw)
            changed["ports"]["run_a"]["size"] = "0.5"
            db.execute("INSERT INTO items VALUES (?,?)", ("wrong_duplicate_id", json.dumps(changed)))
        self.assertIn("identity.duplicate", self.rules())

    def test_mutated_dimension_breaks_stable_identity(self):
        self.generate()
        with closing(sqlite3.connect(self.db)) as db, db:
            item, raw = db.execute("SELECT id,identity FROM items WHERE identity LIKE '%pressure_tee%' LIMIT 1").fetchone()
            changed = json.loads(raw)
            changed["ports"]["branch"]["size"] = "9"
            db.execute("UPDATE items SET identity=? WHERE id=?", (json.dumps(changed), item))
        self.assertIn("identity.stable_id", self.rules())

    def test_orphan_cycle_and_wrong_trade_are_detected(self):
        for sql, rule in [
            ("UPDATE nodes SET parent='missing' WHERE id='p_fittings'", "graph.orphan"),
            ("UPDATE nodes SET parent='p_fittings' WHERE id='plumbing'", "graph.cycle"),
            ("UPDATE nodes SET trade='roofing' WHERE id='p_fittings'", "classification.trade"),
        ]:
            with self.subTest(rule=rule):
                path = self.generate(name=rule + ".sqlite")
                with closing(sqlite3.connect(path)) as db, db:
                    db.execute(sql)
                self.assertIn(rule, self.rules(path))

    def test_missing_whole_family_is_not_hidden_by_valid_remaining_rows(self):
        self.generate()
        self.mutate("DELETE FROM associations WHERE node='e_wire'")
        self.assertIn("scope.missing_family", self.rules())
        self.assertIn("graph.unreachable", self.rules())

    def test_forged_verified_evidence_is_rejected(self):
        self.generate()
        self.mutate("UPDATE sources SET payload=?", (json.dumps({"classification": "manufacturer", "verification": "verified"}),))
        self.assertIn("evidence.unsupported_claim", self.rules())

    def test_pack_cannot_hide_missing_family_by_rewriting_its_scope(self):
        self.generate()
        self.mutate("DELETE FROM associations WHERE node='e_wire'")
        self.mutate("UPDATE metadata SET value='{}' WHERE key='scope'")
        self.assertIn("scope.contract", self.rules())
        self.assertIn("scope.missing_family", self.rules())

    def test_scope_malformed_duplicates_and_unknown_trade_are_rejected(self):
        for number, scope in enumerate([None, [], {"plumbing": "pressure_tee"},
                                       {"roofing": ["conductor"]},
                                       {"plumbing": ["pressure_tee", "pressure_tee"]}]):
            with self.subTest(scope=scope):
                path = self.generate(name=f"scope-{number}.sqlite")
                with closing(sqlite3.connect(path)) as db, db:
                    db.execute("UPDATE metadata SET value=? WHERE key='scope'", (json.dumps(scope),))
                self.assertIn("scope.contract", self.rules(path))

    def test_validator_does_not_repair_or_change_evidence(self):
        self.generate()
        self.mutate("DELETE FROM evidence")
        before = self.db.read_bytes()
        first = validate(self.db)
        self.assertEqual(first, validate(self.db))
        self.assertEqual(before, self.db.read_bytes())
        self.assertIn("evidence.missing", self.rules())

    def test_bad_sqlite_and_unknown_schema_rejected(self):
        self.db.write_bytes(b"not a database")
        self.assertFalse(validate(self.db)["structural_pass"])
        path = self.generate(name="version.sqlite")
        with closing(sqlite3.connect(path)) as db, db:
            db.execute("PRAGMA user_version=999")
        self.assertFalse(validate(path)["structural_pass"])

    def test_extra_private_tables_rejected(self):
        self.generate()
        self.mutate("CREATE TABLE user_inventory(secret TEXT)")
        self.assertIn("artifact.invalid", self.rules())

    def test_removed_foreign_key_constraints_cannot_bypass_integrity_check(self):
        self.generate()
        with closing(sqlite3.connect(self.db)) as db, db:
            db.execute("ALTER TABLE aliases RENAME TO old_aliases")
            db.execute("CREATE TABLE aliases(item TEXT, value TEXT, PRIMARY KEY(item,value))")
            db.execute("INSERT INTO aliases SELECT * FROM old_aliases")
            db.execute("DROP TABLE old_aliases")
            db.execute("INSERT INTO aliases VALUES ('missing-item','hidden orphan')")
            self.assertEqual(list(db.execute("PRAGMA foreign_key_check")), [])
        self.assertIn("artifact.invalid", self.rules())

    def test_private_column_or_null_primary_key_is_rejected(self):
        for number, sql in enumerate(["ALTER TABLE items ADD COLUMN customer_email TEXT",
                                      "UPDATE sources SET id=NULL"]):
            path = self.generate(name=f"schema-{number}.sqlite")
            with closing(sqlite3.connect(path)) as db, db:
                db.execute(sql)
            self.assertIn("artifact.invalid", self.rules(path))

    def test_private_source_field_cannot_hide_inside_allowed_table(self):
        self.generate()
        source = copy.deepcopy(self.source["sources"][0])
        source["customer_email"] = "private@example.test"
        self.mutate("UPDATE sources SET payload=?", (json.dumps(source),))
        self.assertIn("evidence.record_shape", self.rules())
        self.mutate("INSERT INTO metadata VALUES ('account_id','private-account')")
        self.assertIn("metadata.fields", self.rules())

    def test_missing_alias_or_unbounded_alias_fails_search_preconditions(self):
        self.generate()
        self.mutate("UPDATE aliases SET value=?", ("x" * 201,))
        self.assertIn("alias.invalid", self.rules())
        self.mutate("DELETE FROM aliases")
        self.assertIn("search.no_alias", self.rules())

    def test_generator_refuses_overwrite_and_rolls_back_failed_build(self):
        self.generate()
        before = self.db.read_bytes()
        with self.assertRaises(FileExistsError):
            self.generate()
        self.assertEqual(before, self.db.read_bytes())
        bad = copy.deepcopy(self.source)
        bad["candidates"][0]["paths"] = ["does-not-exist"]
        with self.assertRaises(sqlite3.IntegrityError):
            self.generate(bad, "failed.sqlite")
        self.assertFalse((self.directory / "failed.sqlite").exists())

    def test_post_build_cli_has_real_release_failure_exit(self):
        self.generate()
        report = self.directory / "report.json"
        command = [sys.executable, "-m", "tool.catalog_engine.validate", str(self.db), "--report", str(report)]
        normal = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(normal.returncode, 0, normal.stderr)
        release = subprocess.run(command + ["--release"], capture_output=True, text=True)
        self.assertEqual(release.returncode, 1)
        self.assertFalse(json.loads(report.read_text())["release_ready"])

    def test_validator_has_no_generator_import_or_definition_dependency(self):
        import ast
        tree = ast.parse((ROOT / "validate.py").read_text())
        imports = [n.module for n in ast.walk(tree) if isinstance(n, ast.ImportFrom)]
        self.assertFalse(any("generate" in (name or "") for name in imports))
        self.assertNotIn("families.json", (ROOT / "validate.py").read_text())

    def test_malformed_json_shapes_are_reported_not_crashes(self):
        for raw in ['null', '[]', '"text"', '{"version":1}']:
            with self.subTest(raw=raw):
                path = self.generate(name=hashlib.sha256(raw.encode()).hexdigest() + ".sqlite")
                with closing(sqlite3.connect(path)) as db, db:
                    db.execute("UPDATE items SET identity=? WHERE id=(SELECT id FROM items LIMIT 1)", (raw,))
                self.assertIn("family.invalid", self.rules(path))

    def test_bad_units_and_family_fields_are_rejected(self):
        for defect in ["unit", "branch", "connection"]:
            with self.subTest(defect=defect):
                path = self.generate(name=defect + ".sqlite")
                with closing(sqlite3.connect(path)) as db, db:
                    item, raw = db.execute("SELECT id,identity FROM items WHERE identity LIKE '%pressure_tee%' LIMIT 1").fetchone()
                    identity = json.loads(raw)
                    if defect == "branch":
                        del identity["ports"]["branch"]
                    else:
                        identity["ports"]["branch"][defect] = "amps"
                    db.execute("UPDATE items SET identity=? WHERE id=?", (json.dumps(identity), item))
                self.assertIn("family.invalid", self.rules(path))


if __name__ == "__main__":
    unittest.main()

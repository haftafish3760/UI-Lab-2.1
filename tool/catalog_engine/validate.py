"""Read-only post-build validator. Does not import generator code or definitions.

This first rule set validates synthetic engineering artifacts, not factual products.
Release remains blocked until the complete required evidence suite is implemented.
"""
import argparse
import hashlib
import json
import re
import sqlite3
from fractions import Fraction
from pathlib import Path

from .sqlite_policy import check_schema

RULE_VERSION = "0.1.0"
# Independent acceptance policy, not loaded from the generator's family file.
FAMILIES = {
    "pressure_tee": ({"material", "system"}, {"run_a", "run_b", "branch"}),
    "conductor": ({"material", "gauge_system", "gauge", "construction", "insulation", "voltage"}, set()),
    "filter": ({"media", "rating"}, {"length", "width", "depth"}),
}
TRADES = {"pressure_tee": {"plumbing", "hvac"}, "conductor": {"electrical"}, "filter": {"hvac"}}
TABLES = {"metadata", "nodes", "sources", "items", "associations", "aliases", "evidence"}
# Acceptance scope is controlled by the validator, never by the artifact under test.
# This policy describes only the engineering fixture, not a complete trade pack.
EXPECTED_SCOPE = {"plumbing": {"pressure_tee"}, "electrical": {"conductor"},
                  "hvac": {"pressure_tee", "filter"}}
PENDING = ["factual_verification", "source_rights_review", "full_trade_scope",
           "parser_accuracy", "receipt_images", "inventory_persistence", "migrations",
           "ui_accessibility", "localization", "search", "package_signatures",
           "download_abuse", "concurrency_recovery", "production_scale",
           "all_family_semantics", "requirements_traceability_completion"]


def normalized_identity(raw):
    """Independent identity oracle for the narrow staging protocol.

    Equivalence sets are independently encoded here. This is not proof of
    factual correctness; semantic expectations also have hand-specified tests.
    """
    value = json.loads(raw)
    if set(value) != {"version", "family", "attributes", "ports"} or value["version"] != 1:
        raise ValueError("Unsupported identity schema")
    family = value["family"]
    attributes, roles = FAMILIES[family]
    if set(value["attributes"]) != attributes or set(value["ports"]) != roles:
        raise ValueError("Family identity fields do not match acceptance policy")
    for key, data in value["attributes"].items():
        if not isinstance(data, str) or not data.strip() or len(data) > 200:
            raise ValueError("Invalid attribute")
        value["attributes"][key] = data.strip().casefold()
    for port in value["ports"].values():
        if set(port) != {"size", "unit", "basis", "connection"}:
            raise ValueError("Invalid port fields")
        if any(not isinstance(v, str) or not v.strip() or len(v) > 200 for v in port.values()):
            raise ValueError("Invalid port values")
        size = port["size"]
        if len(size) > 32 or not re.fullmatch(r"(?:\d+ \d+/\d+|\d+/\d+|\d+(?:\.\d+)?)", size):
            raise ValueError("Malformed size")
        pieces = size.split()
        number = sum((Fraction(p) for p in pieces), Fraction(0))
        if not 0 < number <= 10000:
            raise ValueError("Invalid dimension range")
        port["size"] = str(number)
        for key in ("unit", "basis", "connection"):
            port[key] = port[key].strip().lower()
        if port["unit"] not in {"in", "mm"} or port["basis"] not in {"nominal", "actual"}:
            raise ValueError("Unknown dimension unit/basis")
        if port["basis"] == "actual" and port["unit"] == "in":
            port["size"] = str(number * Fraction(127, 5))
            port["unit"] = "mm"
        if Fraction(port["size"]) > 10000:
            raise ValueError("Normalized dimension outside staging bounds")
    if family == "pressure_tee":
        # Only this symmetric pressure-tee fixture family allows run reversal.
        ports = value["ports"]
        pair = sorted([ports["run_a"], ports["run_b"]], key=lambda p: json.dumps(p, sort_keys=True, separators=(",", ":")))
        ports["run_a"], ports["run_b"] = pair
        if any(p["connection"] not in {"socket", "male_thread", "female_thread", "solder"} for p in ports.values()):
            raise ValueError("Unknown tee connection")
        if len({(p["unit"], p["basis"]) for p in ports.values()}) != 1:
            raise ValueError("Mixed dimensional conventions need explicit adapter family")
    elif family == "conductor":
        a = value["attributes"]
        if a["gauge_system"] != "awg" or not re.fullmatch(r"(?:[1-9]|[1-3][0-9]|40|[1-4]/0)", a["gauge"]):
            raise ValueError("Invalid AWG designation")
        if a["construction"] not in {"solid", "stranded"} or a["material"] not in {"copper", "aluminum"}:
            raise ValueError("Invalid conductor attributes")
        if not a["voltage"].isdigit() or not 0 < int(a["voltage"]) <= 100000:
            raise ValueError("Invalid voltage")
    elif family == "filter":
        if any(p["connection"] != "none" for p in value["ports"].values()):
            raise ValueError("Filter dimensions must not inherit fitting connections")
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":")), family


def validate(path):
    path = Path(path)
    issues = []
    coverage = {"items_examined": 0, "nodes_examined": 0, "associations_examined": 0,
                "families_examined": [], "trades_examined": [], "factual_items_verified": 0,
                "inventory_paths_exercised": 0, "ui_routes_exercised": 0,
                "parser_cases_exercised": 0, "unimplemented_release_gates": PENDING}

    def issue(rule, subject, actual, expected, severity="error"):
        issues.append(dict(rule=rule, subject=subject, actual=actual,
                           expected=expected, severity=severity))

    db = None
    digest = None
    try:
        if path.stat().st_size > 256 * 1024 * 1024:
            raise ValueError("Staging artifact size limit exceeded")
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        db = sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True)
        db.execute("PRAGMA query_only=ON")
        db.execute("PRAGMA trusted_schema=OFF")
        budget = [0]

        def limit_work():
            budget[0] += 1
            return int(budget[0] > 500000)

        db.set_progress_handler(limit_work, 1000)
        objects = list(db.execute("SELECT type,name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'"))
        if {name for kind, name in objects if kind == "table"} != TABLES or any(kind != "table" for kind, _ in objects):
            raise ValueError("Unexpected schema objects; no views, triggers or extra tables allowed")
        if db.execute("PRAGMA user_version").fetchone()[0] != 1:
            raise ValueError("Unsupported database schema version")
        check_schema(db)
        if list(db.execute("PRAGMA integrity_check")) != [("ok",)]:
            raise ValueError("SQLite integrity check failed")
        for row in db.execute("PRAGMA foreign_key_check"):
            issue("database.reference", str(row[0]), list(row), "All foreign keys resolve")
        metadata = dict(db.execute("SELECT key,value FROM metadata"))
        if set(metadata) != {"purpose", "generator_version", "identity_version", "catalog_version",
                             "definitions_sha256", "inputs_sha256", "scope"}:
            issue("metadata.fields", "pack", sorted(metadata), "Only declared public catalog metadata")
        if metadata.get("purpose") != "synthetic-engine-fixture":
            issue("artifact.purpose", "pack", metadata.get("purpose"), "synthetic-engine-fixture")
        for name in ("definitions_sha256", "inputs_sha256"):
            if not re.fullmatch(r"[a-f0-9]{64}", metadata.get(name, "")):
                issue("manifest.hash", name, metadata.get(name), "SHA-256 input fingerprint")
        nodes = {r[0]: r[1:] for r in db.execute("SELECT id,parent,trade,label FROM nodes")}
        coverage["nodes_examined"] = len(nodes)
        for node, (parent, trade, label) in sorted(nodes.items()):
            if not label.strip():
                issue("graph.label", node, label, "Nonempty label")
            seen = set()
            current = node
            while current is not None:
                if current in seen:
                    issue("graph.cycle", node, sorted(seen), "Acyclic ancestry")
                    break
                if current not in nodes:
                    issue("graph.orphan", node, current, "Existing parent")
                    break
                seen.add(current)
                if len(seen) > 32:
                    issue("graph.depth", node, len(seen), "Maximum 32 levels")
                    break
                ancestor = nodes[current]
                if ancestor[1] != trade:
                    issue("graph.trade", node, ancestor[1], trade)
                    break
                current = ancestor[0]
        identities = {}
        item_families = {}
        for item_id, raw in db.execute("SELECT id,identity FROM items ORDER BY id"):
            coverage["items_examined"] += 1
            try:
                if len(raw) > 16384:
                    raise ValueError("Identity too long")
                key, family = normalized_identity(raw)
                item_families[item_id] = family
                expected_id = "cat1_" + hashlib.sha256(key.encode()).hexdigest()
                if item_id != expected_id:
                    issue("identity.stable_id", item_id, item_id, expected_id)
                if key in identities:
                    issue("identity.duplicate", item_id, identities[key], "One row per canonical identity")
                identities[key] = item_id
                if raw != key:
                    issue("identity.normal_form", item_id, raw, key)
            except (ValueError, TypeError, KeyError, AttributeError, ZeroDivisionError, RecursionError) as error:
                issue("family.invalid", item_id, str(error), "Valid independently specified family identity")
        paths = {}
        present = set()
        for item_id, node in db.execute("SELECT item,node FROM associations ORDER BY item,node"):
            coverage["associations_examined"] += 1
            paths.setdefault(item_id, []).append(node)
            if node in nodes and item_id in item_families:
                trade = nodes[node][1]
                family = item_families[item_id]
                present.add((trade, family))
                if trade not in TRADES[family]:
                    issue("classification.trade", item_id, trade, sorted(TRADES[family]))
        for item_id in item_families:
            if not paths.get(item_id):
                issue("graph.unreachable", item_id, [], "At least one navigation association")
        scope = json.loads(metadata.get("scope", "{}"))
        expected_scope = {trade: sorted(families) for trade, families in EXPECTED_SCOPE.items()}
        if (not isinstance(scope, dict) or any(not isinstance(v, list) or
                any(not isinstance(f, str) for f in v) for v in scope.values()) or
                {t: sorted(v) for t, v in scope.items()} != expected_scope):
            issue("scope.contract", "pack", scope, expected_scope)
        for trade, families in sorted(EXPECTED_SCOPE.items()):
            for family in sorted(families):
                if (trade, family) not in present:
                    issue("scope.missing_family", trade, family, "Declared family has reachable candidates")
        sources = {r[0]: json.loads(r[1]) for r in db.execute("SELECT id,payload FROM sources")}
        for source_id, source in sources.items():
            if (not isinstance(source, dict) or set(source) != {"id", "classification", "verification", "note"} or
                    source.get("id") != source_id or not isinstance(source.get("note"), str) or
                    not source["note"].strip() or len(source["note"]) > 2000):
                issue("evidence.record_shape", source_id, "Unexpected or malformed source fields",
                      "Exact public source contract with matching identifier")
        aliased = set()
        for item_id, alias in db.execute("SELECT item,value FROM aliases ORDER BY item,value"):
            aliased.add(item_id)
            if (not isinstance(alias, str) or not alias.strip() or len(alias) > 200 or
                    any(ord(c) < 32 or 0xD800 <= ord(c) <= 0xDFFF for c in alias)):
                issue("alias.invalid", item_id, "Malformed alias", "Bounded nonempty Unicode search text")
        for item_id in item_families.keys() - aliased:
            issue("search.no_alias", item_id, [], "At least one searchable alias")
        evidence_items = set()
        for item_id, source_id in db.execute("SELECT item,source FROM evidence ORDER BY item,source"):
            evidence_items.add(item_id)
            source = sources.get(source_id, {})
            # Staging candidates cannot certify themselves by flipping a flag.
            if not isinstance(source, dict) or source.get("classification") != "synthetic_fixture" or source.get("verification") != "unverified":
                issue("evidence.unsupported_claim", item_id, source, "Synthetic unverified fixture evidence only")
            else:
                issue("evidence.unverified", item_id, source_id, "Independent factual and rights review", "review")
        for item_id in item_families.keys() - evidence_items:
            issue("evidence.missing", item_id, None, "Traceable evidence")
        coverage["families_examined"] = sorted(set(item_families.values()))
        coverage["trades_examined"] = sorted({t for t, _ in present})
        for entry in issues:
            entry["trade_paths"] = paths.get(entry["subject"], [])
    except (OSError, sqlite3.Error, ValueError, TypeError, KeyError, AttributeError, RecursionError) as error:
        issue("artifact.invalid", "pack", str(error), "Supported, intact, bounded SQLite artifact")
    finally:
        if db is not None:
            db.close()
    issues.sort(key=lambda x: (x["rule"], x["subject"], str(x["actual"])))
    return {"validator_version": RULE_VERSION, "artifact_sha256": digest,
            "structural_pass": not any(i["severity"] == "error" for i in issues),
            "release_ready": False, "coverage": coverage, "issues": issues}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--release", action="store_true")
    args = parser.parse_args()
    result = validate(args.artifact)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    summary = ["# Catalog engineering validation", "",
               f"Structural checks: {'PASS' if result['structural_pass'] else 'FAIL'}",
               "Release: BLOCKED (first-slice fixture evidence; mandatory gates incomplete)", "",
               "## Coverage", "", json.dumps(result["coverage"], indent=2), "", "## Findings", ""]
    summary.extend(f"- {i['severity']}: {i['rule']} / {i['subject']}: {i['actual']} — expected {i['expected']}"
                   for i in result["issues"])
    args.report.with_suffix(".md").write_text("\n".join(summary) + "\n", encoding="utf-8")
    print(f"Structural pass: {result['structural_pass']}; release ready: False")
    return 0 if result["structural_pass"] and not args.release else 1


if __name__ == "__main__":
    raise SystemExit(main())

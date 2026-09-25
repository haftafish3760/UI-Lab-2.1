"""Declarative candidate builder. Produces staging SQLite, never a release pack."""
import argparse
from contextlib import closing
import hashlib
import json
import re
import sqlite3
from fractions import Fraction
from pathlib import Path

from .input_contract import check_definitions, check_source, load_json
from .variants import expand_recipe


def encoded(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def token(value):
    if not isinstance(value, str) or not value.strip() or len(value) > 200:
        raise ValueError("Expected nonempty token of at most 200 characters")
    return value.strip().casefold()


def dimension(value):
    if not isinstance(value, str) or len(value) > 32:
        raise ValueError("Dimensions must be short exact numeric strings")
    if not re.fullmatch(r"(?:\d+ \d+/\d+|\d+/\d+|\d+(?:\.\d+)?)", value):
        raise ValueError("Unsupported dimension notation")
    if " " in value:
        whole, fraction = value.split(" ")
        number = Fraction(whole) + Fraction(fraction)
    else:
        number = Fraction(value)
    if not 0 < number <= 10000:
        raise ValueError("Dimension outside staging bounds")
    return str(number)


def canonical(row, family):
    """ID v1 excludes labels, evidence and navigation; unknown identity is rejected."""
    if set(row["attributes"]) != set(family["identity_attributes"]):
        raise ValueError("Missing or unexpected identity attributes")
    attributes = {k: token(v) for k, v in row["attributes"].items()}
    if set(row["ports"]) != set(family["ports"]):
        raise ValueError("Missing or unexpected dimension roles")
    ports = {}
    for role, port in row["ports"].items():
        if set(port) != {"size", "unit", "basis", "connection"}:
            raise ValueError("Unexpected port fields")
        ports[role] = {k: dimension(v) if k == "size" else token(v)
                       for k, v in port.items()}
        # Actual lengths have an exact common unit. Nominal designations never
        # undergo this conversion: equal printed values can name different parts.
        if ports[role]["basis"] == "actual" and ports[role]["unit"] == "in":
            ports[role]["size"] = str(Fraction(ports[role]["size"]) * Fraction(254, 10))
            ports[role]["unit"] = "mm"
        if Fraction(ports[role]["size"]) > 10000:
            raise ValueError("Normalized dimension outside staging bounds")
    # Swap complete ports, not bare sizes: connections travel with dimensions.
    for group in family["interchangeable_ports"]:
        ordered = sorted((ports[k] for k in group), key=encoded)
        for key, port in zip(sorted(group), ordered):
            ports[key] = port
    identity = {"version": 1, "family": family["id"],
                "attributes": attributes, "ports": ports}
    key = encoded(identity)
    return "cat1_" + hashlib.sha256(key.encode()).hexdigest(), key


def build(definitions_path, candidates_path, target, *, recipe=False):
    definitions = load_json(definitions_path)
    source = load_json(candidates_path)
    if recipe:
        source = expand_recipe(source)
    check_definitions(definitions)
    check_source(source)
    families = {f["id"]: f for f in definitions["families"]}
    if len(families) != len(definitions["families"]):
        raise ValueError("Duplicate family definition")
    if source["purpose"] != "synthetic-engine-fixture":
        raise ValueError("First slice accepts synthetic engine fixtures only")
    records = {}
    for row in source["candidates"]:
        if set(row) != {"family", "attributes", "ports", "paths", "aliases", "source"}:
            raise ValueError("Candidate contains unknown fields")
        family = families[row["family"]]
        item_id, key = canonical(row, family)
        record = records.setdefault(item_id, {"key": key, "paths": set(),
                                             "aliases": set(), "sources": set()})
        record["paths"].update(row["paths"])
        record["aliases"].update(token(a) for a in row["aliases"])
        record["sources"].add(row["source"])
    target = Path(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    # Exclusive creation protects both live assets and previous staging artifacts.
    with target.open("xb"):
        pass
    try:
        with closing(sqlite3.connect(target)) as db, db:
            db.execute("PRAGMA foreign_keys=ON")
            db.execute("PRAGMA user_version=1")
            db.executescript("""
                CREATE TABLE metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL);
                CREATE TABLE nodes(id TEXT PRIMARY KEY, parent TEXT REFERENCES nodes(id),
                                   trade TEXT NOT NULL, label TEXT NOT NULL);
                CREATE TABLE sources(id TEXT PRIMARY KEY, payload TEXT NOT NULL);
                CREATE TABLE items(id TEXT PRIMARY KEY, identity TEXT NOT NULL UNIQUE);
                CREATE TABLE associations(item TEXT REFERENCES items(id),
                    node TEXT REFERENCES nodes(id), PRIMARY KEY(item,node));
                CREATE TABLE aliases(item TEXT REFERENCES items(id), value TEXT,
                    PRIMARY KEY(item,value));
                CREATE TABLE evidence(item TEXT REFERENCES items(id),
                    source TEXT REFERENCES sources(id), PRIMARY KEY(item,source));
            """)
            metadata = {"purpose": source["purpose"], "generator_version": "0.1.0",
                        "identity_version": "1", "catalog_version": source["version"],
                        "definitions_sha256": hashlib.sha256(Path(definitions_path).read_bytes()).hexdigest(),
                        "inputs_sha256": hashlib.sha256(Path(candidates_path).read_bytes()).hexdigest(),
                        "scope": encoded(source["scope"])}
            db.executemany("INSERT INTO metadata VALUES (?,?)", sorted(metadata.items()))
            # Deferred references allow arbitrary source ordering, checked on commit.
            db.execute("PRAGMA defer_foreign_keys=ON")
            for node in sorted(source["nodes"], key=lambda n: n["id"]):
                db.execute("INSERT INTO nodes VALUES (?,?,?,?)",
                           (node["id"], node["parent"], node["trade"], node["label"]))
            for evidence in sorted(source["sources"], key=lambda s: s["id"]):
                db.execute("INSERT INTO sources VALUES (?,?)", (evidence["id"], encoded(evidence)))
            for item_id, record in sorted(records.items()):
                db.execute("INSERT INTO items VALUES (?,?)", (item_id, record["key"]))
                for table, field in [("associations", "paths"), ("aliases", "aliases"),
                                     ("evidence", "sources")]:
                    db.executemany(f"INSERT INTO {table} VALUES (?,?)",
                                   [(item_id, value) for value in sorted(record[field])])
        return {"candidate_count": len(source["candidates"]), "canonical_count": len(records),
                "artifact": str(target), "release_ready": False}
    except BaseException:
        # Only the file exclusively created by this invocation may be removed.
        target.unlink(missing_ok=True)
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--definitions", type=Path, required=True)
    inputs = parser.add_mutually_exclusive_group(required=True)
    inputs.add_argument("--candidates", type=Path)
    inputs.add_argument("--recipe", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(build(args.definitions, args.recipe or args.candidates, args.output,
                           recipe=args.recipe is not None), indent=2))


if __name__ == "__main__":
    main()

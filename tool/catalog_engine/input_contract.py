"""Fail closed on malformed declarative generation inputs before creating output.

This validates engineering format, not factual availability or source rights.
No formulas, executable expressions, includes, or filesystem paths are evaluated.
"""
import json
from pathlib import Path
import re


def load_json(path, maximum_bytes=128 * 1024 * 1024):
    path = Path(path)
    if path.stat().st_size > maximum_bytes:
        raise ValueError("Input exceeds bounded development input size")

    def unique_object(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError("Duplicate JSON key: " + key)
            result[key] = value
        return result

    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_object)


def fields(value, expected):
    if not isinstance(value, dict) or set(value) != set(expected):
        raise ValueError("Missing or unexpected input fields: " + ", ".join(sorted(expected)))


def text(value, maximum=200):
    if not isinstance(value, str) or not value.strip() or len(value) > maximum:
        raise ValueError("Invalid bounded text")
    if any(ord(c) < 32 or 0xD800 <= ord(c) <= 0xDFFF for c in value):
        raise ValueError("Control characters or malformed Unicode in input")


def identifier(value):
    text(value, 100)
    if not re.fullmatch(r"[a-z][a-z0-9_-]*", value):
        raise ValueError("Invalid identifier")


def names(value, allow_empty=True):
    if not isinstance(value, list) or len(value) > 100 or (not allow_empty and not value):
        raise ValueError("Invalid bounded name list")
    for name in value:
        identifier(name)
    if len(value) != len(set(value)):
        raise ValueError("Duplicate names")


def check_definitions(definitions):
    fields(definitions, {"version", "status", "families"})
    if type(definitions["version"]) is not int or definitions["version"] != 1:
        raise ValueError("Unsupported definition version")
    if definitions["status"] != "engineering-fixtures-not-product-verification":
        raise ValueError("Unsupported definition status")
    if not isinstance(definitions["families"], list) or not 1 <= len(definitions["families"]) <= 100:
        raise ValueError("Invalid family count")
    found = set()
    for family in definitions["families"]:
        fields(family, {"id", "identity_attributes", "ports", "interchangeable_ports"})
        identifier(family["id"])
        if family["id"] in found:
            raise ValueError("Duplicate family definition")
        found.add(family["id"])
        names(family["identity_attributes"], allow_empty=False)
        names(family["ports"])
        groups = family["interchangeable_ports"]
        if not isinstance(groups, list) or len(groups) > 20:
            raise ValueError("Invalid symmetry groups")
        used = set()
        for group in groups:
            names(group, allow_empty=False)
            if len(group) < 2 or used.intersection(group) or not set(group) <= set(family["ports"]):
                raise ValueError("Unknown, overlapping or degenerate interchangeable ports")
            used.update(group)


def check_source(source):
    fields(source, {"purpose", "version", "scope", "nodes", "sources", "candidates"})
    if source["purpose"] != "synthetic-engine-fixture":
        raise ValueError("Only synthetic engineering input is supported")
    text(source["version"])
    if not isinstance(source["scope"], dict) or not source["scope"]:
        raise ValueError("Declared scope required")
    for trade, families in source["scope"].items():
        identifier(trade)
        names(families, allow_empty=False)
    for key, maximum in [("nodes", 10000), ("sources", 10000), ("candidates", 300000)]:
        if not isinstance(source[key], list) or not 1 <= len(source[key]) <= maximum:
            raise ValueError("Invalid bounded input collection: " + key)
    for node in source["nodes"]:
        fields(node, {"id", "parent", "trade", "label"})
        identifier(node["id"])
        identifier(node["trade"])
        if node["parent"] is not None:
            identifier(node["parent"])
        text(node["label"])
    for evidence in source["sources"]:
        fields(evidence, {"id", "classification", "verification", "note"})
        identifier(evidence["id"])
        text(evidence["note"], 2000)
        if evidence["classification"] != "synthetic_fixture" or evidence["verification"] != "unverified":
            raise ValueError("Fixture cannot assert its own factual verification")
    for row in source["candidates"]:
        fields(row, {"family", "attributes", "ports", "paths", "aliases", "source"})
        identifier(row["family"])
        identifier(row["source"])
        names(row["paths"], allow_empty=False)
        if not isinstance(row["aliases"], list) or not 1 <= len(row["aliases"]) <= 100:
            raise ValueError("Invalid alias count")
        for alias in row["aliases"]:
            text(alias)
        if not isinstance(row["attributes"], dict) or not isinstance(row["ports"], dict):
            raise ValueError("Attributes and ports must be objects")
        for value in row["attributes"].values():
            text(value)
        for port in row["ports"].values():
            fields(port, {"size", "unit", "basis", "connection"})
            for value in port.values():
                text(value)

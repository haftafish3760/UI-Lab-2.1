"""Staging pack manifest and independent integrity verification.

SHA-256 detects changed bytes; this module does not claim publisher authenticity.
Production signature verification remains a mandatory release requirement.
"""
import argparse
from contextlib import closing
import hashlib
import json
from pathlib import Path
import re
import sqlite3

from .validate import validate

FIELDS = {"manifest_version", "schema_version", "catalog_version", "generator_version",
          "artifact", "bytes", "sha256", "counts", "inputs_sha256", "definitions_sha256",
          "purpose", "publication_state", "sources"}


def describe(path):
    path = Path(path)
    checked = validate(path)
    if not checked["structural_pass"]:
        raise ValueError("Cannot package structurally invalid catalog")
    with closing(sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True)) as db:
        db.execute("PRAGMA query_only=ON")
        db.execute("PRAGMA trusted_schema=OFF")
        metadata = dict(db.execute("SELECT key,value FROM metadata"))
        counts = {table: db.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
                  for table in ("items", "nodes", "associations", "aliases", "sources", "evidence")}
        sources = sorted(row[0] for row in db.execute("SELECT id FROM sources"))
        schema = db.execute("PRAGMA user_version").fetchone()[0]
    return {"manifest_version": 1, "schema_version": schema,
            "catalog_version": metadata["catalog_version"], "generator_version": metadata["generator_version"],
            "artifact": path.name, "bytes": path.stat().st_size,
            "sha256": checked["artifact_sha256"], "counts": counts,
            "inputs_sha256": metadata["inputs_sha256"], "definitions_sha256": metadata["definitions_sha256"],
            "purpose": metadata["purpose"], "publication_state": "staging_only", "sources": sources}


def verify(directory, manifest):
    if not isinstance(manifest, dict) or set(manifest) != FIELDS:
        raise ValueError("Unsupported manifest fields")
    name = manifest["artifact"]
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,100}\.sqlite", name):
        raise ValueError("Artifact must be a plain bounded SQLite filename")
    root = Path(directory).resolve()
    artifact = root / name
    if artifact.is_symlink() or artifact.resolve().parent != root:
        raise ValueError("Artifact escapes pack directory")
    if type(manifest["bytes"]) is not int or not 0 < manifest["bytes"] <= 256 * 1024 * 1024:
        raise ValueError("Invalid artifact size")
    if artifact.stat().st_size != manifest["bytes"]:
        raise ValueError("Artifact length mismatch")
    if hashlib.sha256(artifact.read_bytes()).hexdigest() != manifest["sha256"]:
        raise ValueError("Artifact hash mismatch")
    actual = describe(artifact)
    # Counts are checked against the actual database, not trusted as proof.
    if json.dumps(actual, sort_keys=True) != json.dumps(manifest, sort_keys=True):
        raise ValueError("Manifest metadata differs from independently inspected artifact")
    return {"integrity_verified": True, "publisher_authenticated": False,
            "release_ready": False, "artifact_sha256": actual["sha256"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    manifest = describe(args.artifact)
    if args.output.resolve().parent != args.artifact.resolve().parent:
        raise ValueError("Manifest must be written beside its artifact")
    verify(args.artifact.parent, manifest)
    with args.output.open("x", encoding="utf-8") as stream:
        json.dump(manifest, stream, sort_keys=True, indent=2)
        stream.write("\n")
    print("Staging integrity manifest created; publisher authentication and release remain unverified")


if __name__ == "__main__":
    main()

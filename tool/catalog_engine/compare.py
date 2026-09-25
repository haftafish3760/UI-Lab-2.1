"""Read-only semantic comparison of independently validated staging artifacts.

Changes are evidence for review, never instructions to merge user inventory.
An identity change appears as removed/added because inferring a replacement is
unsafe; a future explicit migration must supply and validate that relationship.
"""
import argparse
from contextlib import closing
import json
from pathlib import Path
import sqlite3

from .validate import validate


def snapshot(path):
    report = validate(path)
    if not report["structural_pass"]:
        raise ValueError("Cannot compare invalid artifact: " + str(path))
    with closing(sqlite3.connect(Path(path).resolve().as_uri() + "?mode=ro", uri=True)) as db:
        db.execute("PRAGMA query_only=ON")
        db.execute("PRAGMA trusted_schema=OFF")
        items = {key: {"identity": json.loads(identity), "paths": [], "aliases": [], "evidence": []}
                 for key, identity in db.execute("SELECT id,identity FROM items")}
        nodes = {key: {"parent": parent, "trade": trade, "label": label}
                 for key, parent, trade, label in db.execute("SELECT id,parent,trade,label FROM nodes")}
        for table, field, value_column in [("associations", "paths", "node"),
                                           ("aliases", "aliases", "value"),
                                           ("evidence", "evidence", "source")]:
            for key, value in db.execute(f"SELECT item,{value_column} FROM {table} ORDER BY item,{value_column}"):
                items[key][field].append(value)
        for record in items.values():
            record["trades"] = sorted({nodes[n]["trade"] for n in record["paths"]})
        sources = {key: json.loads(payload) for key, payload in db.execute("SELECT id,payload FROM sources")}
    return {"sha256": report["artifact_sha256"], "items": items, "nodes": nodes, "sources": sources}


def compare(before, after, max_removed_fraction=0.05):
    if isinstance(max_removed_fraction, bool) or not 0 <= max_removed_fraction <= 1:
        raise ValueError("Removal threshold must be a fraction from zero to one")
    old, new = snapshot(before), snapshot(after)
    changes, blockers = [], []

    def changed(kind, subject, previous, current, risk):
        changes.append({"kind": kind, "subject": subject, "before": previous,
                        "after": current, "risk": risk})

    removed = sorted(old["items"].keys() - new["items"].keys())
    added = sorted(new["items"].keys() - old["items"].keys())
    for key in removed:
        changed("item_removed", key, old["items"][key], None, "high")
    for key in added:
        changed("item_added", key, None, new["items"][key], "review")
    for key in sorted(old["items"].keys() & new["items"].keys()):
        for field in ("identity", "paths", "trades", "aliases", "evidence"):
            a, b = old["items"][key][field], new["items"][key][field]
            if a != b:
                changed("item_" + field, key, a, b, "high" if field != "aliases" else "review")
                if field == "trades" and set(a) - set(b):
                    blockers.append({"rule": "update.trade_loss", "subject": key,
                                     "removed_trades": sorted(set(a) - set(b))})
    for section in ("nodes", "sources"):
        for key in sorted(old[section].keys() | new[section].keys()):
            a, b = old[section].get(key), new[section].get(key)
            if a != b:
                changed(section + "_changed", key, a, b, "high" if section == "sources" else "review")
    fraction = len(removed) / len(old["items"]) if old["items"] else 0
    if removed:
        blockers.append({"rule": "update.migration_required", "subject": "pack", "removed_ids": removed})
    if fraction > max_removed_fraction:
        blockers.append({"rule": "update.blast_radius", "subject": "pack",
                         "removed_fraction": fraction, "maximum": max_removed_fraction})
    return {"format_version": 1, "before_sha256": old["sha256"], "after_sha256": new["sha256"],
            "changes": changes, "blockers": blockers, "release_ready": False,
            "summary": {"added": len(added), "removed": len(removed), "changes": len(changes),
                        "high_risk_changes": sum(c["risk"] == "high" for c in changes)}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before", type=Path)
    parser.add_argument("after", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    report = compare(args.before, args.after)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    with args.report.open("x", encoding="utf-8") as stream:
        json.dump(report, stream, indent=2, ensure_ascii=False)
        stream.write("\n")
    print(json.dumps(report["summary"]))
    return 1 if report["blockers"] else 0


if __name__ == "__main__":
    raise SystemExit(main())

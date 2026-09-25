"""Independent schema contract for the staging SQLite wire format.

Checking foreign_key_check alone is insufficient: an attacker can remove the
foreign-key declarations. Check declarations before trusting that result.
"""

COLUMNS = {
    "metadata": [("key", "TEXT", 0, 1), ("value", "TEXT", 1, 0)],
    "nodes": [("id", "TEXT", 0, 1), ("parent", "TEXT", 0, 0),
              ("trade", "TEXT", 1, 0), ("label", "TEXT", 1, 0)],
    "sources": [("id", "TEXT", 0, 1), ("payload", "TEXT", 1, 0)],
    "items": [("id", "TEXT", 0, 1), ("identity", "TEXT", 1, 0)],
    "associations": [("item", "TEXT", 0, 1), ("node", "TEXT", 0, 2)],
    "aliases": [("item", "TEXT", 0, 1), ("value", "TEXT", 0, 2)],
    "evidence": [("item", "TEXT", 0, 1), ("source", "TEXT", 0, 2)],
}
REFERENCES = {
    "metadata": set(), "nodes": {("parent", "nodes", "id")},
    "sources": set(), "items": set(), "aliases": {("item", "items", "id")},
    "associations": {("item", "items", "id"), ("node", "nodes", "id")},
    "evidence": {("item", "items", "id"), ("source", "sources", "id")},
}


def check_schema(db):
    for table, expected in COLUMNS.items():
        columns = list(db.execute(f"PRAGMA table_xinfo({table})"))
        actual = [(r[1], r[2], r[3], r[5]) for r in columns]
        if actual != expected or any(r[4] is not None or r[6] != 0 for r in columns):
            raise ValueError("Unsupported columns/defaults/generated fields in " + table)
        references = list(db.execute(f"PRAGMA foreign_key_list({table})"))
        if ({(r[3], r[2], r[4]) for r in references} != REFERENCES[table] or
                len(references) != len(REFERENCES[table]) or
                any(r[5] != "NO ACTION" or r[6] != "NO ACTION" for r in references)):
            raise ValueError("Missing or altered foreign-key contract in " + table)
        # SQLite permits NULL in non-integer primary keys of ordinary tables.
        # The format requires actual keys and values even where v1 DDL did not.
        for column, _, _, _ in expected:
            if table == "nodes" and column == "parent":
                continue
            if db.execute(f"SELECT 1 FROM {table} WHERE {column} IS NULL LIMIT 1").fetchone():
                raise ValueError("Null required value in " + table + "." + column)
    indexes = list(db.execute("PRAGMA index_list(items)"))
    unique_identity = False
    for row in indexes:
        # Never interpolate untrusted index names in SQL.
        if row[2] and not row[4]:
            columns = [r[2] for r in db.execute("SELECT * FROM pragma_index_info(?)", (row[1],))]
            unique_identity |= columns == ["identity"]
    if not unique_identity:
        raise ValueError("Canonical identity uniqueness constraint missing")

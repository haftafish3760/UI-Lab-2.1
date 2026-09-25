"""Expand explicit variant tables; never generate a size Cartesian product.

The table is generation input, not independent evidence that variants exist.
Only reviewed factual input can eventually justify production variants. Current
recipes remain synthetic fixtures and cannot approve their own release.
"""
import copy

from .input_contract import check_source, fields, text


def expand_recipe(recipe, maximum_candidates=300000):
    fields(recipe, {"format_version", "source", "variant_batches"})
    if type(recipe["format_version"]) is not int or recipe["format_version"] != 1:
        raise ValueError("Unsupported recipe version")
    source = copy.deepcopy(recipe["source"])
    check_source(source)
    batches = recipe["variant_batches"]
    if not isinstance(batches, list) or not 1 <= len(batches) <= 1000:
        raise ValueError("Invalid variant batch count")
    for batch in batches:
        fields(batch, {"template", "columns", "rows"})
        template = batch["template"]
        probe = dict(source)
        probe["candidates"] = [template]
        check_source(probe)
        columns, rows = batch["columns"], batch["rows"]
        if not isinstance(columns, list) or not 1 <= len(columns) <= 100:
            raise ValueError("Variant columns required")
        destinations = []
        for column in columns:
            text(column)
            parts = column.split(".")
            if (len(parts) == 2 and parts[0] == "attributes" and parts[1] in template["attributes"]):
                destinations.append(parts)
            elif (len(parts) == 3 and parts[0] == "ports" and
                  parts[1] in template["ports"] and parts[2] in template["ports"][parts[1]]):
                destinations.append(parts)
            else:
                raise ValueError("Variant column is not an existing identity field")
        if len(columns) != len(set(columns)):
            raise ValueError("Repeated variant column")
        if not isinstance(rows, list) or not rows:
            raise ValueError("Explicit variant rows required")
        if len(source["candidates"]) + len(rows) > maximum_candidates:
            raise ValueError("Variant expansion exceeds candidate budget")
        for values in rows:
            if not isinstance(values, list) or len(values) != len(columns):
                raise ValueError("Variant row does not match columns")
            row = copy.deepcopy(template)
            for path, value in zip(destinations, values):
                text(value)
                container = row
                for part in path[:-1]:
                    container = container[part]
                container[path[-1]] = value
            source["candidates"].append(row)
    check_source(source)
    return source

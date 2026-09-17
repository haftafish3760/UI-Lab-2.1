"""Capture only the transitive Dart dependencies of the retained legacy probes.

Never executes or modifies the protected source. Destination is a versioned QA
reference, not application code, stock authority, or an accepted catalog.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOTS = ['inventory_parser.dart', 'work_supply_models.dart',
         'work_supply_trade_pack_runtime_loader.dart', 'work_supply_catalog.dart',
         'work_supply_catalog_pack_payload.dart']


def capture(source, destination, recorded_manifest):
    source = source.resolve()
    expected = {r['path']: r['sha256'] for r in
                json.loads(recorded_manifest.read_text())['files']}
    pending = [source / name for name in ROOTS]
    captured = {}
    while pending:
        path = pending.pop().resolve()
        if not path.is_relative_to(source):
            raise ValueError(f'Dependency escapes source boundary: {path}')
        relative = path.relative_to(source).as_posix()
        if relative in captured:
            continue
        raw = path.read_bytes()
        digest = hashlib.sha256(raw).hexdigest()
        crlf_digest = hashlib.sha256(raw.replace(b'\r\n', b'\n')
                                    .replace(b'\n', b'\r\n')).hexdigest()
        if expected.get(relative) not in (digest, crlf_digest):
            raise ValueError(f'Source differs from recorded extraction: {relative}')
        captured[relative] = raw
        for uri in re.findall(r'''(?:import|export|part)\s+['"]([^'"]+)''',
                              raw.decode()):
            if ':' not in uri:
                pending.append(path.parent / uri)
    if destination.exists():
        raise ValueError('Destination exists; preserve it and review differences.')
    # Validate the entire closure before creating any output.
    for relative, raw in sorted(captured.items()):
        if (source / relative).read_bytes() != raw:
            raise ValueError(f'Source changed during capture: {relative}')
    for relative, raw in sorted(captured.items()):
        target = destination / 'data' / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
    manifest = {'status': 'unaccepted legacy QA reference; not runtime code',
                'roots': ROOTS, 'source': str(source),
                'files': [{'path': p, 'sha256': hashlib.sha256(b).hexdigest(),
                           'recordedExtractionSha256': expected[p], 'bytes': len(b)}
                          for p, b in sorted(captured.items())]}
    (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print(f'Captured {len(captured)} dependency files; protected source unchanged.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    args = parser.parse_args()
    workspace = Path(__file__).resolve().parents[2]
    capture(args.source, workspace / 'tool/inventory/legacy_reference',
            workspace / 'docs/inventory_migration/source_manifest.json')

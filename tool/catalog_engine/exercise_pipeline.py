"""Exercise real generator/validator processes and retain inspectable artifacts.

This proves software behavior with authored examples, not product availability.
No generator or validator implementation is imported into this acceptance driver.
"""
import argparse
from contextlib import closing
import hashlib
import json
from pathlib import Path
import shutil
import sqlite3
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def exercise(output):
    output = output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    executions = []

    def run(module, args, expected):
        command = [sys.executable, '-m', 'tool.catalog_engine.' + module, *map(str, args)]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=60)
        executions.append(dict(command=command, exit_code=result.returncode,
                               stdout=result.stdout, stderr=result.stderr))
        if result.returncode != expected:
            raise RuntimeError(f'{module}: expected exit {expected}, got {result.returncode}: {result.stderr}')

    def inspect(path, name, expected_rule=None):
        before = hashlib.sha256(path.read_bytes()).hexdigest()
        report = output / (name + '.json')
        run('validate', [path, '--report', report], 1 if expected_rule else 0)
        result = json.loads(report.read_text(encoding='utf-8'))
        if hashlib.sha256(path.read_bytes()).hexdigest() != before:
            raise RuntimeError('Validator modified its input')
        if expected_rule and expected_rule not in {x['rule'] for x in result['issues']}:
            raise RuntimeError(f'Missing required diagnosis: {expected_rule}')
        return result

    passed = False
    try:
        artifact = output / 'catalog.sqlite'
        run('generate', ['--definitions', ROOT / 'tool/catalog_engine/definitions/families.json',
                         '--candidates', ROOT / 'tool/catalog_engine/fixtures/candidates.json',
                         '--output', artifact], 0)
        inspect(artifact, 'baseline')
        with closing(sqlite3.connect(artifact.as_uri() + '?mode=ro', uri=True)) as db:
            rows = [dict(id=id_, **json.loads(raw)) for id_, raw in db.execute('SELECT id,identity FROM items ORDER BY id')]
            tees = [row for row in rows if row['family'] == 'pressure_tee']
            # Literal owner-provided run/run/branch expectations, not generator output.
            signatures = {(r['ports']['run_a']['size'], r['ports']['run_b']['size'],
                           r['ports']['branch']['size']) for r in tees}
            if signatures != {('1/2', '3/4', '1/2'), ('1/2', '3/4', '3/4'), ('1/2', '1/2', '1/2')}:
                raise RuntimeError('Generated tee dimensions differ from independent examples')
            if len(tees) != 3 or len(rows) != 5:
                raise RuntimeError('Unexpected extra or missing generated identities')
        (output / 'generated-items.json').write_text(json.dumps(rows, indent=2) + '\n', encoding='utf-8')
        defects = {
            'orphan': ("UPDATE nodes SET parent='missing-parent' WHERE id='p_fittings'", 'graph.orphan'),
            'missing-evidence': ('DELETE FROM evidence', 'evidence.missing'),
            'missing-family': ("DELETE FROM associations WHERE node='e_wire'", 'scope.missing_family'),
        }
        for name, (sql, rule) in defects.items():
            damaged = output / (name + '.sqlite')
            shutil.copyfile(artifact, damaged)
            with closing(sqlite3.connect(damaged)) as db, db:
                db.execute(sql)
            inspect(damaged, name, rule)
        duplicate = output / 'duplicate.sqlite'
        shutil.copyfile(artifact, duplicate)
        with closing(sqlite3.connect(duplicate)) as db, db:
            row = dict(tees[0])
            row.pop('id')
            row['ports']['run_a']['size'] = '0.5'
            db.execute('INSERT INTO items VALUES (?,?)', ('deliberate-duplicate', json.dumps(row)))
        inspect(duplicate, 'duplicate', 'identity.duplicate')
        run('verify_release', [artifact, '--report', output / 'release.json'], 1)
        passed = True
    finally:
        (output / 'exercise.json').write_text(json.dumps({
            'pipeline_exercise_passed': passed, 'release_ready': False,
            'data_status': 'authored engineering examples; real-product factual verification remains open',
            'executions': executions}, indent=2) + '\n', encoding='utf-8')
    return output


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-directory', type=Path, required=True)
    print(exercise(parser.parse_args().output_directory))

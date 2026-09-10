#!/usr/bin/env python3
"""Run the complete workspace-owned Android media tests with source-bound evidence."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import time
import uuid
import xml.etree.ElementTree as ET

from run_storage_qa import ROOT, fingerprint, stop_process


def evaluate_junit(folder, expected_classes):
    observed = set()
    counts = dict(tests=0, failures=0, errors=0, skipped=0)
    problems = []
    for path in sorted(folder.glob('TEST-*.xml')):
        try:
            suite = ET.parse(path).getroot()
            name = suite.attrib['name'].rsplit('.', 1)[-1]
            if name in observed:
                raise ValueError('Duplicate suite')
            observed.add(name)
            cases = suite.findall('testcase')
            declared = {key: int(suite.get(key, '0')) for key in counts}
            actual = dict(tests=len(cases), failures=sum(c.find('failure') is not None for c in cases),
                          errors=sum(c.find('error') is not None for c in cases),
                          skipped=sum(c.find('skipped') is not None for c in cases))
            if declared != actual or not cases:
                raise ValueError('Missing or inconsistent test cases')
            for key in counts:
                counts[key] += actual[key]
        except (ET.ParseError, KeyError, ValueError) as error:
            problems.append(f'{path.name}: {error}')
    missing = sorted(set(expected_classes) - observed)
    unexpected = sorted(observed - set(expected_classes))
    return {**counts, 'missing_classes': missing, 'unexpected_classes': unexpected,
            'problems': problems, 'passed': counts['tests'] > 0 and not any(
                [counts['failures'], counts['errors'], counts['skipped'], missing, unexpected, problems])}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--java-home', required=True, type=Path,
                        help='JDK 21 installation for the current Robolectric SDK matrix')
    parser.add_argument('--timeout-seconds', type=int, default=600)
    args = parser.parse_args()
    java = args.java_home.resolve() / 'bin/java'
    if not java.is_file() or args.timeout_seconds <= 0:
        parser.error('Require an installed JDK and a positive timeout')
    version = subprocess.run([str(java), '-version'], capture_output=True, text=True, check=True)
    vendor = ROOT / 'third_party/image_picker_android/android/src/test'
    expected = sorted({p.stem for suffix in ('*Test.java', '*Test.kt') for p in vendor.rglob(suffix)})
    if not expected:
        raise RuntimeError('No native test classes found')
    run_id = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()) + '-native-' + uuid.uuid4().hex[:8]
    output = ROOT / 'build/storage_qa' / run_id
    output.mkdir(parents=True)
    (output / 'java-version.txt').write_text(version.stdout + version.stderr)
    before = fingerprint(ROOT)
    command = [str(ROOT / 'android/gradlew'), '-p', str(ROOT / 'android'),
               ':image_picker_android:testDebugUnitTest', '--rerun-tasks']
    report = {'command': command, 'expected_classes': expected, 'source_before': before,
              'passed': False, 'timeout': False,
              'limits': ['Native JVM tests only; no device runtime or migration completion claim.']}
    report_path = output / 'report.json'
    report_path.write_text(json.dumps(report, indent=2))
    env = {**os.environ, 'JAVA_HOME': str(args.java_home.resolve())}
    # Forced execution prevents stale Gradle XML from masquerading as a new run.
    with (output / 'gradle.log').open('w') as log:
        process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        try:
            process.wait(timeout=args.timeout_seconds)
        except (subprocess.TimeoutExpired, KeyboardInterrupt) as error:
            report['timeout'] = isinstance(error, subprocess.TimeoutExpired)
            report['interrupted'] = isinstance(error, KeyboardInterrupt)
            stop_process(process)
    report['exit_code'] = process.returncode
    xml_folder = ROOT / 'build/image_picker_android/test-results/testDebugUnitTest'
    captured = output / 'junit'
    captured.mkdir()
    for path in xml_folder.glob('TEST-*.xml'):
        shutil.copy2(path, captured / path.name)
    report['evaluation'] = evaluate_junit(captured, expected)
    report['source_after'] = fingerprint(ROOT)
    report['passed'] = (process.returncode == 0 and not report['timeout']
                        and not report.get('interrupted', False)
                        and before == report['source_after'] and report['evaluation']['passed'])
    report_path.write_text(json.dumps(report, indent=2))
    print(json.dumps(report['evaluation']), flush=True)
    print(f'Report: {report_path}', flush=True)
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())

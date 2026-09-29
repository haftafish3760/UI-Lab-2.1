#!/usr/bin/env python3
"""Run declared native Flutter storage checks and retain reviewable evidence."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import signal
import subprocess
import sys
import time
import uuid
from host_test_lease import HostTestLease

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = Path(__file__).with_name('suites.json')


def fingerprint(root):
    paths = set()
    for folder in ('lib', 'test', 'integration_test'):
        paths.update((root / folder).rglob('*.dart'))
    paths.update((root / 'tooling/storage_qa').glob('*.py'))
    paths.update(p for p in (root / 'android/app/src').rglob('*') if p.is_file())
    vendor = root / 'third_party/image_picker_android'
    for subtree in ('lib', 'android/src', 'pigeons'):
        paths.update(p for p in (vendor / subtree).rglob('*') if p.is_file())
    for name in ('pubspec.yaml', 'android/build.gradle.kts', 'UPSTREAM.json'):
        if (vendor / name).is_file():
            paths.add(vendor / name)
    android_config = root / 'android/app/build.gradle.kts'
    if android_config.exists():
        paths.add(android_config)
    for name in ('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml',
                 'tooling/storage_qa/suites.json', 'tooling/storage_qa/run_storage_qa.py'):
        paths.add(root / name)
    digest = hashlib.sha256()
    for path in sorted(paths):
        digest.update(str(path.relative_to(root)).encode())
        digest.update(b'\0')
        digest.update(hashlib.sha256(path.read_bytes()).digest())
    return {'sha256': digest.hexdigest(), 'files': len(paths)}


def evaluate_log(path, expected_paths):
    done = False
    protocol_success = False
    passed = skipped = failed = 0
    observed = set()
    started = set()
    completed = set()
    for line in path.read_text(errors='replace').splitlines():
        try:
            event = json.loads(line)
        except (ValueError, TypeError):
            continue  # Flutter startup diagnostics are retained in the raw log.
        if not isinstance(event, dict):
            continue
        kind = event.get('type')
        if kind == 'suite':
            observed.add(str(Path(event['suite']['path']).resolve()))
        elif kind == 'testStart':
            started.add(event['test']['id'])
        elif kind == 'done':
            done = True
            protocol_success = event.get('success') is True
        elif kind == 'testDone':
            completed.add(event['testID'])
            if event.get('result') != 'success':
                failed += 1
            elif event.get('skipped'):
                skipped += 1
            elif not event.get('hidden'):
                passed += 1
    missing = sorted(set(map(str, expected_paths)) - observed)
    incomplete = sorted(started - completed)
    unrecognized = sorted(completed - started)
    return {'protocol_completed': done, 'protocol_success': protocol_success, 'passed_tests': passed,
            'failed_tests': failed, 'skipped_tests': skipped,
            'missing_suites': missing, 'unfinished_tests': incomplete,
            'unrecognized_completions': unrecognized,
            'passed': done and protocol_success and passed > 0 and failed == 0 and skipped == 0 and not missing and not incomplete and not unrecognized}


def stop_process(process):
    if process.poll() is not None:
        return
    if os.name == 'nt':
        subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        os.killpg(process.pid, signal.SIGTERM)
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        if os.name != 'nt':
            os.killpg(process.pid, signal.SIGKILL)
        else:
            process.kill()
        process.wait()


def git_value(*args):
    result = subprocess.run(['git', *args], cwd=ROOT, capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


def select_paths(root, manifest, suites=None, *, all_tests=False):
    if all_tests and suites:
        raise ValueError('Choose all tests or named suites, not both')
    if all_tests:
        paths = {'all': sorted(p.resolve() for p in (root / 'test').rglob('*_test.dart'))}
    else:
        paths = {suite: [(root / value).resolve() for value in manifest['suites'][suite]]
                 for suite in dict.fromkeys(suites or manifest['suites'].keys())}
    for suite, files in paths.items():
        if not files or len(set(files)) != len(files) or any(
                not p.is_file() or not p.is_relative_to((root / 'test').resolve())
                for p in files):
            raise ValueError(f'Invalid, duplicate or missing test path in {suite}')
    return paths


def run():
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument('--suite', action='append', choices=['core', 'domains', 'editors'])
    selection.add_argument('--all', action='store_true', help='Run every discovered *_test.dart under test/')
    parser.add_argument('--timeout-seconds', type=int, default=900)
    args = parser.parse_args()
    if args.timeout_seconds <= 0:
        parser.error('timeout must be positive')
    manifest = json.loads(MANIFEST.read_text())
    if manifest['version'] != 1:
        raise ValueError('Unsupported suite manifest')
    paths = select_paths(ROOT, manifest, args.suite, all_tests=args.all)
    selected = list(paths)
    run_id = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()) + '-' + uuid.uuid4().hex[:8]
    output = ROOT / 'build' / 'storage_qa' / run_id
    output.mkdir(parents=True)
    version = subprocess.run(['flutter', '--version', '--machine'], cwd=ROOT,
                             capture_output=True, text=True, timeout=60)
    (output / 'flutter-version.txt').write_text(version.stdout + version.stderr)
    report = {'schema_version': 1, 'run_id': run_id, 'platform': platform.platform(),
              'python': platform.python_version(), 'git_head': git_value('rev-parse', 'HEAD'),
              'git_dirty': bool(git_value('status', '--porcelain')),
              'source_before': fingerprint(ROOT), 'selected_suites': selected,
              'test_inventory': {suite: [str(p.relative_to(ROOT)) for p in files] for suite, files in paths.items()},
              'results': [], 'passed': False,
              'limits': ['Host native tests only; no device, cloud, security certification, or UI acceptance claim.',
                         'Even all discovered tests do not prove complete workflow coverage.']}
    report_file = output / 'report.json'
    def write_report():
        temporary = output / 'report.tmp'
        temporary.write_text(json.dumps(report, indent=2) + '\n')
        temporary.replace(report_file)
    write_report()
    interrupted = False
    try:
        if version.returncode != 0:
            raise RuntimeError('Flutter version command failed')
        for suite in selected:
            command = ['flutter', 'test', '--machine', '--concurrency=1',
                       *[str(p.relative_to(ROOT)) for p in paths[suite]]]
            log = output / f'{suite}.jsonl'
            result = {'suite': suite, 'command': command, 'log': log.name,
                      'timeout': False, 'interrupted': False}
            start = time.monotonic()
            print(f'Running {suite}: {len(paths[suite])} files', flush=True)
            with log.open('w') as stream:
                process = subprocess.Popen(command, cwd=ROOT, stdout=stream,
                                           stderr=subprocess.STDOUT,
                                           start_new_session=os.name != 'nt')
                try:
                    process.wait(timeout=args.timeout_seconds)
                except subprocess.TimeoutExpired:
                    result['timeout'] = True
                    stop_process(process)
                except KeyboardInterrupt:
                    result['interrupted'] = True
                    interrupted = True
                    stop_process(process)
            result.update(evaluate_log(log, paths[suite]))
            result['exit_code'] = process.returncode
            result['elapsed_seconds'] = round(time.monotonic() - start, 3)
            result['passed'] = result['passed'] and process.returncode == 0 and not result['timeout'] and not interrupted
            report['results'].append(result)
            write_report()
            print(f"{suite}: {'PASS' if result['passed'] else 'FAIL'}", flush=True)
            if interrupted:
                break
    finally:
        report['source_after'] = fingerprint(ROOT)
        report['source_unchanged'] = report['source_before'] == report['source_after']
        report['passed'] = (not interrupted and report['source_unchanged'] and
                            len(report['results']) == len(selected) and
                            all(item['passed'] for item in report['results']))
        write_report()
        print(f'Report: {report_file}', flush=True)
    return 130 if interrupted else (0 if report['passed'] else 1)


def main():
    try:
        with HostTestLease():
            return run()
    except RuntimeError as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())

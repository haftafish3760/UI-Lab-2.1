#!/usr/bin/env python3
"""Capture stopped debuggable-app SQLite evidence without changing device data."""
import argparse
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import platform
import sys
import shutil
import sqlite3
import subprocess
import tempfile
from datetime import datetime, timezone


class CaptureError(RuntimeError):
    pass


@dataclass(frozen=True)
class CaptureOptions:
    serial: str
    output: Path
    adb: str = 'adb'
    package: str = 'com.maintainiac.ui_lab_2_1'
    remote_directory: str = 'files/maintainiac_ui_lab/sqlite'
    database: str = 'maintainiac.sqlite'
    expected_schema: int = 1

    def validate(self):
        if not self.serial.strip():
            raise CaptureError('An explicit device serial is required.')
        if not re.fullmatch(r'[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)+', self.package):
            raise CaptureError('Invalid Android package name.')
        remote = PurePosixPath(self.remote_directory)
        if (remote.is_absolute() or '..' in remote.parts or
                not re.fullmatch(r'[A-Za-z0-9_./-]+', self.remote_directory)):
            raise CaptureError('Use a simple relative app-data directory.')
        if not re.fullmatch(r'[A-Za-z0-9_-][A-Za-z0-9_.-]*', self.database):
            raise CaptureError('The database must be a plain filename.')
        if self.expected_schema < 0:
            raise CaptureError('Expected schema must be nonnegative.')


class Device:
    def __init__(self, options, run):
        self.options = options
        self.run = run

    def execute(self, arguments, output=subprocess.PIPE):
        return self.run([self.options.adb, '-s', self.options.serial, *arguments],
                        stdout=output, stderr=subprocess.PIPE, timeout=30,
                        check=False)

    def query(self, arguments):
        result = self.execute(arguments)
        if result.returncode:
            raise CaptureError('ADB command failed: ' + result.stderr.decode(errors='replace').strip())
        return result.stdout.decode(errors='strict').strip()

    def require_stopped(self):
        result = self.execute(['shell', 'pidof', self.options.package])
        if result.returncode == 1 and not result.stdout.strip():
            processes = self.query(['shell', 'ps', '-A', '-o', 'NAME']).splitlines()
            if not processes or processes[0].strip() != 'NAME':
                raise CaptureError('Could not inspect secondary app processes.')
            if any(name.strip() == self.options.package or
                   name.strip().startswith(self.options.package + ':')
                   for name in processes[1:]):
                raise CaptureError('An app process is running. Stop all app processes before capture.')
            return
        if result.returncode == 0 and result.stdout.strip():
            raise CaptureError('The app is running. Stop it before capturing SQLite files.')
        raise CaptureError('Could not establish that the app process is absent.')

    def source_names(self):
        listing = self.query(['shell', 'run-as', self.options.package, 'ls', '-1',
                              self.options.remote_directory]).splitlines()
        candidates = [self.options.database + suffix for suffix in ('', '-wal', '-shm', '-journal')]
        if self.options.database not in listing:
            raise CaptureError('The expected app database was not found.')
        return [name for name in candidates if name in listing]

    def copy(self, name, destination):
        remote = self.options.remote_directory + '/' + name
        with destination.open('xb') as output:
            result = self.execute(['exec-out', 'run-as', self.options.package,
                                   'cat', remote], output=output)
        if result.returncode:
            raise CaptureError('Database file capture failed: ' + name)


def digest(path):
    checksum = hashlib.sha256()
    length = 0
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            checksum.update(block)
            length += len(block)
    return {'bytes': length, 'sha256': checksum.hexdigest()}


def validate_copy(raw, names, options):
    # SQLite may rebuild SHM or checkpoint when opening. Validate disposable
    # copies so the raw captured bytes and their hashes remain unchanged.
    with tempfile.TemporaryDirectory(prefix='sqlite-capture-check-') as temporary:
        folder = Path(temporary)
        for name in names:
            shutil.copyfile(raw / name, folder / name)
        connection = sqlite3.connect((folder / options.database).as_uri() + '?mode=ro')
        try:
            schema = connection.execute('PRAGMA user_version').fetchone()[0]
            integrity = connection.execute('PRAGMA integrity_check').fetchall()
            foreign_keys = connection.execute('PRAGMA foreign_key_check').fetchall()
            if schema != options.expected_schema:
                raise CaptureError('Captured database schema differs from the expected version.')
            if integrity != [('ok',)] or foreign_keys:
                raise CaptureError('Captured SQLite integrity or foreign-key check failed.')
            return {'schema': schema, 'integrity_check': 'ok', 'foreign_key_violations': 0}
        finally:
            connection.close()


def capture(options, run=subprocess.run):
    options.validate()
    # Never overwrite a previous result, including a failed capture.
    options.output.mkdir(parents=True, exist_ok=False)
    report = {
        'capture_valid': False,
        'tool_sha256': digest(Path(__file__))['sha256'],
        'python': sys.version, 'host': platform.platform(),
        'started_at_utc': datetime.now(timezone.utc).isoformat(),
        'serial': options.serial, 'package': options.package,
        'remote_directory': options.remote_directory, 'database': options.database,
        'expected_schema': options.expected_schema,
        'limits': [
            'QA capture only, not a live backup or proof of workflow correctness.',
            'Absence checks and matching repeated reads cannot prevent an external restart.',
            'No application/device data is changed; no app stop, reset or upload is performed.',
        ],
    }
    try:
        device = Device(options, run)
        if device.query(['get-state']) != 'device':
            raise CaptureError('The selected device is not ready.')
        device.require_stopped()
        report['app_absent_before'] = True
        names = device.source_names()
        raw = options.output / 'raw'
        raw.mkdir()
        for name in names:
            device.copy(name, raw / name)
        first = {name: digest(raw / name) for name in names}
        # Detect a restart/write between files instead of presenting a mixed
        # main/WAL set as a stable capture. Never omit an existing sidecar.
        device.require_stopped()
        if names != device.source_names():
            raise CaptureError('The database file set changed during capture.')
        with tempfile.TemporaryDirectory(prefix='sqlite-capture-repeat-') as temporary:
            for name in names:
                repeated = Path(temporary) / name
                device.copy(name, repeated)
                if digest(repeated) != first[name]:
                    raise CaptureError('Database bytes changed during capture: ' + name)
        device.require_stopped()
        report['app_absent_after'] = True
        report['files'] = first
        report['sqlite'] = validate_copy(raw, names, options)
        if any(digest(raw / name) != first[name] for name in names):
            raise CaptureError('Raw evidence changed during validation.')
        report['capture_valid'] = True
        return report
    except Exception as error:
        report['error'] = str(error)
        raise
    finally:
        report['finished_at_utc'] = datetime.now(timezone.utc).isoformat()
        (options.output / 'capture-report.json').write_text(json.dumps(report, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial', required=True)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--package', default=CaptureOptions.package)
    parser.add_argument('--remote-directory', default=CaptureOptions.remote_directory)
    parser.add_argument('--database', default=CaptureOptions.database)
    parser.add_argument('--expected-schema', type=int, default=1)
    args = parser.parse_args()
    try:
        capture(CaptureOptions(**vars(args)))
    except Exception as error:
        print('Capture refused or failed: ' + str(error))
        return 1
    print('Stable stopped-app capture: ' + str(args.output / 'capture-report.json'))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

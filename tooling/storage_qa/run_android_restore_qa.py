#!/usr/bin/env python3
"""Prebuild and verify the isolated package before Flutter selects its test app."""
import argparse
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
QA_PACKAGE = 'com.maintainiac.ui_lab_2_1.storageqa'
ENTRY = 'integration_test/local_restore_runtime_test.dart'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial', required=True)
    parser.add_argument('--sdk', type=Path)
    args = parser.parse_args()
    sdk = args.sdk
    if sdk is None:
        configured = os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME')
        candidates = [Path(configured)] if configured else [
            Path.home() / 'Library/Android/sdk', Path.home() / 'Android/Sdk']
        sdk = next((p for p in candidates if p.is_dir()), None)
    if sdk is None:
        parser.error('Provide --sdk for the installed Android SDK.')
    inspectors = sorted((sdk / 'build-tools').glob('*/aapt'))
    if not inspectors:
        parser.error('The SDK must provide aapt to verify package identity.')
    subprocess.run(['flutter', 'build', 'apk', '--debug', '--no-pub', '-t', ENTRY,
                    '--dart-define=STORAGE_QA=true'], cwd=ROOT, check=True)
    inspected = subprocess.run([
        str(inspectors[-1]), 'dump', 'badging',
        str(ROOT / 'build/app/outputs/flutter-apk/app-debug.apk'),
    ], check=True, capture_output=True, text=True)
    package = re.search(r"package: name='([^']+)'", inspected.stdout)
    if package is None or package.group(1) != QA_PACKAGE:
        raise RuntimeError('Refusing to launch a non-QA APK.')
    print(f'Verified test package: {QA_PACKAGE}', flush=True)
    # Flutter determines its cleanup package before startApp can rebuild. The
    # verified prebuild prevents stale normal-APK identity; no-uninstall also
    # preserves test evidence and never removes the normal installation.
    subprocess.run(['flutter', 'test', ENTRY, '-d', args.serial, '--no-pub',
                    '--no-uninstall', '--dart-define=STORAGE_QA=true'],
                   cwd=ROOT, check=True)


if __name__ == '__main__':
    main()

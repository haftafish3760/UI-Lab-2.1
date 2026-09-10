#!/usr/bin/env python3
"""Prebuild an isolated iOS restore test before Flutter reads bundle identity."""
import argparse
import os
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
QA_BUNDLE = 'com.maintainiac.uiLab21.storageqa'
ENTRY = 'integration_test/local_restore_runtime_test.dart'


def verify_bundle(app):
    with (app / 'Info.plist').open('rb') as stream:
        identity = plistlib.load(stream).get('CFBundleIdentifier')
    if identity != QA_BUNDLE:
        raise RuntimeError('Refusing to launch a non-QA iOS bundle.')


def verify_build(output, platform):
    # Flutter can retain a copied Runner.app from a previous build while Xcode's
    # Debug output has changed. Neither artifact alone proves safe selection.
    verify_bundle(output / f'Debug-{platform}' / 'Runner.app')
    verify_bundle(output / platform / 'Runner.app')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', required=True)
    parser.add_argument('--simulator', action='store_true')
    parser.add_argument('--team', help='Existing Apple development team ID, if required.')
    parser.add_argument('--build-only', action='store_true')
    args = parser.parse_args()
    if args.team and not re.fullmatch(r'[A-Z0-9]{10}', args.team):
        parser.error('Team must be a ten-character Apple development team ID.')
    if os.environ.get('XCODE_XCCONFIG_FILE'):
        parser.error('An existing Xcode override is active; do not silently replace it.')
    output = ROOT / 'build/storage_qa'
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='ios-identity-', dir=output) as scratch:
        settings = Path(scratch) / 'StorageQA.xcconfig'
        text = f'UILAB_APP_BUNDLE_IDENTIFIER = {QA_BUNDLE}\n'
        if args.team:
            text += f'DEVELOPMENT_TEAM = {args.team}\n'
        settings.write_text(text)
        environment = dict(os.environ, XCODE_XCCONFIG_FILE=str(settings))
        build = ['flutter', 'build', 'ios', '--debug', '--no-pub', '-t', ENTRY,
                 '--dart-define=STORAGE_QA=true']
        if args.simulator:
            build.append('--simulator')
        subprocess.run(build, cwd=ROOT, env=environment, check=True)
        platform = 'iphonesimulator' if args.simulator else 'iphoneos'
        verify_build(ROOT / 'build/ios', platform)
        print(f'Verified test bundle: {QA_BUNDLE}', flush=True)
        if not args.build_only:
            # Keep the same override during Flutter's rebuild. Prebuilding avoids
            # stale normal-app identity; no-uninstall preserves QA evidence.
            subprocess.run([
                'flutter', 'test', ENTRY, '-d', args.device, '--no-pub',
                '--no-uninstall', '--dart-define=STORAGE_QA=true',
            ], cwd=ROOT, env=environment, check=True)


if __name__ == '__main__':
    main()

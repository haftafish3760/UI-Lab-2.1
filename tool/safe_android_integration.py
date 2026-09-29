"""Build and verify the isolated APK before a no-uninstall device test run.

This is not a backup tool. Run only against an explicitly authorized device.
Do not run concurrent Android builds: Flutter reuses app-debug.apk.
"""
import argparse
from pathlib import Path
import re
import subprocess

QA_PACKAGE = 'com.maintainiac.ui_lab_2_1.storageqa'
NORMAL_PACKAGE = 'com.tameyourbiz.app'


def require_qa_package(badging):
    match = re.search(r"^package: name='([^']+)'", badging, re.MULTILINE)
    if not match or match.group(1) != QA_PACKAGE:
        raise RuntimeError('Refusing device execution: APK is not the isolated QA package.')


def commands(target, device, defines):
    for value in defines:
        if '=' not in value or value.split('=', 1)[0] == 'STORAGE_QA':
            raise ValueError('Additional defines must be NAME=value and cannot override STORAGE_QA.')
    flags = ['--dart-define=STORAGE_QA=true'] + [f'--dart-define={v}' for v in defines]
    return (
        ['flutter', 'build', 'apk', '--debug', f'--target={target}', *flags],
        ['flutter', 'test', target, '-d', device, '--no-uninstall', *flags],
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('target')
    parser.add_argument('--device', required=True)
    parser.add_argument('--aapt', required=True, help='Android SDK aapt executable')
    parser.add_argument('--define', action='append', default=[])
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    target = (root / args.target).resolve()
    if not target.is_file() or not target.is_relative_to(root / 'integration_test'):
        parser.error('Target must be an existing integration_test file in this repository.')
    build, test = commands(str(target), args.device, args.define)
    adb = ['adb', '-s', args.device]

    def normal_installed():
        listing = subprocess.check_output(
            [*adb, 'shell', 'pm', 'list', 'packages'], text=True,
        )
        return f'package:{NORMAL_PACKAGE}' in listing.splitlines()

    present_before = normal_installed()
    subprocess.run(build, cwd=root, check=True)
    apk = root / 'build/app/outputs/flutter-apk/app-debug.apk'
    require_qa_package(subprocess.check_output(
        [args.aapt, 'dump', 'badging', str(apk)], text=True,
    ))
    # Flutter can cache a previous APK identity before rebuilding. Prebuilding
    # corrects that identity; --no-uninstall independently disables its cleanup.
    try:
        subprocess.run(test, cwd=root, check=True)
    finally:
        if present_before and not normal_installed():
            raise RuntimeError('Normal package disappeared. Stop device work; do not reinstall automatically.')


if __name__ == '__main__':
    main()

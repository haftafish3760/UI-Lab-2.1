import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('screens cannot select concrete notification storage', () {
    for (final entity in Directory(
      'lib/src/screens',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      expect(
        source,
        isNot(contains('file_notification_repository.dart')),
        reason: '${entity.path} must use the authorized notification service.',
      );
      expect(
        source,
        isNot(contains('private_notification_repository.dart')),
        reason: '${entity.path} must not choose notification storage.',
      );
    }
  });

  test('governing blueprints point to the shared notification contract', () {
    for (final path in const [
      'docs/maintainiac_app_blueprint.md',
      'docs/product_control_blueprint.md',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('notification_system_blueprint.md'),
        reason: '$path must route engineers to the shared contract.',
      );
    }
  });

  test('notification blueprint keeps decisions and messaging separate', () {
    final blueprint = File(
      'docs/notification_system_blueprint.md',
    ).readAsStringSync();
    expect(blueprint, contains('Needs Attention'));
    expect(blueprint, contains('unrestricted employee chat'));
    expect(blueprint, contains('exact source route'));
    expect(blueprint, contains('private Application Support/app data'));
    expect(blueprint, contains('native delivery'));
    expect(
      blueprint,
      contains('never asks for notification permission at startup'),
    );
    expect(blueprint, contains('9:00 AM local time'));
    expect(blueprint, contains('ID-only tap payloads'));
    expect(blueprint, contains('device delivery proof'));
    expect(blueprint, contains('completed that replacement'));
    expect(blueprint, contains('former prototype notification'));
  });

  test('the retired prototype notification center cannot return', () {
    expect(
      File('lib/src/data/app_notification_center.dart').existsSync(),
      isFalse,
    );
    final appSource = File('lib/src/app.dart').readAsStringSync();
    expect(appSource, contains('NotificationUiController'));
    expect(appSource, isNot(contains('PrototypeNotificationCenter')));
  });
}

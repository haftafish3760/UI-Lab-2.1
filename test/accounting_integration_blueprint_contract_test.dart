import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('QuickBooks remains a replaceable future adapter', () {
    final accounting = File(
      'docs/accounting_integration_blueprint.md',
    ).readAsStringSync();

    expect(accounting, contains('no connector work is in the'));
    expect(accounting, contains('source of truth for its operational records'));
    expect(accounting, contains('only a possible future adapter'));
    expect(accounting, contains('not a current accommodation'));
    expect(accounting, contains('must not be expanded for QuickBooks'));
    expect(accounting, contains('AccountingConnector'));
    expect(accounting, contains('Provider IDs are never used'));
    expect(accounting, contains('External mapping contract'));
    expect(accounting, contains('Durable outbox and idempotency'));
    expect(
      accounting,
      contains('Timestamp-based last-write-wins is prohibited'),
    );
    expect(
      accounting,
      contains('cannot create a second accounting transaction'),
    );
    expect(accounting, contains('provider timeout with an'));
    expect(accounting, contains('deliberate one-way export'));
    expect(accounting, contains('never uploaded merely because'));
  });

  test('accounting failures cannot block local work or bypass permission', () {
    final accounting = File(
      'docs/accounting_integration_blueprint.md',
    ).readAsStringSync();

    expect(accounting, contains('Local create, edit, review, approval'));
    expect(accounting, contains('accounting.connection.manage'));
    expect(accounting, contains('Hiding an integration button is not'));
    expect(accounting, contains('secure credential storage'));
    expect(accounting, contains('Settings > Connections'));
    expect(accounting, contains('Could not send'));
    expect(accounting, contains('company/realm'));
    expect(accounting, contains('permission revocation while queued'));
    expect(accounting, contains('works fully without the connector'));
  });

  test('governing and migration blueprints point to the same contract', () {
    final files = <String>[
      'docs/product_control_blueprint.md',
      'docs/maintainiac_app_blueprint.md',
      'docs/work_lifecycle_blueprint.md',
      'docs/maintainiac_5_7_capability_migration_map.md',
    ];

    for (final path in files) {
      expect(
        File(path).readAsStringSync(),
        contains('accounting_integration_blueprint.md'),
        reason: '$path must route accounting work through one contract',
      );
    }
  });
}

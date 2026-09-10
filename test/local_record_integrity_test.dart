import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';

import 'support/storage/database_harness.dart';

void main() {
  late DatabaseHarness harness;
  setUp(() async => harness = await DatabaseHarness.create());
  tearDown(() async => harness.dispose());

  test(
    'structurally valid record changes cannot bypass revision history',
    () async {
      final store = await harness.openStore();
      await store.commit(
        organizationId: 'company',
        commandId: 'save',
        writes: [
          LocalRecordWrite(
            domain: 'expense',
            recordId: 'record',
            ownerId: 'alex',
            expectedRevision: 0,
            payload: {'amountMinorUnits': 12345},
          ),
        ],
        occurredAt: DateTime.utc(2026, 9, 9),
      );
      await store.database.customStatement(
        "UPDATE local_records SET payload = json_set(payload, '\$.amountMinorUnits', 1)",
      );
      expect(
        (await store.database.customSelect('PRAGMA quick_check').getSingle())
            .data
            .values
            .single,
        'ok',
      );
      await expectLater(store.database.verifyIntegrity(), throwsStateError);
    },
  );
  for (final corruption in [
    'history payload',
    'history gap',
    'missing journal',
  ]) {
    test('$corruption is refused without rewriting evidence', () async {
      final store = await harness.openStore();
      for (var revision = 0; revision < 2; revision++) {
        await store.commit(
          organizationId: 'company',
          commandId: 'save-$revision',
          writes: [
            LocalRecordWrite(
              domain: 'expense',
              recordId: 'record',
              ownerId: 'alex',
              expectedRevision: revision,
              payload: {'amountMinorUnits': 100 + revision},
            ),
          ],
          occurredAt: DateTime.utc(2026, 9, 9),
        );
      }
      await store.database.customStatement(switch (corruption) {
        'history payload' =>
          "UPDATE local_record_revisions SET payload = '{}' WHERE revision = 1",
        'history gap' =>
          'DELETE FROM local_record_revisions WHERE revision = 1',
        _ => "DELETE FROM local_change_outbox WHERE command_id = 'save-0'",
      });
      final before =
          (await store.database
                  .customSelect('SELECT * FROM local_record_revisions')
                  .get())
              .map((row) => row.data)
              .toList();
      await expectLater(store.database.verifyIntegrity(), throwsStateError);
      expect(
        (await store.database
                .customSelect('SELECT * FROM local_record_revisions')
                .get())
            .map((row) => row.data)
            .toList(),
        before,
      );
    });
  }

  test('hash verification reaches history beyond the first batch', () async {
    final store = await harness.openStore();
    await store.database.transaction(() async {
      for (var revision = 0; revision < 257; revision++) {
        await store.commit(
          organizationId: 'company',
          commandId: 'save-$revision',
          writes: [
            LocalRecordWrite(
              domain: 'expense',
              recordId: 'record',
              ownerId: 'alex',
              expectedRevision: revision,
              payload: {'amountMinorUnits': revision},
            ),
          ],
          occurredAt: DateTime.utc(2026, 9, 9),
        );
      }
    });
    await store.database.verifyIntegrity();
    await store.database.customStatement(
      "UPDATE local_record_revisions SET payload_hash = 'invalid' WHERE revision = 257",
    );
    await expectLater(
      store.database.verifyIntegrity(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Saved revision contents failed verification.',
        ),
      ),
    );
  });
}

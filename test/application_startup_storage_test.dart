import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_gateway.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/startup/open_ui_lab_application.dart';

void main() {
  test(
    'failed domain startup preserves drafts and allows reopening the same database',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'startup-storage-',
      );
      final file = File('${directory.path}/maintainiac.sqlite');
      Future<dynamic> open() => openUiLabApplication(
        storageDirectory: directory,
        nativeNotifications: const UnsupportedNativeNotificationGateway(),
      );
      try {
        final first = await open();
        await closeUnstartedApplication(first);
        var db = LocalDatabase.file(file);
        await LocalDraftStore(db).save(
          organizationId: 'test-company',
          domain: 'unfinished',
          draftId: 'test-draft',
          ownerId: 'test-user',
          expectedRevision: 0,
          payload: {'raw': '  unfinished input  '},
          occurredAt: DateTime.now().toUtc(),
        );
        final original = await db
            .customSelect(
              "SELECT record_id, payload FROM local_records WHERE domain = 'directory/customers' LIMIT 1",
            )
            .getSingle();
        await db.customStatement(
          "UPDATE local_records SET payload = '{}' WHERE domain = 'directory/customers' AND record_id = ?",
          [original.read<String>('record_id')],
        );
        await db.close();
        await expectLater(open(), throwsA(isA<Object>()));
        db = LocalDatabase.file(file);
        final retained = await LocalDraftStore(db).find(
          organizationId: 'test-company',
          domain: 'unfinished',
          draftId: 'test-draft',
          ownerId: 'test-user',
        );
        expect(retained!.payload, contains('  unfinished input  '));
        expect(retained.revision, 1);
        // Simulates correcting the external failure; the application itself never repairs or resets data.
        await db.customStatement(
          'UPDATE local_records SET payload = ? WHERE domain = ? AND record_id = ?',
          [
            original.read<String>('payload'),
            'directory/customers',
            original.read<String>('record_id'),
          ],
        );
        await db.close();
        final reopened = await open();
        await closeUnstartedApplication(reopened);
        db = LocalDatabase.file(file);
        expect((await db.select(db.localDrafts).get()).single.revision, 1);
        await db.close();
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}

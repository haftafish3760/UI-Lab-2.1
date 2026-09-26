import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_gateway.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_store.dart';
import 'package:ui_lab_2_1/src/startup/open_ui_lab_application.dart';

void main() {
  test(
    'normal startup preserves Work data without a review-example marker',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'startup-preservation-',
      );
      LocalDatabase? database;
      UiLabApp? application;
      try {
        database = LocalDatabase.file(File('${root.path}/maintainiac.sqlite'));
        final time = DateTime.utc(2026, 9, 25);
        // An unrecognized Work subdomain also belongs to its creator. Startup
        // must not erase it just because today's UI does not understand it.
        await LocalRecordStore(database).commit(
          organizationId: expenseUiLabOrganizationId,
          commandId: 'preserved-development-command',
          occurredAt: time,
          writes: [
            LocalRecordWrite(
              domain: 'work/development-evidence',
              recordId: 'owner-record',
              ownerId: expenseUiLabOwnerEmployeeId,
              expectedRevision: 0,
              payload: {
                'notes': 'Created by the owner, not a disposable fixture',
              },
            ),
          ],
        );
        await LocalDraftStore(database).save(
          organizationId: expenseUiLabOrganizationId,
          domain: 'work/estimate',
          draftId: 'unfinished-estimate',
          ownerId: expenseUiLabOwnerEmployeeId,
          expectedRevision: 0,
          payload: {'rawAmount': '12.', 'notes': '  unfinished input  '},
          occurredAt: time,
        );
        final tables = [
          'local_records',
          'local_record_revisions',
          'local_drafts',
          'local_commands',
          'local_change_outbox',
        ];
        Future<Map<String, List<Map<String, dynamic>>>> snapshot(
          LocalDatabase db,
        ) async => {
          for (final table in tables)
            table: (await db.customSelect('SELECT * FROM $table').get())
                .map((row) => Map<String, dynamic>.from(row.data))
                .toList(),
        };
        final before = await snapshot(database);
        await database.close();
        database = null;
        for (var reopen = 0; reopen < 2; reopen++) {
          application =
              await openUiLabApplication(
                    storageDirectory: root,
                    nativeNotifications:
                        const UnsupportedNativeNotificationGateway(),
                  )
                  as UiLabApp;
          final db = application.workSession!.repository.database;
          final after = await snapshot(db);
          for (final table in tables) {
            for (final original in before[table]!) {
              expect(
                after[table],
                contains(equals(original)),
                reason: '$table lost data',
              );
            }
          }
          await db.verifyIntegrity();
          await closeUnstartedApplication(application);
          application = null;
        }
      } finally {
        if (application != null) await closeUnstartedApplication(application);
        await database?.close();
        await root.delete(recursive: true);
      }
    },
  );
}

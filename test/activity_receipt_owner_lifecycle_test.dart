import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/day_notes/day_note_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/workday/workday_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/workday/start_workday_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';

void main() {
  for (final kind in ['note', 'start', 'receipt']) {
    for (final during in [false, true]) {
      test(
        '$kind owner disposal ${during ? 'during' : 'before'} operation',
        () async {
          final root = await Directory.systemTemp.createTemp('activity-owner-');
          final persistence = await LocalPersistence.open(directory: root);
          final notes = await openUiLabDayNotes(persistence.database);
          final workday = await openUiLabWorkdaySession(persistence.database);
          final receipts = ReceiptDraftUiController(
            AuthorizedReceiptDraftService(persistence.receiptDrafts),
            receiptDraftUiLabOwnerPermissions(),
          );
          final source = File('${root.path}/source.jpg');
          await source.writeAsBytes([1, 3, 5, 7], flush: true);
          final target = switch (kind) {
            'note' => notes,
            'start' => workday,
            _ => receipts,
          };
          try {
            if (!during) target.dispose();
            final pending = switch (kind) {
              'note' => notes.openDraft(
                date: DateTime(2030),
                employeeId: 'alex',
              ),
              'start' => workday.openStartDraft(
                employeeId: 'alex',
                vehicleId: 'transit-12',
                initialOdometer: '0.0',
              ),
              _ => receipts.create(
                draftId: 'lifecycle-receipt',
                title: 'Receipt',
                expenseDate: DateTime(2030),
                evidence: [
                  ReceiptEvidenceImport(
                    sourcePath: source.path,
                    originalName: 'source.jpg',
                    kind: ReceiptDraftEvidenceKind.photo,
                  ),
                ],
                occurredAtUtc: DateTime.now().toUtc(),
              ),
            };
            if (during) target.dispose();
            if (kind == 'receipt') {
              expect(await pending, during ? isNotNull : isNull);
            } else {
              await expectLater(pending, throwsStateError);
            }
            final pause = await persistence.database.draftSessions
                .pauseAndFlush();
            pause.release();
            await persistence.database.verifyIntegrity();
          } finally {
            for (final owner in [notes, workday, receipts]) {
              if (!identical(owner, target)) owner.dispose();
            }
            await persistence.close();
            await root.delete(recursive: true);
          }
        },
      );
    }
  }
}

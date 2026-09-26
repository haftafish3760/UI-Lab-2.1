import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';

void main() {
  test(
    'same-time import failure preserves acknowledged receipt evidence',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'receipt-preservation-',
      );
      var persistence = await LocalPersistence.open(directory: root);
      ReceiptDraftUiController controller() => ReceiptDraftUiController(
        AuthorizedReceiptDraftService(persistence.receiptDrafts),
        receiptDraftUiLabOwnerPermissions(),
      );
      var ui = controller();
      try {
        final source = await File(
          '${root.path}/source.jpg',
        ).writeAsBytes([7, 8, 9]);
        final imported = ReceiptEvidenceImport(
          sourcePath: source.path,
          originalName: 'source.jpg',
          kind: ReceiptDraftEvidenceKind.photo,
        );
        final time = DateTime.utc(2026, 9, 25);
        await ui.load();
        final created = (await ui.create(
          draftId: 'preserve',
          title: 'Receipt',
          expenseDate: time,
          evidence: [imported],
          occurredAtUtc: time,
        ))!;
        final original = created.activeEvidence.single;
        final savedFile = File(original.localPath);
        final originalBytes = await savedFile.readAsBytes();
        await persistence.database.customStatement(
          "CREATE TRIGGER reject_receipt BEFORE UPDATE ON local_records "
          "WHEN NEW.domain = 'receipt-drafts/records' "
          "BEGIN SELECT RAISE(ABORT, 'injected write failure'); END",
        );
        final rejected = await ui.update(
          draftId: created.draftId,
          title: 'Rejected change',
          expenseDate: time,
          expectedRevision: created.lifecycle.revision,
          retainedEvidenceIds: [original.evidenceId],
          addedEvidence: [imported],
          occurredAtUtc: time,
        );
      expect(rejected, isNull);
      expect(ui.failure, isNotNull);
      expect(ui.failure!.kind, ReceiptDraftUiFailureKind.storage);
        expect(
          await savedFile.exists(),
          isTrue,
          reason: 'A failed append must never remove already-saved evidence',
        );
        expect(await savedFile.readAsBytes(), originalBytes);
        expect(await source.readAsBytes(), originalBytes);
        final retainedCopies = await root
            .list(recursive: true)
            .where((entry) => entry is File && entry.path.endsWith('.image'))
            .toList();
        expect(
          retainedCopies,
          hasLength(2),
          reason: 'A failed save must not automatically delete the new copy',
        );
        await persistence.database.customStatement(
          'DROP TRIGGER reject_receipt',
        );
        ui.dispose();
        await persistence.close();
        persistence = await LocalPersistence.open(directory: root);
        ui = controller();
        await ui.load();
        final reopened = ui.records.single;
        expect(reopened.title, created.title);
        expect(reopened.lifecycle.revision, created.lifecycle.revision);
        expect(reopened.activeEvidence.single.localPath, original.localPath);
        final retried = (await ui.update(
          draftId: created.draftId,
          title: 'Retried',
          expenseDate: time,
          expectedRevision: reopened.lifecycle.revision,
          retainedEvidenceIds: [original.evidenceId],
          addedEvidence: [imported],
          occurredAtUtc: time,
        ))!;
        expect(
          retried.activeEvidence.map((e) => e.evidenceId).toSet(),
          hasLength(2),
        );
        expect(
          retried.activeEvidence.map((e) => e.localPath).toSet(),
          hasLength(2),
        );
        expect(await savedFile.readAsBytes(), originalBytes);
      } finally {
        ui.dispose();
        await persistence.close();
        await root.delete(recursive: true);
      }
    },
  );
}

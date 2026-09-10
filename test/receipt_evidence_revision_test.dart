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
    'unknown evidence and stale review revisions cannot change the saved receipt',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'receipt-evidence-revision-',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      var controller = ReceiptDraftUiController(
        AuthorizedReceiptDraftService(persistence.receiptDrafts),
        receiptDraftUiLabOwnerPermissions(),
      );
      try {
        await controller.load();
        final imports = <ReceiptEvidenceImport>[];
        for (final name in ['first.jpg', 'second.jpg']) {
          final file = File('${directory.path}/$name');
          await file.writeAsBytes([1, 2, 3]);
          imports.add(
            ReceiptEvidenceImport(
              sourcePath: file.path,
              originalName: name,
              kind: ReceiptDraftEvidenceKind.photo,
            ),
          );
        }
        final created = (await controller.create(
          draftId: 'receipt',
          title: 'Receipt',
          expenseDate: DateTime(2026, 9, 9),
          evidence: imports,
          occurredAtUtc: DateTime.utc(2026, 9, 9),
        ))!;
        final invalid = await controller.update(
          draftId: created.draftId,
          title: created.title,
          expenseDate: created.expenseDate,
          retainedEvidenceIds: [
            created.activeEvidence.first.evidenceId,
            'unknown-evidence',
          ],
          addedEvidence: const [],
          occurredAtUtc: DateTime.utc(2026, 9, 9, 1),
        );
        expect(invalid, isNull);
        expect(controller.failure?.kind, ReceiptDraftUiFailureKind.invalid);
        await controller.load();
        final retained = controller.records.single;
        expect(retained.lifecycle.revision, created.lifecycle.revision);
        expect(
          retained.activeEvidence.map((e) => e.evidenceId),
          created.activeEvidence.map((e) => e.evidenceId),
        );
        final reversed = created.activeEvidence
            .map((e) => e.evidenceId)
            .toList()
            .reversed
            .toList();
        final updated = await controller.update(
          draftId: created.draftId,
          expectedRevision: created.lifecycle.revision,
          title: created.title,
          expenseDate: created.expenseDate,
          retainedEvidenceIds: reversed,
          addedEvidence: const [],
          occurredAtUtc: DateTime.utc(2026, 9, 9, 2),
        );
        expect(updated, isNotNull);
        final stale = await controller.update(
          draftId: created.draftId,
          expectedRevision: created.lifecycle.revision,
          title: created.title,
          expenseDate: created.expenseDate,
          retainedEvidenceIds: created.activeEvidence.map((e) => e.evidenceId),
          addedEvidence: const [],
          occurredAtUtc: DateTime.utc(2026, 9, 9, 3),
        );
        expect(stale, isNull);
        expect(controller.failure?.kind, ReceiptDraftUiFailureKind.conflict);
        await controller.load();
        expect(
          controller.records.single.lifecycle.revision,
          updated!.lifecycle.revision,
        );
        expect(
          controller.records.single.activeEvidence.map((e) => e.evidenceId),
          reversed,
        );
        controller.dispose();
        await persistence.close();
        persistence = await LocalPersistence.open(directory: directory);
        controller = ReceiptDraftUiController(
          AuthorizedReceiptDraftService(persistence.receiptDrafts),
          receiptDraftUiLabOwnerPermissions(),
        );
        expect(await controller.load(), isTrue);
        expect(
          controller.records.single.activeEvidence.map((e) => e.evidenceId),
          reversed,
        );
        expect(
          controller.records.single.lifecycle.revision,
          updated.lifecycle.revision,
        );
      } finally {
        controller.dispose();
        await persistence.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

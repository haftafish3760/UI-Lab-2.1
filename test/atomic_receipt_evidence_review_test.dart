import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/receipts/atomic_receipt_evidence_review.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';

void main() {
  test(
    'evidence metadata and raw input commit together; failures retain originals and input',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'atomic-evidence-review-',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      final permissions = receiptDraftUiLabOwnerPermissions();
      var controller = ReceiptDraftUiController(
        AuthorizedReceiptDraftService(persistence.receiptDrafts),
        permissions,
      );
      try {
        await controller.load();
        final imports = <ReceiptEvidenceImport>[];
        for (final name in ['first.jpg', 'second.jpg']) {
          final file = File('${directory.path}/$name');
          await file.writeAsBytes(name.codeUnits);
          imports.add(
            ReceiptEvidenceImport(
              sourcePath: file.path,
              originalName: name,
              kind: ReceiptDraftEvidenceKind.photo,
            ),
          );
        }
        final original = (await controller.create(
          draftId: 'receipt',
          title: 'Receipt',
          expenseDate: DateTime(2026, 9, 9),
          evidence: imports,
          occurredAtUtc: DateTime.utc(2026, 9, 9),
        ))!;
        final order = [original.activeEvidence.last.evidenceId];
        final inputId = AtomicReceiptEvidenceReview.draftIdFor(
          permissions.actorEmployeeId,
          original.draftId,
        );
        final raw = {
          'sourceId': original.draftId,
          'sourceRevision': original.lifecycle.revision,
          'orderedEvidenceIds': order,
        };
        final inputRevision = await persistence.drafts.save(
          organizationId: permissions.organizationId,
          ownerId: permissions.actorEmployeeId,
          domain: AtomicReceiptEvidenceReview.draftDomain,
          draftId: inputId,
          expectedRevision: 0,
          payload: raw,
          occurredAt: DateTime.now(),
        );
        final checkpoint = LocalDraftCheckpoint(
          domain: AtomicReceiptEvidenceReview.draftDomain,
          draftId: inputId,
          revision: inputRevision,
        );
        final service = AtomicReceiptEvidenceReview(persistence.receiptDrafts);
        Future<StoredReceiptDraft> confirm({
          ReceiptDraftCommandPermissions? asUser,
          List<String>? ids,
        }) => service.confirm(
          receiptId: original.draftId,
          expectedRevision: original.lifecycle.revision,
          orderedEvidenceIds: ids ?? order,
          permissions: asUser ?? permissions,
          checkpoint: checkpoint,
          occurredAtUtc: DateTime.utc(2026, 9, 9, 1),
        );
        await expectLater(
          confirm(
            asUser: ReceiptDraftCommandPermissions(
              organizationId: permissions.organizationId,
              actorEmployeeId: permissions.actorEmployeeId,
              permissionRevision: 'denied',
              readScope: null,
            ),
          ),
          throwsA(isA<ReceiptDraftPermissionDeniedException>()),
        );
        await expectLater(
          confirm(ids: [original.activeEvidence.first.evidenceId]),
          throwsA(isA<ReceiptDraftRevisionConflictException>()),
        );
        await persistence.database.customStatement(
          "CREATE TRIGGER fail_review_consumption BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
        await expectLater(confirm(), throwsA(isA<Exception>()));
        await controller.load();
        expect(
          controller.records.single.lifecycle.revision,
          original.lifecycle.revision,
        );
        expect(controller.records.single.activeEvidence.length, 2);
        final retained = await persistence.drafts.find(
          organizationId: permissions.organizationId,
          ownerId: permissions.actorEmployeeId,
          domain: checkpoint.domain,
          draftId: checkpoint.draftId,
        );
        expect(persistence.drafts.decode(retained!), raw);
        await persistence.database.customStatement(
          'DROP TRIGGER fail_review_consumption',
        );
        final confirmed = await confirm();
        expect(confirmed.lifecycle.revision, original.lifecycle.revision + 1);
        expect(confirmed.activeEvidence.map((e) => e.evidenceId), order);
        expect(confirmed.evidence.length, 2);
        for (final evidence in original.evidence) {
          expect(
            await File(evidence.localPath).readAsBytes(),
            evidence.originalName.codeUnits,
          );
        }
        expect(
          await persistence.drafts.find(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
            domain: checkpoint.domain,
            draftId: checkpoint.draftId,
          ),
          isNull,
        );
        await expectLater(
          confirm(),
          throwsA(isA<ReceiptDraftRevisionConflictException>()),
        );
        controller.dispose();
        await persistence.close();
        persistence = await LocalPersistence.open(directory: directory);
        controller = ReceiptDraftUiController(
          AuthorizedReceiptDraftService(persistence.receiptDrafts),
          permissions,
        );
        await controller.load();
        expect(
          controller.records.single.lifecycle.revision,
          confirmed.lifecycle.revision,
        );
        expect(
          controller.records.single.activeEvidence.map((e) => e.evidenceId),
          order,
        );
        expect(
          controller.records.single.evidence
              .firstWhere(
                (e) => e.evidenceId == original.evidence.first.evidenceId,
              )
              .state,
          ReceiptDraftEvidenceState.removed,
        );
      } finally {
        controller.dispose();
        await persistence.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

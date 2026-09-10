import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_workflow_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_review_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_evidence_draft_workflow.dart';
import 'receipt_evidence_draft_workflow_test.dart'
    show openEvidenceSession, seedEvidence;
import 'expense_draft_workflow_test.dart' show initialExpense, change;

void main() {
  test(
    'receipt review and evidence recover without publishing; fresh changed or closed sources block resume',
    () async {
      final dir = await Directory.systemTemp.createTemp('receipt-catalog-');
      var p = await LocalPersistence.open(directory: dir);
      addTearDown(() async {
        await p.close();
        await dir.delete(recursive: true);
      });
      var app = await openEvidenceSession(p);
      final source = await seedEvidence(app, dir);
      final review = await app.openReviewDraft(
        receiptId: source.draftId,
        initial: initialExpense(),
      );
      review.updateInput(
        change(review.input, {'amount': '-', 'vendor': 'Unfinished'}),
      );
      await review.session.close();
      final evidence = await app.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      evidence.updateInput(evidence.input.remove(0));
      await evidence.session.close();
      final originals = {
        review.session.draftId: review.session.input,
        evidence.session.draftId: evidence.session.input,
      };
      await p.close();
      p = await LocalPersistence.open(directory: dir);
      app = await openEvidenceSession(p);
      final recovery = ReceiptWorkflowDraftRecovery(app);
      final entries = await recovery.list();
      expect(entries, hasLength(2));
      for (final entry in entries) {
        expect(
          entry.preview.availability,
          DraftRecoveryAvailability.recoverable,
        );
        final resumed = await recovery.resume(entry);
        final session = switch (resumed) {
          ResumedReceiptReview(:final controller) => controller.session,
          ResumedReceiptEvidence(:final controller) => controller.session,
        };
        expect(session.input, originals[entry.draftId]);
        expect(session.savedRevision, entry.revision);
        await session.close();
        final wrong = DraftRecoverySelection(
          domain: entry.domain,
          draftId: entry.draftId,
          revision: entry.revision + 1,
        );
        await expectLater(
          entry.domain == 'expenses/receipt-review'
              ? app.openReviewDraft(
                  receiptId: source.draftId,
                  initial: initialExpense(),
                  recoverySelection: wrong,
                )
              : app.openEvidenceDraft(
                  receiptId: source.draftId,
                  expectedRevision: source.lifecycle.revision,
                  recoverySelection: wrong,
                ),
          throwsA(isA<LocalRecordConflict>()),
        );
      }
      expect(app.expenses.records, isEmpty);
      expect(app.receipts.records.single.activeEvidence, hasLength(2));
      final other = await openEvidenceSession(p);
      expect(
        await other.receipts.update(
          draftId: source.draftId,
          title: 'Changed receipt',
          expenseDate: source.expenseDate,
          retainedEvidenceIds: source.activeEvidence.map((e) => e.evidenceId),
          addedEvidence: [],
          occurredAtUtc: DateTime.now().toUtc(),
        ),
        isNotNull,
      );
      expect(
        (await recovery.list()).every(
          (e) => e.preview.availability == DraftRecoveryAvailability.conflict,
        ),
        isTrue,
      );
      for (final entry in entries) {
        await expectLater(recovery.resume(entry), throwsStateError);
      }
      expect(
        await other.receipts.discard(
          draftId: source.draftId,
          occurredAtUtc: DateTime.now().toUtc(),
        ),
        isTrue,
      );
      expect(
        (await recovery.list()).every(
          (e) =>
              e.preview.availability ==
              DraftRecoveryAvailability.parentUnavailable,
        ),
        isTrue,
      );
      for (final entry in entries) {
        final saved = (await p.drafts.find(
          organizationId: app.receiptPermissions.organizationId,
          ownerId: app.receiptPermissions.actorEmployeeId,
          domain: entry.domain,
          draftId: entry.draftId,
        ))!;
        expect(p.drafts.decode(saved), originals[entry.draftId]);
        expect(saved.revision, entry.revision);
      }
      await recovery.discard(entries.first);
      await expectLater(recovery.resume(entries.first), throwsA(anything));
      expect(await recovery.list(), hasLength(1));
    },
  );
}

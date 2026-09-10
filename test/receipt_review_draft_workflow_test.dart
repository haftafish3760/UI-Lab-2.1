import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_review_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'expense_draft_workflow_test.dart' show initialExpense, change;
import 'receipt_evidence_draft_workflow_test.dart'
    show openEvidenceSession, seedEvidence;

void main() {
  test(
    'malformed receipt review stays retained and explicitly discardable',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'receipt-review-malformed-',
      );
      final persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      final session = await openEvidenceSession(persistence);
      final source = await seedEvidence(session, directory);
      var workflow = await session.openReviewDraft(
        receiptId: source.draftId,
        initial: initialExpense(),
      );
      final good = workflow.input;
      await workflow.session.close();
      final draft = workflow.session;
      final raw = {...draft.input, 'receiptSourceId': 'different-receipt'};
      await persistence.drafts.save(
        organizationId: draft.organizationId,
        domain: draft.domain,
        draftId: draft.draftId,
        ownerId: draft.ownerId,
        expectedRevision: draft.savedRevision,
        payload: raw,
        occurredAt: DateTime.now(),
      );
      workflow = await session.openReviewDraft(
        receiptId: source.draftId,
        initial: initialExpense(),
      );
      expect(workflow.recoveryAvailable, isFalse);
      expect(workflow.session.input, raw);
      expect(() => workflow.updateInput(good), throwsStateError);
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.discard();
      expect(
        session.receipts.recordById(source.draftId)!.lifecycle.revision,
        source.lifecycle.revision,
      );
      expect(session.expenses.records, isEmpty);
      await workflow.session.close();
    },
  );
  test(
    'receipt review reopens raw values and commits expense receipt and draft together',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'receipt-review-workflow-',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      var session = await openEvidenceSession(persistence);
      final source = await seedEvidence(session, directory);
      var workflow = await session.openReviewDraft(
        receiptId: source.draftId,
        initial: initialExpense(),
      );
      workflow.updateInput(change(workflow.input, {'amount': '-'}));
      final raw = workflow.session.input;
      await workflow.session.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openEvidenceSession(persistence);
      workflow = await session.openReviewDraft(
        receiptId: source.draftId,
        initial: initialExpense(),
      );
      expect(workflow.session.input, raw);
      expect(workflow.input.receiptImageCount, 2);
      await expectLater(workflow.confirm(), throwsStateError);
      workflow.updateInput(change(workflow.input, {'amount': '25.50'}));
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_review_confirm BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      expect(await workflow.confirm(), isNull);
      expect(session.expenses.records, isEmpty);
      expect(
        session.receipts.recordById(source.draftId)!.state,
        ReceiptDraftState.inProgress,
      );
      expect(workflow.session.input['amount'], '25.50');
      await persistence.database.customStatement(
        'DROP TRIGGER fail_review_confirm',
      );
      final result = (await workflow.confirm())!;
      expect(result.amount, 25.5);
      expect(result.receiptImageCount, 2);
      expect(
        (await session.receipts.findById(
          draftId: source.draftId,
          includeClosed: true,
        )).record!.submittedExpenseId,
        result.id,
      );
      expect(session.expenses.records, hasLength(1));
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );

  test(
    'stale receipt review preserves its original revision and cannot submit',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'receipt-review-stale-',
      );
      final persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      final session = await openEvidenceSession(persistence);
      final source = await seedEvidence(session, directory);
      var workflow = await session.openReviewDraft(
        receiptId: source.draftId,
        initial: initialExpense(),
      );
      workflow.updateInput(change(workflow.input, {'amount': '25.50'}));
      await workflow.session.close();
      expect(
        await session.receipts.update(
          draftId: source.draftId,
          title: 'Updated receipt',
          expenseDate: source.expenseDate,
          retainedEvidenceIds: source.activeEvidence.map((e) => e.evidenceId),
          addedEvidence: [],
          occurredAtUtc: DateTime.now().toUtc(),
          expectedRevision: source.lifecycle.revision,
        ),
        isNotNull,
      );
      workflow = await session.openReviewDraft(
        receiptId: source.draftId,
        initial: initialExpense(),
      );
      expect(workflow.isStale, isTrue);
      expect(workflow.input.receiptSourceRevision, source.lifecycle.revision);
      expect(await workflow.confirm(), isNull);
      expect(session.expenses.records, isEmpty);
      expect(workflow.session.input['amount'], '25.50');
      await workflow.session.close();
    },
  );
}

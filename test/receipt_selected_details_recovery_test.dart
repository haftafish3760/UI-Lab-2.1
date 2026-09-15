import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_evidence_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_field_proposals.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_selected_details.dart';
import 'receipt_evidence_draft_workflow_test.dart'
    show openEvidenceSession, seedEvidence;

final reviewedDetails = ReceiptFieldProposals(
  merchant: 'Juniper Supply',
  date: DateTime(2030, 1, 2),
  totalMinor: 1230,
  subtotalMinor: 1200,
  taxMinor: 30,
  rows: const ['Juniper Supply', 'SUBTOTAL 12.00', 'TAX 0.30', 'TOTAL 12.30'],
  warnings: const ['Check the purchase date.'],
);

void main() {
  for (final removeSource in [false, true]) {
    test('selected details survive both restart boundaries; removed source '
        '$removeSource cannot fill a form', () async {
      final directory = await Directory.systemTemp.createTemp(
        'selected-review-',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      var session = await openEvidenceSession(persistence);
      final expenseCount = session.expenses.records.length;
      final source = await seedEvidence(session, directory);
      final first = source.activeEvidence.first;
      // Two separate source identities deliberately have identical bytes.
      expect(first.sha256, source.activeEvidence.last.sha256);
      final selected = ReceiptSelectedDetails(
        evidenceId: first.evidenceId,
        sha256: first.sha256,
        details: reviewedDetails,
      );
      var review = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      review.updateInput(review.input.useDetails(selected).remove(0));
      await review.session.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openEvidenceSession(persistence);
      review = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      expect(review.input.selectedDetails!.toJson(), selected.toJson());
      expect(review.input.undo().selectedDetails!.toJson(), selected.toJson());
      if (!removeSource) review.updateInput(review.input.undo().move(0, 1));
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_review_details BEFORE DELETE ON local_drafts "
        "BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      await expectLater(review.confirm(), throwsA(isA<Object>()));
      expect(
        session.receipts.recordById(source.draftId)!.selectedDetails,
        isNull,
      );
      expect(review.input.selectedDetails!.toJson(), selected.toJson());
      await persistence.database.customStatement(
        'DROP TRIGGER fail_review_details',
      );
      final committed = await review.confirm();
      await session.expenses.load();
      expect(session.expenses.records.length, expenseCount);
      expect(committed.state, ReceiptDraftState.inProgress);
      expect(committed.submittedExpenseId, isNull);
      expect(committed.lifecycle.revision, source.lifecycle.revision + 1);
      expect(
        committed.activeSelectedDetails?.toJson(),
        removeSource ? null : selected.toJson(),
      );
      await review.session.close();
      await persistence.close();
      // Simulates closing after Continue, before an expense editor has opened.
      persistence = await LocalPersistence.open(directory: directory);
      session = await openEvidenceSession(persistence);
      final reopened = session.receipts.recordById(source.draftId)!;
      expect(
        reopened.activeSelectedDetails?.toJson(),
        removeSource ? null : selected.toJson(),
      );
      review = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: reopened.lifecycle.revision,
      );
      expect(
        review.input.selectedDetails?.toJson(),
        removeSource ? null : selected.toJson(),
      );
      if (!removeSource) {
        // Clearing suggestions also persists; a new review cannot revive them.
        review.updateInput(review.input.useDetails(null));
        expect((await review.confirm()).selectedDetails, isNull);
      }
      await review.session.close();
    });
  }

  test('a mismatched checksum cannot be recovered or confirmed', () async {
    final directory = await Directory.systemTemp.createTemp(
      'wrong-review-source-',
    );
    final persistence = await LocalPersistence.open(directory: directory);
    addTearDown(() async {
      await persistence.close();
      await directory.delete(recursive: true);
    });
    final session = await openEvidenceSession(persistence);
    final source = await seedEvidence(session, directory);
    var review = await session.openEvidenceDraft(
      receiptId: source.draftId,
      expectedRevision: source.lifecycle.revision,
    );
    final wrong = ReceiptSelectedDetails(
      evidenceId: source.activeEvidence.first.evidenceId,
      sha256: '0' * 64,
      details: reviewedDetails,
    );
    expect(
      () => review.updateInput(review.input.useDetails(wrong)),
      throwsStateError,
    );
    await review.session.close();
    final draft = review.session;
    final payload = {...draft.input, 'selectedDetails': wrong.toJson()};
    await persistence.drafts.save(
      organizationId: draft.organizationId,
      ownerId: draft.ownerId,
      domain: draft.domain,
      draftId: draft.draftId,
      expectedRevision: draft.savedRevision,
      payload: payload,
      occurredAt: DateTime.now(),
    );
    review = await session.openEvidenceDraft(
      receiptId: source.draftId,
      expectedRevision: source.lifecycle.revision,
    );
    expect(review.recoveryAvailable, isFalse);
    expect(review.session.input, payload);
    // Bypassing the UI/controller still cannot commit a mismatched proposal.
    await expectLater(
      session.confirmEvidenceReview(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
        orderedEvidenceIds: source.activeEvidence
            .map((e) => e.evidenceId)
            .toList(),
        checkpoint: LocalDraftCheckpoint(
          domain: draft.domain,
          draftId: draft.draftId,
          revision: review.session.savedRevision,
        ),
      ),
      throwsA(isA<Object>()),
    );
    await expectLater(review.confirm(), throwsStateError);
    await review.session.discard();
    await review.session.close();
    expect(
      session.receipts.recordById(source.draftId)!.selectedDetails,
      isNull,
    );
  });

  test(
    'selected details codec preserves missing values and rejects corruption',
    () {
      final selected = ReceiptSelectedDetails(
        evidenceId: 'photo',
        sha256: 'a' * 64,
        details: const ReceiptFieldProposals(
          merchant: null,
          totalMinor: null,
          subtotalMinor: null,
          taxMinor: null,
          rows: [],
          warnings: [],
        ),
      );
      expect(
        ReceiptSelectedDetails.fromJson(selected.toJson()).details.totalMinor,
        isNull,
      );
      expect(
        () => ReceiptSelectedDetails.fromJson({
          ...selected.toJson(),
          'version': 2,
        }),
        throwsFormatException,
      );
      expect(
        () => ReceiptSelectedDetails.fromJson({
          ...selected.toJson(),
          'date': '2030-02-30',
        }),
        throwsFormatException,
      );
      expect(
        () => ReceiptSelectedDetails.fromJson({
          ...selected.toJson(),
          'totalMinor': '12.30',
        }),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => selected.details.rows.add('changed'),
        throwsUnsupportedError,
      );
    },
  );
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_checkpoint.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_item_read.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_item_parser.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_photo_text.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_evidence_draft_workflow.dart';
import 'receipt_evidence_draft_workflow_test.dart'
    show openEvidenceSession, seedEvidence;

ReceiptItemRead exampleItemRead(
  String id,
  String checksum, {
  String description = 'Copper fitting',
}) {
  final text = ReceiptPhotoText(
    text: '$description 2 box x 3.499 7.00\nCOUPON -1.00\nTOTAL 6.00',
    lines: [
      ReceiptTextLine('$description 2 box x 3.499 7.00', 10, 20, 400, 40),
      const ReceiptTextLine('COUPON -1.00', 10, 45, 300, 60),
      const ReceiptTextLine('TOTAL 6.00', 10, 65, 300, 80),
    ],
    warnings: const ['Check the receipt edges.'],
  );
  return ReceiptItemRead(
    evidenceId: id,
    sha256: checksum,
    parserVersion: receiptItemParserVersion,
    readAtUtc: DateTime.utc(2030, 1, 2),
    recognizedText: text.text,
    sourceLines: text.lines,
    warnings: text.warnings,
    result: proposeReceiptItems(text, sourceId: id),
  );
}

void main() {
  test(
    'item observations preserve decimals, source boxes and unresolved rows',
    () {
      final original = exampleItemRead('photo', 'a' * 64);
      final restored = ReceiptItemRead.fromJson(original.toJson());
      expect(restored.toJson(), original.toJson());
      expect(restored.result.items.single.unitPrice!.decimalValue, '3.499');
      expect(
        restored.result.items.single.sourceRows.single.sourceLines.single.left,
        10,
      );
      expect(restored.result.unresolvedRows.single.text, 'COUPON -1.00');
      expect(restored.sourceLines.length, 3);
      expect(restored.warnings, ['Check the receipt edges.']);
      expect(() => restored.result.items.clear(), throwsUnsupportedError);
      expect(
        () => ReceiptItemRead.fromJson({...original.toJson(), 'version': 2}),
        throwsFormatException,
      );
      expect(
        () => decodeReceiptItemReads({
          'itemReads': [original.toJson(), original.toJson()],
        }),
        throwsFormatException,
      );
      expect(decodeReceiptItemReads({}), isEmpty);
      expect(
        () => decodeReceiptItemReads({'itemReads': null}),
        throwsFormatException,
      );
    },
  );

  for (final removeFirst in [false, true]) {
    test(
      'multiple photo reads survive recovery and atomic handoff; removed=$removeFirst',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'receipt-item-read-',
        );
        var persistence = await LocalPersistence.open(directory: directory);
        addTearDown(() async {
          await persistence.close();
          await directory.delete(recursive: true);
        });
        var session = await openEvidenceSession(persistence);
        final source = await seedEvidence(session, directory);
        final first = source.activeEvidence.first,
            second = source.activeEvidence.last;
        expect(first.sha256, second.sha256);
        final a = exampleItemRead(first.evidenceId, first.sha256);
        final b = exampleItemRead(
          second.evidenceId,
          second.sha256,
          description: 'Work gloves',
        );
        var review = await session.openEvidenceDraft(
          receiptId: source.draftId,
          expectedRevision: source.lifecycle.revision,
        );
        review.updateInput(
          review.input.recordItems(a).recordItems(b).remove(0),
        );
        await review.session.close();
        await persistence.close();
        persistence = await LocalPersistence.open(directory: directory);
        session = await openEvidenceSession(persistence);
        review = await session.openEvidenceDraft(
          receiptId: source.draftId,
          expectedRevision: source.lifecycle.revision,
        );
        expect(review.input.itemReads.map((read) => read.toJson()), [
          a.toJson(),
          b.toJson(),
        ]);
        if (!removeFirst) review.updateInput(review.input.undo().move(0, 1));
        await persistence.database.customStatement(
          "CREATE TRIGGER fail_item_read_commit BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
        );
        await expectLater(review.confirm(), throwsA(isA<Object>()));
        expect(session.receipts.recordById(source.draftId)!.itemReads, isEmpty);
        expect(review.input.itemReads.length, 2);
        await persistence.database.customStatement(
          'DROP TRIGGER fail_item_read_commit',
        );
        final committed = await review.confirm();
        expect(
          committed.activeItemReads.map((read) => read.evidenceId),
          removeFirst
              ? [second.evidenceId]
              : [second.evidenceId, first.evidenceId],
        );
        await session.expenses.load();
        expect(session.expenses.records, isEmpty);
        await review.session.close();
        await persistence.close();
        persistence = await LocalPersistence.open(directory: directory);
        session = await openEvidenceSession(persistence);
        final reopened = session.receipts.recordById(source.draftId)!;
        expect(
          reopened.activeItemReads.map((read) => read.toJson()),
          committed.activeItemReads.map((read) => read.toJson()),
        );
        review = await session.openEvidenceDraft(
          receiptId: source.draftId,
          expectedRevision: reopened.lifecycle.revision,
        );
        final replacement = exampleItemRead(
          second.evidenceId,
          second.sha256,
          description: 'Corrected gloves',
        );
        review.updateInput(review.input.recordItems(replacement));
        expect(review.input.itemReads.length, removeFirst ? 1 : 2);
        if (!removeFirst) {
          expect(
            review.input.itemReads.first.result.items.single.description,
            'Copper fitting',
          );
        }
        await review.session.close();
      },
    );
  }

  test(
    'wrong image checksum cannot bypass recovery or atomic confirmation',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'wrong-item-read-',
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
      final wrong = exampleItemRead(
        source.activeEvidence.first.evidenceId,
        '0' * 64,
      );
      expect(
        () => review.updateInput(review.input.recordItems(wrong)),
        throwsStateError,
      );
      await review.session.close();
      final draft = review.session;
      final payload = {
        ...draft.input,
        'itemReads': [wrong.toJson()],
      };
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
      expect(session.receipts.recordById(source.draftId)!.itemReads, isEmpty);
      await review.session.close();
    },
  );
}

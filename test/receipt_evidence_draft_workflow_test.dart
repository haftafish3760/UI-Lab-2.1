import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_evidence_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_submission_session.dart';
import 'package:ui_lab_2_1/src/data/receipts/atomic_receipt_submission.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'recurring_payment_draft_workflow_test.dart' show openSession;

Future<ReceiptSubmissionSession> openEvidenceSession(
  LocalPersistence persistence,
) async {
  final expenseSession = await openSession(persistence);
  final receipts = ReceiptDraftUiController(
    AuthorizedReceiptDraftService(persistence.receiptDrafts),
    receiptDraftUiLabOwnerPermissions(),
  );
  await receipts.load();
  addTearDown(receipts.dispose);
  return ReceiptSubmissionSession(
    drafts: persistence.drafts,
    service: AtomicReceiptSubmission(
      expenses: persistence.expenses,
      receiptDrafts: persistence.receiptDrafts,
      employeeLabelForId: (_) => 'Alex Morgan',
      jobLabelForId: (_) => null,
    ),
    expenses: expenseSession.expenses,
    receipts: receipts,
    expensePermissions: expenseSession.expensePermissions,
    receiptPermissions: receiptDraftUiLabOwnerPermissions(),
  );
}

Future<StoredReceiptDraft> seedEvidence(
  ReceiptSubmissionSession session,
  Directory directory, {
  List<int> bytes = const [1, 2, 3],
}) async {
  final file = File('${directory.path}/source.jpg');
  await file.writeAsBytes(bytes);
  return (await session.receipts.create(
    draftId: 'receipt',
    title: 'Receipt',
    expenseDate: DateTime(2030, 1, 2),
    evidence: [
      for (final name in ['first.jpg', 'second.jpg'])
        ReceiptEvidenceImport(
          sourcePath: file.path,
          originalName: name,
          kind: ReceiptDraftEvidenceKind.photo,
        ),
    ],
    occurredAtUtc: DateTime.utc(2030, 1, 2),
  ))!;
}

void main() {
  test(
    'evidence workflow reopens undo state and retries one atomic confirmation',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'evidence-workflow-',
      );
      var persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      var session = await openEvidenceSession(persistence);
      final source = await seedEvidence(session, directory);
      var workflow = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      workflow.updateInput(workflow.input.remove(0));
      final raw = workflow.session.input;
      await workflow.session.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: directory);
      session = await openEvidenceSession(persistence);
      workflow = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      expect(workflow.session.input, raw);
      expect(workflow.input.undoId, source.activeEvidence.first.evidenceId);
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_evidence BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      await expectLater(workflow.confirm(), throwsA(isA<Object>()));
      expect(
        session.receipts.recordById(source.draftId)!.activeEvidence.length,
        2,
      );
      expect(workflow.session.input, raw);
      await persistence.database.customStatement('DROP TRIGGER fail_evidence');
      final saved = await workflow.confirm();
      expect(
        saved.activeEvidence.single.evidenceId,
        source.activeEvidence.last.evidenceId,
      );
      expect(saved.lifecycle.revision, source.lifecycle.revision + 1);
      for (final evidence in source.activeEvidence) {
        expect(await File(evidence.localPath).exists(), isTrue);
      }
      await expectLater(workflow.confirm(), throwsStateError);
      await workflow.session.close();
    },
  );
  test(
    'malformed retained review can be discarded but cannot be replaced or confirmed',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'evidence-invalid-workflow-',
      );
      final persistence = await LocalPersistence.open(directory: directory);
      addTearDown(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      final session = await openEvidenceSession(persistence);
      final source = await seedEvidence(session, directory);
      var workflow = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
      );
      final good = workflow.input;
      await workflow.session.close();
      final draft = workflow.session;
      final raw = {...draft.input, 'selectedId': 'missing'};
      await persistence.drafts.save(
        organizationId: draft.organizationId,
        domain: draft.domain,
        draftId: draft.draftId,
        ownerId: draft.ownerId,
        expectedRevision: draft.savedRevision,
        payload: raw,
        occurredAt: DateTime.now(),
      );
      workflow = await session.openEvidenceDraft(
        receiptId: source.draftId,
        expectedRevision: source.lifecycle.revision,
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
      await workflow.session.close();
    },
  );
}

import '../storage/draft_repository.dart';
import 'package:flutter/widgets.dart';
import '../expenses/expense_workflow_models.dart';
import '../expenses/authorized_expense_service.dart';
import '../expenses/expense_ui_repository_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/serialized_async_actions.dart';
import 'atomic_receipt_submission.dart';
import 'receipt_media_session.dart';
import 'atomic_receipt_evidence_review.dart';
import 'receipt_draft_record.dart';
import 'authorized_receipt_draft_service.dart';
import 'receipt_draft_submission_coordinator.dart';
import 'receipt_draft_ui_controller.dart';

/// App-owned authorized submission and post-commit projection refresh.
class ReceiptSubmissionSession {
  ReceiptSubmissionSession({
    required this.service,
    this.drafts,
    this.media,
    required this.expenses,
    required this.receipts,
    required this.expensePermissions,
    required this.receiptPermissions,
  });
  final AtomicReceiptSubmission service;
  final DraftRepository? drafts;
  final ReceiptMediaSession? media;
  final ExpenseUiRepositoryController expenses;
  final ReceiptDraftUiController receipts;
  final ExpenseCommandPermissions expensePermissions;
  final ReceiptDraftCommandPermissions receiptPermissions;
  final _actions = SerializedAsyncActions();
  Future<AsyncActionPause> pauseOperations() => _actions.pauseAndDrain();

  Future<StoredReceiptDraft> confirmEvidenceReview({
    required String receiptId,
    required int expectedRevision,
    required List<String> orderedEvidenceIds,
    required LocalDraftCheckpoint checkpoint,
  }) => _actions.run(() async {
    final result = await AtomicReceiptEvidenceReview(service.receiptDrafts)
        .confirm(
          receiptId: receiptId,
          expectedRevision: expectedRevision,
          orderedEvidenceIds: orderedEvidenceIds,
          permissions: receiptPermissions,
          checkpoint: checkpoint,
          occurredAtUtc: DateTime.now().toUtc(),
        );
    await receipts.load();
    return result;
  });

  Future<ReceiptDraftSubmissionResult> submit({
    required String draftId,
    required int expectedReceiptRevision,
    required ExpenseRecord reviewedRecord,
    required String paidByEmployeeId,
    required DateTime occurredAtUtc,
    LocalDraftCheckpoint? draftCheckpoint,
  }) => _actions.run(() async {
    final result = await service.submit(
      draftId: draftId,
      expectedReceiptRevision: expectedReceiptRevision,
      reviewedRecord: reviewedRecord,
      paidByEmployeeId: paidByEmployeeId,
      expensePermissions: expensePermissions,
      receiptPermissions: receiptPermissions,
      occurredAtUtc: occurredAtUtc,
      draftCheckpoint: draftCheckpoint,
    );
    if (result.succeeded) {
      // A projection refresh failure is surfaced by its controller; it cannot
      // turn an already committed business command into an uncommitted result.
      await expenses.load();
      await receipts.load();
    }
    return result;
  });
}

class ReceiptSubmissionScope extends InheritedWidget {
  const ReceiptSubmissionScope({
    required this.session,
    required super.child,
    super.key,
  });
  final ReceiptSubmissionSession session;
  static ReceiptSubmissionSession? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ReceiptSubmissionScope>()
      ?.session;
  @override
  bool updateShouldNotify(ReceiptSubmissionScope oldWidget) =>
      !identical(session, oldWidget.session);
}

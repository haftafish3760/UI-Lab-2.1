import '../expenses/expense_workflow_models.dart';
import '../expenses/authorized_expense_service.dart';
import '../expenses/expense_ui_repository_bridge.dart';
import '../expenses/expense_ui_repository_controller.dart';
import '../expenses/local_expense_repository.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_draft_store.dart';
import 'receipt_draft_record.dart';
import '../storage/sqlite_domain_snapshot_store.dart';
import 'authorized_receipt_draft_service.dart';
import 'local_receipt_draft_repository.dart';
import 'receipt_draft_submission_coordinator.dart';
import 'receipt_draft_ui_controller.dart';

/// Runs existing authorized business commands against isolated buffers, then
/// commits both domains and optional recovery input in one SQLite transaction.
/// Live UI controllers must reload their projections after this returns success.
class AtomicReceiptSubmission {
  const AtomicReceiptSubmission({
    required this.expenses,
    required this.receiptDrafts,
    required this.employeeLabelForId,
    required this.jobLabelForId,
  });
  final LocalExpenseRepository expenses;
  final LocalReceiptDraftRepository receiptDrafts;
  final ExpenseEmployeeLabelResolver employeeLabelForId;
  final ExpenseJobLabelResolver jobLabelForId;

  Future<ReceiptDraftSubmissionResult> submit({
    required String draftId,
    required int expectedReceiptRevision,
    required ExpenseRecord reviewedRecord,
    required String paidByEmployeeId,
    required ExpenseCommandPermissions expensePermissions,
    required ReceiptDraftCommandPermissions receiptPermissions,
    required DateTime occurredAtUtc,
    LocalDraftCheckpoint? draftCheckpoint,
  }) async {
    if (expensePermissions.organizationId !=
            receiptPermissions.organizationId ||
        expensePermissions.actorEmployeeId !=
            receiptPermissions.actorEmployeeId) {
      return const ReceiptDraftSubmissionResult.failure(
        'Receipt and Expense sessions do not match.',
      );
    }
    try {
      return await expenses.withStagedWrites(
        (expenseStage) => receiptDrafts.withStagedSubmission((
          receiptStage,
        ) async {
          final expenseController = ExpenseUiRepositoryController(
            ExpenseUiRepositoryBridge(
              service: AuthorizedExpenseService(expenseStage.repository),
              employeeLabelForId: employeeLabelForId,
              jobLabelForId: jobLabelForId,
            ),
            expensePermissions,
          );
          final receiptController = ReceiptDraftUiController(
            AuthorizedReceiptDraftService(receiptStage.repository),
            receiptPermissions,
          );
          try {
            if (!await expenseController.load() ||
                !await receiptController.load()) {
              return const ReceiptDraftSubmissionResult.failure(
                'Receipt submission could not load its authorized records.',
              );
            }
            final receipt = receiptController.recordById(draftId);
            if (receipt == null) {
              final found = await receiptController.findById(
                draftId: draftId,
                includeClosed: true,
              );
              final closed = found.record;
              final confirmed = expenseController.recordById(
                'EXP-RECEIPT-$draftId',
              );
              final maySubmit =
                  closed != null &&
                  receiptPermissions.canTarget(closed) &&
                  (receiptPermissions.owns(closed)
                      ? receiptPermissions.canSubmitOwn
                      : receiptPermissions.canSubmitTeam);
              if (maySubmit &&
                  closed.state == ReceiptDraftState.submitted &&
                  closed.lifecycle.revision == expectedReceiptRevision + 1 &&
                  confirmed != null &&
                  closed.submittedExpenseId == confirmed.id &&
                  expenseController.receiptIdForExpense(confirmed.id) ==
                      draftId &&
                  confirmed.paidByEmployeeId == paidByEmployeeId &&
                  receiptSubmissionMatches(confirmed, reviewedRecord)) {
                if (draftCheckpoint != null) {
                  final remaining =
                      await LocalDraftStore(
                        receiptStage.prepare().database,
                      ).find(
                        organizationId: expensePermissions.organizationId,
                        domain: draftCheckpoint.domain,
                        draftId: draftCheckpoint.draftId,
                        ownerId: expensePermissions.actorEmployeeId,
                      );
                  if (remaining != null) {
                    return const ReceiptDraftSubmissionResult.failure(
                      'The expense is already confirmed, but separate unfinished input remains. Review it before continuing.',
                    );
                  }
                }
                return ReceiptDraftSubmissionResult.success(confirmed);
              }
            }
            if (receipt == null ||
                receipt.lifecycle.revision != expectedReceiptRevision) {
              return const ReceiptDraftSubmissionResult.failure(
                'The receipt changed after review started. Review it again before saving.',
              );
            }
            if (draftCheckpoint != null) {
              final store = LocalDraftStore(receiptStage.prepare().database);
              final retained = await store.find(
                organizationId: expensePermissions.organizationId,
                domain: draftCheckpoint.domain,
                draftId: draftCheckpoint.draftId,
                ownerId: expensePermissions.actorEmployeeId,
              );
              final input = retained == null ? null : store.decode(retained);
              if (draftCheckpoint.domain != 'expenses/receipt-review' ||
                  retained?.revision != draftCheckpoint.revision ||
                  input?['receiptSourceId'] != draftId ||
                  input?['receiptSourceRevision'] != expectedReceiptRevision) {
                return const ReceiptDraftSubmissionResult.failure(
                  'Saved review input does not match this receipt revision. Your input has been preserved.',
                );
              }
            }
            await receiptStage.repository.verifySubmissionEvidence(
              draftId: draftId,
              access: receiptPermissions.readAccess!,
              expectedRevision: expectedReceiptRevision,
            );
            final result =
                await ReceiptDraftSubmissionCoordinator(
                  expenses: expenseController,
                  receiptDrafts: receiptController,
                ).submit(
                  draftId: draftId,
                  reviewedRecord: reviewedRecord,
                  paidByEmployeeId: paidByEmployeeId,
                  occurredAtUtc: occurredAtUtc,
                );
            if (!result.succeeded) return result;
            await commitPreparedDomainChanges(
              [expenseStage.prepare(), receiptStage.prepare()],
              organizationId: expensePermissions.organizationId,
              ownerId: expensePermissions.actorEmployeeId,
              checkpoint: draftCheckpoint,
            );
            expenseStage.publishCommitted();
            receiptStage.publishCommitted();
            return result;
          } finally {
            expenseController.dispose();
            receiptController.dispose();
          }
        }),
      );
    } on Object {
      return const ReceiptDraftSubmissionResult.failure(
        'The receipt and Expense were not confirmed. Saved records and recovery input were preserved; retry saving.',
      );
    }
  }
}

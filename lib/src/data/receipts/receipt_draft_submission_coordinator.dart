import '../../screens/expenses/expense_models.dart';
import '../expenses/expense_ui_repository_controller.dart';
import 'receipt_draft_ui_controller.dart';

class ReceiptDraftSubmissionResult {
  const ReceiptDraftSubmissionResult._({
    required this.succeeded,
    this.expense,
    this.message,
  });

  const ReceiptDraftSubmissionResult.success(ExpenseRecord expense)
    : this._(succeeded: true, expense: expense);

  const ReceiptDraftSubmissionResult.failure(String message)
    : this._(succeeded: false, message: message);

  final bool succeeded;
  final ExpenseRecord? expense;
  final String? message;
}

/// Coordinates a durable Receipt Draft and its confirmed Expense record.
///
/// Expense creation happens first with a deterministic identity. If closing
/// the draft is interrupted, retry validates and reuses that exact Expense
/// instead of creating a duplicate.
class ReceiptDraftSubmissionCoordinator {
  const ReceiptDraftSubmissionCoordinator({
    required this.expenses,
    required this.receiptDrafts,
  });

  final ExpenseUiRepositoryController expenses;
  final ReceiptDraftUiController receiptDrafts;

  Future<ReceiptDraftSubmissionResult> submit({
    required String draftId,
    required ExpenseRecord reviewedRecord,
    required String paidByEmployeeId,
    required DateTime occurredAtUtc,
  }) async {
    final draft = receiptDrafts.recordById(draftId);
    if (draft == null) {
      return const ReceiptDraftSubmissionResult.failure(
        'That receipt draft is no longer available. Reload receipt drafts.',
      );
    }
    if (reviewedRecord.receiptImageCount != draft.activeEvidence.length) {
      return const ReceiptDraftSubmissionResult.failure(
        'The retained receipt evidence changed. Review the draft again before '
        'saving the Expense.',
      );
    }

    final expenseId = _expenseId(draftId);
    final requested = _withIdentity(reviewedRecord, expenseId);
    final deleted = expenses.deletedRecords.where(
      (record) => record.id == expenseId,
    );
    if (deleted.isNotEmpty) {
      return const ReceiptDraftSubmissionResult.failure(
        'The Expense for this receipt was removed. Restore it before '
        'finishing the receipt draft.',
      );
    }

    var expense = expenses.recordById(expenseId);
    if (expense != null &&
        (!_matches(expense, requested) ||
            expenses.receiptIdForExpense(expenseId) != draftId)) {
      return const ReceiptDraftSubmissionResult.failure(
        'An Expense with this receipt identity contains different confirmed '
        'values. Review it before trying again.',
      );
    }
    expense ??= await expenses.createFromReceiptDraft(
      record: requested,
      receiptDraftId: draftId,
      paidByEmployeeId: paidByEmployeeId,
      occurredAtUtc: occurredAtUtc,
    );
    if (expense == null) {
      return ReceiptDraftSubmissionResult.failure(
        expenses.failure?.message ??
            'The Expense could not be saved. The receipt draft remains open.',
      );
    }

    final closed = await receiptDrafts.submit(
      draftId: draftId,
      expenseId: expense.id,
      occurredAtUtc: occurredAtUtc,
    );
    if (!closed) {
      return ReceiptDraftSubmissionResult.failure(
        'The Expense was saved, but the receipt draft still needs to be '
        'closed. ${receiptDrafts.failure?.message ?? ''}'
        ' Try Save expense again; it will reuse the saved Expense.',
      );
    }
    return ReceiptDraftSubmissionResult.success(expense);
  }
}

String _expenseId(String draftId) => 'EXP-RECEIPT-$draftId';

ExpenseRecord _withIdentity(ExpenseRecord record, String expenseId) =>
    ExpenseRecord(
      id: expenseId,
      vendor: record.vendor,
      category: record.category,
      amount: record.amount,
      date: record.date,
      owner: record.owner,
      paidByEmployeeId: record.paidByEmployeeId,
      job: record.job,
      jobId: record.jobId,
      receiptStatus: 'Receipt attached',
      receiptType: record.receiptType,
      receiptImageCount: record.receiptImageCount,
      lineItems: record.lineItems,
      receiptSubtotal: record.receiptSubtotal,
      salesTax: record.salesTax,
      prepareMaterialsReview: record.prepareMaterialsReview,
      approvalStatus: record.approvalStatus,
      approvalReason: record.approvalReason,
      requiresSubmitterAttention: record.requiresSubmitterAttention,
      submitterAttentionReason: record.submitterAttentionReason,
    );

bool _matches(ExpenseRecord existing, ExpenseRecord requested) {
  final existingDate = existing.resolvedDate;
  final requestedDate = requested.resolvedDate;
  if (existingDate == null || requestedDate == null) return false;
  return existing.vendor == requested.vendor &&
      existing.category == requested.category &&
      _sameMoney(existing.amount, requested.amount) &&
      _sameDate(existingDate, requestedDate) &&
      existing.paidByEmployeeId == requested.paidByEmployeeId &&
      existing.jobId == requested.jobId &&
      existing.receiptType == requested.receiptType &&
      _sameOptionalMoney(existing.receiptSubtotal, requested.receiptSubtotal) &&
      _sameMoney(existing.salesTax, requested.salesTax) &&
      existing.approvalStatus == requested.approvalStatus &&
      existing.approvalReason == requested.approvalReason &&
      _sameLines(existing.lineItems, requested.lineItems);
}

bool _sameLines(List<ExpenseLineItem> left, List<ExpenseLineItem> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a.id != b.id ||
        a.description != b.description ||
        a.category != b.category ||
        a.quantity != b.quantity ||
        a.unit != b.unit ||
        !_sameMoney(a.unitPrice, b.unitPrice) ||
        !_sameMoney(a.total, b.total) ||
        a.unitsPerPackage != b.unitsPerPackage ||
        a.partNumber != b.partNumber ||
        a.jobId != b.jobId) {
      return false;
    }
  }
  return true;
}

bool _sameOptionalMoney(double? left, double? right) =>
    left == null || right == null ? left == right : _sameMoney(left, right);

bool _sameMoney(double left, double right) =>
    (left * 100).round() == (right * 100).round();

bool _sameDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

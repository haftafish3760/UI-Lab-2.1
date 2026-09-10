import '../expenses/expense_workflow_models.dart';
import 'receipt_draft_record.dart';

typedef ReceiptDraftEmployeeLabelResolver = String Function(String employeeId);

abstract final class ReceiptDraftUiAdapter {
  static ExpenseReceiptDraft toUi(
    StoredReceiptDraft stored,
    ReceiptDraftEmployeeLabelResolver employeeLabelForId,
  ) => ExpenseReceiptDraft(
    id: stored.draftId,
    title: stored.title,
    expenseDate: stored.expenseDate,
    updatedOn: stored.lifecycle.updatedAtUtc.toLocal(),
    ownerEmployeeId: stored.ownerEmployeeId,
    owner: employeeLabelForId(stored.ownerEmployeeId),
    imageCount: stored.activeEvidence.length,
  );
}

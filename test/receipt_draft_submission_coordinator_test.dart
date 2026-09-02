import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/file_receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_submission_coordinator.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  test(
    'retry closes one draft without duplicating its saved Expense',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'receipt-draft-submit-',
      );
      addTearDown(() => root.delete(recursive: true));
      final evidence = File('${root.path}/receipt.jpg');
      await evidence.writeAsBytes([2, 4, 6, 8]);
      var receiptWriteCount = 0;
      final receiptRepository = await FileReceiptDraftRepository.open(
        Directory('${root.path}/receipts'),
        snapshotWriter: (target, bytes) async {
          receiptWriteCount += 1;
          if (receiptWriteCount == 2) {
            throw const FileSystemException('Simulated interrupted close');
          }
          await target.writeAsBytes(bytes, flush: true);
        },
      );
      final drafts = _receiptController(receiptRepository);
      final expenses = _expenseController(
        await FileExpenseRepository.open(Directory('${root.path}/expenses')),
      );
      addTearDown(drafts.dispose);
      addTearDown(expenses.dispose);
      await drafts.load();
      await expenses.load();
      final created = await drafts.create(
        draftId: 'draft-submit-1',
        title: 'Central Supply receipt',
        expenseDate: DateTime(2026, 9, 1),
        evidence: [
          ReceiptEvidenceImport(
            sourcePath: evidence.path,
            originalName: 'receipt.jpg',
            kind: ReceiptDraftEvidenceKind.photo,
          ),
        ],
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      );
      expect(created, isNotNull);
      final coordinator = ReceiptDraftSubmissionCoordinator(
        expenses: expenses,
        receiptDrafts: drafts,
      );
      final reviewed = _reviewedExpense();

      final interrupted = await coordinator.submit(
        draftId: created!.draftId,
        reviewedRecord: reviewed,
        paidByEmployeeId: 'alex',
        occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
      );
      expect(interrupted.succeeded, isFalse);
      expect(interrupted.message, contains('Expense was saved'));
      expect(interrupted.message, contains('reuse the saved Expense'));
      expect(expenses.records, hasLength(1));
      expect(drafts.records, hasLength(1));

      final retried = await coordinator.submit(
        draftId: created.draftId,
        reviewedRecord: reviewed,
        paidByEmployeeId: 'alex',
        occurredAtUtc: DateTime.utc(2026, 9, 1, 14),
      );
      expect(retried.succeeded, isTrue);
      expect(expenses.records, hasLength(1));
      expect(retried.expense?.id, 'EXP-RECEIPT-draft-submit-1');
      expect(drafts.records, isEmpty);

      final reopenedExpenses = await FileExpenseRepository.open(
        Directory('${root.path}/expenses'),
      );
      final storedExpense = await reopenedExpenses.findById(
        expenseId: 'EXP-RECEIPT-draft-submit-1',
        access: ExpenseAccess.company(
          organizationId: 'organization-1',
          employeeId: 'alex',
        ),
      );
      expect(storedExpense?.receiptId, 'draft-submit-1');
      final reopenedDrafts = await FileReceiptDraftRepository.open(
        Directory('${root.path}/receipts'),
      );
      final history = await reopenedDrafts.query(
        ReceiptDraftQuery(
          access: ReceiptDraftAccess.company(
            organizationId: 'organization-1',
            employeeId: 'alex',
          ),
          includeClosed: true,
        ),
      );
      expect(history.single.state, ReceiptDraftState.submitted);
      expect(history.single.submittedExpenseId, storedExpense?.expenseId);
      expect(history.single.activeEvidence, hasLength(1));
    },
  );
}

ExpenseUiRepositoryController _expenseController(
  ExpenseRepository repository,
) => ExpenseUiRepositoryController(
  ExpenseUiRepositoryBridge(
    service: AuthorizedExpenseService(repository),
    employeeLabelForId: (_) => 'Alex Morgan',
    jobLabelForId: (_) => null,
  ),
  ExpenseCommandPermissions(
    organizationId: 'organization-1',
    actorEmployeeId: 'alex',
    permissionRevision: 'permissions-1',
    readScope: ExpenseReadScope.company,
    canCreate: true,
    canEdit: true,
    canDelete: true,
    canRestore: true,
    canApprove: true,
    canManageOtherEmployees: true,
  ),
);

ReceiptDraftUiController _receiptController(
  ReceiptDraftRepository repository,
) => ReceiptDraftUiController(
  AuthorizedReceiptDraftService(repository),
  ReceiptDraftCommandPermissions(
    organizationId: 'organization-1',
    actorEmployeeId: 'alex',
    permissionRevision: 'permissions-1',
    readScope: ReceiptDraftReadScope.company,
    canCreate: true,
    canEditOwn: true,
    canEditTeam: true,
    canSubmitOwn: true,
    canSubmitTeam: true,
    canDiscardOwn: true,
    canDiscardTeam: true,
  ),
);

ExpenseRecord _reviewedExpense() => ExpenseRecord(
  id: 'temporary-editor-id',
  vendor: 'Central Supply',
  category: ExpenseCategory.materials,
  amount: 48.72,
  date: DateTime(2026, 9, 1),
  owner: 'Alex Morgan',
  paidByEmployeeId: 'alex',
  receiptStatus: 'Receipt reviewed',
  receiptType: ExpenseReceiptType.detailed,
  receiptImageCount: 1,
  receiptSubtotal: 45,
  salesTax: 3.72,
  lineItems: const [
    ExpenseLineItem(
      id: 'line-1',
      description: 'PEX adapter',
      category: ExpenseCategory.materials,
      quantity: 2,
      unit: 'each',
      unitPrice: 22.50,
    ),
  ],
);

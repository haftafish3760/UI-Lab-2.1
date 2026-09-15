import 'package:flutter/material.dart';
import 'expense_entry_choice_screen.dart';
import 'expense_editor_screen.dart';
import 'expense_models.dart';
import 'expense_permissions.dart';
import 'receipt_intake_screen.dart';

Future<void> openExpenseEntryFlow(
  BuildContext context, {
  required DateTime expenseDate,
  required ExpensePermissions permissions,
  required Future<ExpenseRecord?> Function(ExpenseRecord) onConfirm,
  ExpenseCategory initialCategory = ExpenseCategory.uncategorized,
}) async {
  if (!permissions.canView || !permissions.canCreate) return;
  String? receiptDraftId;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (entryContext) => ExpenseEntryChoiceScreen(
        canAttachReceipt: permissions.canAttachReceipt,
        canConfigureDisplay: permissions.canConfigureDisplay,
        initialCategory: initialCategory,
        onContinue: (choice) async {
          if (!entryContext.mounted || !permissions.canCreate) return;
          final saved = await Navigator.of(entryContext).push<ExpenseRecord>(
            MaterialPageRoute(
              builder: (_) => choice.withReceipt
                  ? ReceiptIntakeScreen(
                      draftId: receiptDraftId,
                      applyInitialSetup: true,
                      onDraftReady: (id) => receiptDraftId = id,
                      expenseDate: expenseDate,
                      initialReceiptType: choice.type,
                      initialCategory: choice.category,
                      permissions: permissions,
                    )
                  : ExpenseEditorScreen(
                      expenseDate: expenseDate,
                      initialReceiptType: choice.type,
                      initialCategory: choice.category,
                      startNewExpense: true,
                      permissions: permissions,
                      onConfirm: onConfirm,
                    ),
            ),
          );
          if (saved != null && entryContext.mounted) {
            Navigator.pop(entryContext);
          }
        },
      ),
    ),
  );
}

import '../../data/expenses/expense_entry_setup_input.dart';
import '../../data/expenses/expense_entry_setup_workflow.dart';
import '../../data/expenses/expense_draft_recovery.dart';
import '../../data/expenses/expense_ui_repository_controller.dart';
import '../../data/receipts/receipt_submission_session.dart';
import 'receipt_intake_settings_screen.dart';
import '../../shared/app_preferences.dart';
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
  ExpenseEntrySetupWorkflow? recoveredSetup,
}) async {
  if (!permissions.canView || !permissions.canCreate) return;
  final owner = ExpenseUiScope.maybeOf(context);
  final receipts = ReceiptSubmissionScope.maybeOf(context);
  late ExpenseEntrySetupWorkflow setup;
  try {
    if (owner == null) {
      throw StateError('Durable expense storage is unavailable.');
    }
    if (recoveredSetup != null &&
        (!identical(recoveredSetup.session.store, owner.drafts) ||
            recoveredSetup.session.organizationId != owner.organizationId ||
            recoveredSetup.session.ownerId != owner.actorEmployeeId)) {
      throw StateError('The expense setup owner changed.');
    }
    final preferences = readReceiptIntakeDisplayPreferences(
      context,
      const ReceiptIntakeDisplayPreferences(),
    );
    setup =
        recoveredSetup ??
        await owner.openEntrySetup(
          initial: ExpenseEntrySetupInput(
            date: expenseDate,
            category: initialCategory,
            detailChosen:
                !(AppPreferencesScope.maybeOf(
                      context,
                    )?.chooseReceiptDetailEachTime ??
                    false),
            receiptType: preferences.detailedReceipts
                ? ExpenseReceiptType.detailed
                : ExpenseReceiptType.basic,
          ),
        );
  } on Object {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense entry could not open. Please try again.'),
        ),
      );
    }
    return;
  }
  if (!context.mounted) {
    await setup.session.close();
    return;
  }
  String? committedDestination;
  bool committedWithReceipt = false;
  Future<ExpenseEntrySetupWorkflow?> returnToSetup() async {
    final id = committedDestination!;
    final returned = committedWithReceipt
        ? await receipts!.returnToReceiptSetup(id)
        : await owner.returnToManualSetup(id);
    if (returned != null) {
      await setup.session.close();
      setup = returned;
    }
    committedDestination = null;
    return returned;
  }

  try {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (entryContext) => ExpenseEntryChoiceScreen(
          workflow: setup,
          canAttachReceipt: permissions.canAttachReceipt,
          canConfigureDisplay: permissions.canConfigureDisplay,
          initialCategory: initialCategory,
          onContinue: (choice) async {
            if (!entryContext.mounted || !permissions.canCreate) return null;
            // The prior transfer may have committed before navigation/re-entry
            // failed. Recover that destination; never submit the sealed source again.
            if (committedDestination != null) return returnToSetup();
            late Widget next;
            final withReceipt =
                setup.input.continuation?.destination ==
                    ExpenseSetupDestination.receipt ||
                (setup.input.continuation == null && choice.withReceipt);
            if (withReceipt) {
              if (receipts == null) {
                throw StateError('Receipt storage is unavailable.');
              }
              final receipt = await receipts.continueExpenseSetup(setup);
              committedDestination = receipt.draftId;
              committedWithReceipt = true;
              next = ReceiptIntakeScreen(
                draftId: receipt.draftId,
                expenseDate: receipt.expenseDate,
                initialCategory: receipt.entrySetup!.category,
                initialReceiptType: receipt.entrySetup!.type,
                permissions: permissions,
              );
            } else {
              final id = await setup.continueManually(
                ownerLabel: 'Current user',
              );
              committedDestination = id;
              committedWithReceipt = false;
              final recovery = ExpenseDraftRecovery(owner);
              final entry = (await recovery.list()).singleWhere(
                (entry) => entry.draftId == id,
              );
              final workflow = await recovery.resume(entry);
              if (!entryContext.mounted) {
                await workflow.session.close();
                return null;
              }
              next = ExpenseEditorScreen(
                expenseDate: workflow.input.date,
                recoveredExpenseWorkflow: workflow,
                permissions: permissions,
                onConfirm: onConfirm,
              );
            }
            if (!entryContext.mounted) return null;
            final result = await Navigator.of(
              entryContext,
            ).push<ExpenseRecord>(MaterialPageRoute(builder: (_) => next));
            if (!entryContext.mounted) return null;
            if (result != null) {
              return null;
            }
            return returnToSetup();
          },
        ),
      ),
    );
  } finally {
    await setup.session.close();
  }
}

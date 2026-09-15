import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/expenses/expense_ui_repository_controller.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/localized_date.dart';
import '../../shared/local_draft_scope.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import '../dashboard/dashboard_models.dart';
import 'expense_correction_reason_dialog.dart';
import 'expense_detail_widgets.dart';
import 'expense_editor_screen.dart';
import 'expense_line_item_editor.dart';
import 'expense_models.dart';
import 'expense_permissions.dart';
import 'expense_receipt_document.dart';
import 'expense_receipt_evidence_screen.dart';
import 'expense_record_unavailable.dart';
import 'expense_save_feedback.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({
    required this.expenseId,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final String expenseId;
  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) {
    if (!permissions.canView) {
      return Scaffold(
        key: ValueKey('expense-detail-$expenseId'),
        body: const SafeArea(
          child: Center(
            child: Text('You do not have permission to view this expense.'),
          ),
        ),
      );
    }
    final scope = OperationalScope.of(context);
    final store = PrototypeOperationsScope.of(context);
    final expense = store.expenses
        .where((item) => item.id == expenseId)
        .firstOrNull;
    if (expense == null) {
      return ExpenseRecordUnavailable(
        screenKey: ValueKey('expense-detail-unavailable-$expenseId'),
      );
    }
    final isOwn = permissions.owns(paidByEmployeeId: expense.paidByEmployeeId);
    final canEdit =
        permissions.canViewAmounts && permissions.canEditRecord(isOwn: isOwn);
    final canRemove =
        permissions.canViewAmounts && permissions.canRemoveRecord(isOwn: isOwn);
    final canReview =
        permissions.canReviewCompanyExpenses &&
        expense.approvalStatus == ExpenseApprovalStatus.pending;
    return Scaffold(
      key: const ValueKey('expense-detail-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              key: const ValueKey('expense-detail-scroll'),
              padding: insets.copyWith(top: 10, bottom: 32),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.columnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExpensesScopeHeader(
                          view: scope.view,
                          selectedEmployeeId: scope.selectedEmployeeId,
                          onViewChanged: scope.setView,
                          onEmployeeChanged: scope.selectEmployee,
                          onSettings: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ExpensesSettingsScreen(),
                            ),
                          ),
                          showSettings: permissions.canConfigureDisplay,
                          workspaceLabel: 'Expense details',
                          showBackButton: true,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          operationalDateLabel(
                            context,
                            expense.resolvedDate ?? dashboardToday,
                          ),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                expense.displayVendor,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (canEdit)
                              OutlinedButton.icon(
                                key: const ValueKey('edit-expense-button'),
                                onPressed: () => _edit(context, store, expense),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: Text(
                                  expense.receiptImageCount > 0
                                      ? 'Correct receipt'
                                      : 'Edit expense',
                                ),
                              ),
                            if (canRemove) ...[
                              const SizedBox(width: 4),
                              PopupMenuButton<_ExpenseDetailAction>(
                                key: const ValueKey(
                                  'expense-detail-actions-button',
                                ),
                                tooltip: 'More expense actions',
                                onSelected: (action) {
                                  if (action == _ExpenseDetailAction.remove) {
                                    _remove(context, store, expense);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: _ExpenseDetailAction.remove,
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded),
                                        SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            'Move to removed expenses',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        ExpenseDetailSummary(expense: expense),
                        if (expense.approvalReason != null ||
                            expense.submitterAttentionReason != null) ...[
                          const SizedBox(height: 10),
                          ExpenseAttentionReason(expense: expense),
                        ],
                        const SizedBox(height: 10),
                        if (permissions.canViewAmounts)
                          ExpenseReceiptDocument(
                            expense: expense,
                            onOpenEvidence: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ExpenseReceiptEvidenceScreen(
                                  expenseId: expense.id,
                                  permissions: permissions,
                                ),
                              ),
                            ),
                            onEditLine: canEdit
                                ? (item) =>
                                      _editLine(context, store, expense, item)
                                : null,
                          )
                        else
                          const SectionCard(
                            child: Text(
                              'Receipt amounts are not available for this '
                              'employee.',
                            ),
                          ),
                        if (canReview) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => _review(
                                  context,
                                  store,
                                  expense,
                                  ExpenseApprovalStatus.declined,
                                ),
                                child: const Text('Do not approve'),
                              ),
                              FilledButton.icon(
                                onPressed: () => _review(
                                  context,
                                  store,
                                  expense,
                                  ExpenseApprovalStatus.approved,
                                ),
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Approve expense'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    PrototypeOperationsStore store,
    ExpenseRecord expense,
  ) async {
    final recordIsOwn = permissions.owns(
      paidByEmployeeId: expense.paidByEmployeeId,
    );
    if (!permissions.canViewAmounts ||
        !permissions.canEditRecord(isOwn: recordIsOwn)) {
      return;
    }
    final editorConfirms =
        LocalDraftScope.maybeOf(context) != null &&
        ExpenseUiScope.maybeOf(context) != null;
    final result = await Navigator.of(context).push<ExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ExpenseEditorScreen(
          expenseDate: expense.resolvedDate ?? dashboardToday,
          initialCategory: expense.category,
          initialReceiptType: expense.receiptType,
          existing: expense,
          permissions: permissions,
          existingRecordIsOwn: recordIsOwn,
        ),
      ),
    );
    if (!context.mounted) return;
    if (editorConfirms) return;
    var draft = result;
    while (context.mounted && draft != null) {
      if (!context.mounted) return;
      final auditNote = expense.receiptImageCount > 0
          ? await showExpenseCorrectionReasonDialog(
              context,
              resetsApproval:
                  expense.approvalStatus != ExpenseApprovalStatus.notRequired,
            )
          : null;
      if (expense.receiptImageCount > 0 && auditNote == null) return;
      final saved = await store.updateExpense(draft, auditNote: auditNote);
      if (!context.mounted || saved != null) return;
      final keepEditing = await showExpenseSaveFailure(context);
      if (!context.mounted || !keepEditing) return;
      draft = await Navigator.of(context).push<ExpenseRecord>(
        MaterialPageRoute(
          builder: (_) => ExpenseEditorScreen(
            expenseDate: draft!.resolvedDate ?? dashboardToday,
            initialCategory: draft.category,
            initialReceiptType: draft.receiptType,
            existing: draft,
            permissions: permissions,
            existingRecordIsOwn: recordIsOwn,
          ),
        ),
      );
    }
  }

  Future<void> _review(
    BuildContext context,
    PrototypeOperationsStore store,
    ExpenseRecord expense,
    ExpenseApprovalStatus status,
  ) async {
    if (!permissions.canReviewCompanyExpenses) return;
    final saved = await store.updateExpense(
      expense.copyWith(approvalStatus: status),
    );
    if (!context.mounted) return;
    if (saved != null) {
      Navigator.pop(context);
      return;
    }
    await showExpenseSaveFailure(context);
  }

  Future<void> _remove(
    BuildContext context,
    PrototypeOperationsStore store,
    ExpenseRecord expense,
  ) async {
    final isOwn = permissions.owns(paidByEmployeeId: expense.paidByEmployeeId);
    if (!permissions.canViewAmounts ||
        !permissions.canRemoveRecord(isOwn: isOwn)) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this expense?'),
        content: const Text(
          'It will stop counting in daily totals, but it will not be '
          'permanently erased. An authorized user can restore it from the '
          'Expenses screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep expense'),
          ),
          FilledButton(
            key: const ValueKey('confirm-remove-expense-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Move to removed'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final removed = await store.softDeleteExpense(expense.id);
    if (!context.mounted) return;
    if (!removed) {
      await showExpenseActionFailure(
        context,
        title: 'Expense not removed',
        fallbackMessage: 'The expense could not be removed. Try again.',
      );
      return;
    }
    navigator.pop();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Expense removed.'),
        action: permissions.canRestoreRecord(isOwn: isOwn)
            ? SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  final restored = await store.restoreExpense(expense.id);
                  if (restored == null) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'The expense could not be restored. Try again from '
                          'Removed expenses.',
                        ),
                      ),
                    );
                  }
                },
              )
            : null,
      ),
    );
  }

  Future<void> _editLine(
    BuildContext context,
    PrototypeOperationsStore store,
    ExpenseRecord expense,
    ExpenseLineItem item,
  ) async {
    final isOwn = permissions.owns(paidByEmployeeId: expense.paidByEmployeeId);
    if (!permissions.canViewAmounts ||
        !permissions.canEditRecord(isOwn: isOwn)) {
      return;
    }
    if (LocalDraftScope.maybeOf(context) != null &&
        ExpenseUiScope.maybeOf(context) != null) {
      await Navigator.of(context).push<ExpenseRecord>(
        MaterialPageRoute(
          builder: (_) => ExpenseEditorScreen(
            expenseDate: expense.resolvedDate ?? dashboardToday,
            existing: expense,
            initialLineId: item.id,
            permissions: permissions,
            existingRecordIsOwn: isOwn,
          ),
        ),
      );
      return;
    }
    final updated = await showExpenseLineItemEditor(
      context,
      initial: item,
      defaultCategory: item.category,
    );
    if (!context.mounted || updated == null) return;
    final lines = [...expense.lineItems];
    final index = lines.indexWhere((candidate) => candidate.id == item.id);
    if (index < 0) return;
    lines[index] = updated;
    final subtotal = lines.fold<double>(0, (sum, line) => sum + line.total);
    final auditNote = expense.receiptImageCount > 0
        ? await showExpenseCorrectionReasonDialog(
            context,
            resetsApproval:
                expense.approvalStatus != ExpenseApprovalStatus.notRequired,
          )
        : null;
    if (expense.receiptImageCount > 0 && auditNote == null) return;
    final saved = await store.updateExpense(
      expense.copyWith(
        lineItems: List.unmodifiable(lines),
        receiptSubtotal: subtotal,
        amount: subtotal + expense.salesTax,
      ),
      auditNote: auditNote,
    );
    if (context.mounted && saved == null) {
      await showExpenseSaveFailure(context);
    }
  }
}

enum _ExpenseDetailAction { remove }

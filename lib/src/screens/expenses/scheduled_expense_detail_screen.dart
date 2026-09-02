import 'package:flutter/material.dart';

import '../../data/expense_prototype_store.dart';
import '../../data/expenses/expense_ui_repository_controller.dart';
import '../../data/expenses/recurring_expense_payment_coordinator.dart';
import '../../data/expenses/recurring_expense_ui_controller.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import 'expense_detail_screen.dart';
import 'expense_models.dart';
import 'expense_permissions.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';
import 'scheduled_expense_editor_screen.dart';
import 'scheduled_expense_feedback.dart';
import 'scheduled_expense_occurrence_editor_screen.dart';
import 'scheduled_expense_payment_dialog.dart';

class ScheduledExpenseDetailScreen extends StatelessWidget {
  const ScheduledExpenseDetailScreen({
    required this.recordId,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final String recordId;
  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) {
    if (!permissions.canView || !permissions.canManageScheduledExpenses) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'You do not have permission to manage this planned expense.',
            ),
          ),
        ),
      );
    }
    final scope = OperationalScope.of(context);
    final module = PrototypeOperationsScope.of(context).expenseStore;
    final controller = RecurringExpenseUiScope.maybeOf(context);
    final record =
        controller?.recordById(recordId) ??
        module.scheduledExpenses
            .where((item) => item.id == recordId)
            .firstOrNull;
    if (record == null) {
      return const _ScheduledExpenseUnavailable();
    }
    final occurrence =
        controller?.currentOccurrenceFor(recordId) ??
        module.currentOccurrenceFor(recordId);
    final history =
        (controller?.occurrencesFor(recordId) ??
                module.occurrencesFor(recordId))
            .where((item) => !item.isOpen)
            .toList();
    return Scaffold(
      key: const ValueKey('scheduled-expense-detail-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
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
                          workspaceLabel: 'Upcoming expense',
                          showBackButton: true,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          record.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        _ScheduleSummary(
                          record: record,
                          occurrence: occurrence,
                        ),
                        const SizedBox(height: 12),
                        _ScheduleActions(
                          record: record,
                          occurrence: occurrence,
                          module: module,
                          controller: controller,
                          permissions: permissions,
                        ),
                        const SizedBox(height: 14),
                        _PaymentHistory(
                          history: history,
                          permissions: permissions,
                        ),
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
}

class _ScheduleSummary extends StatelessWidget {
  const _ScheduleSummary({required this.record, required this.occurrence});

  final ScheduledExpenseRecord record;
  final ScheduledExpenseOccurrence? occurrence;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScheduleDetail('Usual amount', expenseMoney(record.amount)),
        _ScheduleDetail(
          'Due',
          occurrence == null
              ? 'No future payment scheduled'
              : operationalShortDateLabel(context, occurrence!.dueOn),
        ),
        _ScheduleDetail('Repeats', record.kind.label),
        _ScheduleDetail('Category', record.category.label),
        _ScheduleDetail('Status', record.state.label),
        _ScheduleDetail('Amount handling', record.amountKind.label),
        _ScheduleDetail(
          'Reminders',
          record.reminderDaysBefore.isEmpty
              ? 'None'
              : record.reminderDaysBefore
                    .map((day) => '$day day${day == 1 ? '' : 's'} before')
                    .join(', '),
        ),
        _ScheduleDetail(
          'This payment',
          occurrence == null
              ? 'No open payment'
              : occurrence!.isOverdueOn(DateTime.now())
              ? 'Overdue'
              : 'Not marked paid',
        ),
        _ScheduleDetail(
          'Receipt',
          record.receiptRequired
              ? 'Required for each paid expense'
              : 'Optional',
        ),
      ],
    ),
  );
}

class _ScheduleActions extends StatelessWidget {
  const _ScheduleActions({
    required this.record,
    required this.occurrence,
    required this.module,
    required this.controller,
    required this.permissions,
  });

  final ScheduledExpenseRecord record;
  final ScheduledExpenseOccurrence? occurrence;
  final ExpensePrototypeStore module;
  final RecurringExpenseUiController? controller;
  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.end,
    children: [
      if (occurrence != null && record.isActive)
        OutlinedButton.icon(
          key: const ValueKey('edit-scheduled-expense-occurrence'),
          onPressed: () => _editOccurrence(context),
          icon: const Icon(Icons.event_note_outlined),
          label: const Text('Edit this payment'),
        ),
      OutlinedButton.icon(
        onPressed: () => _editFuture(context),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit this and future'),
      ),
      if (record.state != ScheduledExpenseState.ended)
        OutlinedButton.icon(
          onPressed: _isPending ? null : () => _toggleState(context),
          icon: Icon(
            record.state == ScheduledExpenseState.paused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
          ),
          label: Text(
            record.state == ScheduledExpenseState.paused ? 'Resume' : 'Pause',
          ),
        ),
      if (occurrence != null && record.isActive) ...[
        OutlinedButton.icon(
          onPressed: _isPending ? null : () => _skip(context),
          icon: const Icon(Icons.skip_next_rounded),
          label: const Text('Skip this payment'),
        ),
        FilledButton.icon(
          key: const ValueKey('mark-scheduled-expense-paid'),
          onPressed: permissions.canCreate && !_isPending
              ? () => _markPaid(context)
              : null,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Mark paid'),
        ),
      ],
    ],
  );

  bool get _isPending =>
      controller?.isPending(record.id) == true ||
      (occurrence != null && controller?.isPending(occurrence!.id) == true);

  Future<void> _editFuture(BuildContext context) async {
    final edited = await Navigator.of(context).push<ScheduledExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ScheduledExpenseEditorScreen(
          initial: record,
          permissions: permissions,
        ),
      ),
    );
    if (edited == null || !context.mounted) return;
    final durable = controller;
    if (durable == null) {
      module.updateScheduledExpense(edited);
      return;
    }
    final saved = await durable.update(edited);
    if (context.mounted && saved == null) {
      await showScheduledExpenseFailure(context);
    }
  }

  Future<void> _editOccurrence(BuildContext context) async {
    final edited = await Navigator.of(context).push<ScheduledExpenseOccurrence>(
      MaterialPageRoute(
        builder: (_) => ScheduledExpenseOccurrenceEditorScreen(
          occurrence: occurrence!,
          permissions: permissions,
        ),
      ),
    );
    if (edited == null) return;
    final durable = controller;
    if (durable == null) {
      module.updateScheduledExpenseOccurrence(
        templateId: record.id,
        occurrenceId: occurrence!.id,
        dueOn: edited.dueOn,
        expectedAmount: edited.expectedAmount,
      );
      return;
    }
    final saved = await durable.updateOccurrence(edited);
    if (context.mounted && saved == null) {
      await showScheduledExpenseFailure(context);
    }
  }

  Future<void> _toggleState(BuildContext context) async {
    final next = record.state == ScheduledExpenseState.paused
        ? ScheduledExpenseState.active
        : ScheduledExpenseState.paused;
    final durable = controller;
    if (durable == null) {
      module.setScheduledExpenseState(record.id, next);
      return;
    }
    if (!await durable.setState(record.id, next) && context.mounted) {
      await showScheduledExpenseFailure(context);
    }
  }

  Future<void> _skip(BuildContext context) async {
    final current = occurrence;
    if (current == null) return;
    final durable = controller;
    if (durable == null) {
      module.skipScheduledExpense(
        templateId: record.id,
        occurrenceId: current.id,
      );
      return;
    }
    if (!await durable.skip(record.id, current.id) && context.mounted) {
      await showScheduledExpenseFailure(context);
    }
  }

  Future<void> _markPaid(BuildContext context) async {
    if (!permissions.canCreate) return;
    double? actualAmount;
    if (record.amountKind == ScheduledExpenseAmountKind.enterWhenPaid) {
      actualAmount = await showScheduledExpensePaymentAmountDialog(
        context,
        expectedAmount: occurrence!.expectedAmount,
      );
      if (actualAmount == null || !context.mounted) return;
    }
    final paidOn = DateTime.now();
    final durable = controller;
    ExpenseRecord? expense;
    if (durable == null) {
      expense = module.markScheduledExpensePaid(
        templateId: record.id,
        occurrenceId: occurrence!.id,
        paidOn: paidOn,
        actualAmount: actualAmount,
      );
    } else {
      final expenseController = ExpenseUiScope.maybeOf(context);
      if (expenseController == null) {
        await showScheduledExpenseFailure(
          context,
          message: 'Expense storage is not ready. The payment was not changed.',
        );
        return;
      }
      final result =
          await RecurringExpensePaymentCoordinator(
            expenses: expenseController,
            recurringExpenses: durable,
          ).markPaid(
            template: record,
            occurrence: occurrence!,
            actualAmount: actualAmount ?? occurrence!.expectedAmount,
            paidOn: paidOn,
          );
      if (!result.succeeded) {
        if (context.mounted) {
          await showScheduledExpenseFailure(
            context,
            message:
                result.message ??
                'The payment could not be recorded. Try again.',
          );
        }
        return;
      }
      expense = result.expense;
    }
    final savedExpense = expense;
    if (savedExpense == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseDetailScreen(
          expenseId: savedExpense.id,
          permissions: permissions,
        ),
      ),
    );
  }
}

class _ScheduledExpenseUnavailable extends StatelessWidget {
  const _ScheduledExpenseUnavailable();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'This planned expense is missing, no longer available, or '
              'outside your current access.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );
}

class _PaymentHistory extends StatelessWidget {
  const _PaymentHistory({required this.history, required this.permissions});

  final List<ScheduledExpenseOccurrence> history;
  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Payment history', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        if (history.isEmpty)
          const Text('No payments have been recorded yet.')
        else
          for (final item in history)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(operationalShortDateLabel(context, item.dueOn)),
              subtitle: Text(item.status.label),
              trailing: Text(
                expenseMoney(item.actualAmount ?? item.expectedAmount),
              ),
              onTap: item.expenseId == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ExpenseDetailScreen(
                          expenseId: item.expenseId!,
                          permissions: permissions,
                        ),
                      ),
                    ),
            ),
      ],
    ),
  );
}

class _ScheduleDetail extends StatelessWidget {
  const _ScheduleDetail(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 112, child: Text(label)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

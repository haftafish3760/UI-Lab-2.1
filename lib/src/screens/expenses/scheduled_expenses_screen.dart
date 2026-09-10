import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/expenses/recurring_expense_ui_controller.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import 'expense_models.dart';
import 'expense_permissions.dart';
import 'device_reminder_status.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';
import 'recurring_expense_repository_status.dart';
import 'scheduled_expense_detail_screen.dart';
import 'scheduled_expense_editor_screen.dart';

class ScheduledExpensesScreen extends StatelessWidget {
  const ScheduledExpensesScreen({
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) {
    if (!permissions.canView || !permissions.canManageScheduledExpenses) {
      return const Scaffold(
        key: ValueKey('scheduled-expenses-screen'),
        body: SafeArea(
          child: Center(
            child: Text(
              'You do not have permission to manage planned expenses.',
            ),
          ),
        ),
      );
    }
    final scope = OperationalScope.of(context);
    final controller = RecurringExpenseUiScope.maybeOf(context);
    final records = [
      ...(controller?.records ??
          PrototypeOperationsScope.of(context).expenseStore.scheduledExpenses),
    ]..sort((a, b) => a.nextDueOn.compareTo(b.nextDueOn));
    final showStatus =
        controller != null &&
        (controller.isLoading ||
            controller.phase == RecurringExpenseUiPhase.failed ||
            controller.showRecoveryNotice);
    final firstLoadUnavailable =
        records.isEmpty &&
        controller != null &&
        (controller.isLoading ||
            controller.phase == RecurringExpenseUiPhase.failed);
    return Scaffold(
      key: const ValueKey('scheduled-expenses-screen'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add upcoming expense'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return ListView(
              padding: insets.copyWith(top: 10, bottom: 96),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExpensesScopeHeader(
                          view: scope.view,
                          selectedEmployeeId: scope.selectedEmployeeId,
                          onViewChanged: scope.setView,
                          onEmployeeChanged: scope.selectEmployee,
                          onSettings: () => _openSettings(context),
                          showSettings: permissions.canConfigureDisplay,
                          workspaceLabel: 'Upcoming expenses',
                          showBackButton: true,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Upcoming and recurring expenses',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Due dates are shown in chronological order.',
                        ),
                        const SizedBox(height: 14),
                        if (showStatus) ...[
                          const RecurringExpenseRepositoryStatus(),
                          const SizedBox(height: 10),
                        ],
                        if (records.any(
                          (record) =>
                              record.pushReminder || record.soundReminder,
                        )) ...[
                          DeviceReminderStatus(
                            requestSound: records.any(
                              (record) => record.soundReminder,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (records.isEmpty && !firstLoadUnavailable)
                          SectionCard(
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'No upcoming expenses are set up.',
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: () => _add(context),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add'),
                                ),
                              ],
                            ),
                          )
                        else
                          for (
                            var index = 0;
                            index < records.length;
                            index++
                          ) ...[
                            ScheduledExpenseCard(
                              record: records[index],
                              onTap: () => _open(context, records[index]),
                            ),
                            if (index != records.length - 1)
                              const SizedBox(height: 10),
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

  Future<void> _add(BuildContext context) async {
    if (!permissions.canManageScheduledExpenses) return;
    final result = await Navigator.of(context).push<ScheduledExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ScheduledExpenseEditorScreen(
          permissions: permissions,
          onConfirm: RecurringExpenseUiScope.maybeOf(context)?.create,
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final controller = RecurringExpenseUiScope.maybeOf(context);
    if (controller == null) {
      PrototypeOperationsScope.of(
        context,
      ).expenseStore.addScheduledExpense(result);
      return;
    }
  }

  void _open(BuildContext context, ScheduledExpenseRecord record) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ScheduledExpenseDetailScreen(
            recordId: record.id,
            permissions: permissions,
          ),
        ),
      );

  void _openSettings(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const ExpensesSettingsScreen()),
  );
}

class ScheduledExpenseCard extends StatelessWidget {
  const ScheduledExpenseCard({
    required this.record,
    required this.onTap,
    super.key,
  });

  final ScheduledExpenseRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: ValueKey('scheduled-expense-${record.id}'),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outline),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 62),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 7, 8, 7),
            child: Row(
              children: [
                Icon(record.category.icon, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${record.kind.label} · Due ${operationalShortDateLabel(context, record.nextDueOn)}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      expenseMoney(record.amount),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Icon(switch (record.state) {
                      ScheduledExpenseState.active =>
                        Icons.chevron_right_rounded,
                      ScheduledExpenseState.paused =>
                        Icons.pause_circle_outline_rounded,
                      ScheduledExpenseState.ended => Icons.stop_circle_outlined,
                    }, size: 19),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

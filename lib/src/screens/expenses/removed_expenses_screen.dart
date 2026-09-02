import 'package:flutter/material.dart';

import '../../data/expenses/expense_ui_repository_controller.dart';
import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../theme/app_theme.dart';
import 'expense_models.dart';
import 'expense_permissions.dart';
import 'expense_save_feedback.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';

class RemovedExpensesScreen extends StatelessWidget {
  const RemovedExpensesScreen({required this.permissions, super.key});

  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final store = PrototypeOperationsScope.of(context);
    final records = _visibleRecords(scope, store.deletedExpenses);
    return Scaffold(
      key: const ValueKey('removed-expenses-screen'),
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
                          workspaceLabel: 'Removed expenses',
                          showBackButton: true,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Removed expenses',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'These records no longer count in daily totals. '
                          'Restore one to return it to Expenses.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (records.isEmpty)
                          const _EmptyRemovedExpenses()
                        else
                          for (
                            var index = 0;
                            index < records.length;
                            index++
                          ) ...[
                            _RemovedExpenseRow(
                              record: records[index],
                              showAmount: permissions.canViewAmounts,
                              canRestore: permissions.canRestoreRecord(
                                isOwn: permissions.owns(
                                  paidByEmployeeId:
                                      records[index].paidByEmployeeId,
                                ),
                              ),
                              pending:
                                  ExpenseUiScope.maybeOf(
                                    context,
                                  )?.isPending(records[index].id) ??
                                  false,
                              onRestore: () =>
                                  _restore(context, store, records[index]),
                            ),
                            if (index != records.length - 1)
                              const SizedBox(height: 8),
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

  List<ExpenseRecord> _visibleRecords(
    OperationalScopeController scope,
    Iterable<ExpenseRecord> records,
  ) {
    final selectedEmployeeId = scope.selectedEmployeeId;
    return records
        .where((record) {
          final isOwn = permissions.owns(
            paidByEmployeeId: record.paidByEmployeeId,
          );
          if (!permissions.canRestoreRecord(isOwn: isOwn)) return false;
          if (scope.view == AppViewMode.technician) return isOwn;
          return selectedEmployeeId == null ||
              record.paidByEmployeeId == selectedEmployeeId;
        })
        .toList(growable: false);
  }

  Future<void> _restore(
    BuildContext context,
    PrototypeOperationsStore store,
    ExpenseRecord record,
  ) async {
    final isOwn = permissions.owns(paidByEmployeeId: record.paidByEmployeeId);
    if (!permissions.canRestoreRecord(isOwn: isOwn)) return;
    final restored = await store.restoreExpense(record.id);
    if (context.mounted && restored == null) {
      await showExpenseActionFailure(
        context,
        title: 'Expense not restored',
        fallbackMessage: 'The expense could not be restored. Try again.',
      );
    }
  }
}

class _RemovedExpenseRow extends StatelessWidget {
  const _RemovedExpenseRow({
    required this.record,
    required this.showAmount,
    required this.canRestore,
    required this.pending,
    required this.onRestore,
  });

  final ExpenseRecord record;
  final bool showAmount;
  final bool canRestore;
  final bool pending;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = record.resolvedDate;
    return Material(
      key: ValueKey('removed-expense-${record.id}'),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outline),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 8, 5),
          child: Row(
            children: [
              Icon(record.category.icon, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: record.vendor,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text:
                            '\n${record.category.label}'
                            '${date == null ? '' : ' · ${operationalShortDateLabel(context, date)}'}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showAmount) ...[
                const SizedBox(width: 6),
                Text(
                  expenseMoney(record.amount),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              OutlinedButton(
                key: ValueKey('restore-expense-${record.id}'),
                onPressed: canRestore && !pending ? onRestore : null,
                child: Text(pending ? 'Restoring…' : 'Restore'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRemovedExpenses extends StatelessWidget {
  const _EmptyRemovedExpenses();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('There are no removed expenses in this view.'),
    ),
  );
}

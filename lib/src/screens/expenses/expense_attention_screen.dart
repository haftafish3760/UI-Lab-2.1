import 'package:flutter/material.dart';

import '../../data/operational_attention.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/operational_attention_panel.dart';
import '../dashboard/dashboard_models.dart';
import 'expense_detail_screen.dart';
import 'expense_permissions.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';

class ExpenseAttentionScreen extends StatelessWidget {
  const ExpenseAttentionScreen({
    required this.items,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final List<OperationalAttentionItem> items;
  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) {
    if (!permissions.canView || !permissions.canViewAmounts) {
      return const Scaffold(
        key: ValueKey('expense-attention-screen'),
        body: SafeArea(
          child: Center(
            child: Text(
              'You do not have permission to view expense attention.',
            ),
          ),
        ),
      );
    }
    final scope = OperationalScope.of(context);
    return Scaffold(
      key: const ValueKey('expense-attention-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return ListView(
              padding: insets.copyWith(top: 10, bottom: 32),
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
                          onSettings: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ExpensesSettingsScreen(),
                            ),
                          ),
                          showSettings: permissions.canConfigureDisplay,
                          workspaceLabel: 'Expense attention',
                          showBackButton: true,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          operationalDateLabel(context, dashboardToday),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items.isEmpty
                              ? 'Nothing needs attention.'
                              : '${items.length} ${items.length == 1 ? 'item needs' : 'items need'} attention',
                        ),
                        const SizedBox(height: 14),
                        OperationalAttentionList(
                          items: items,
                          rowKeyFor: (item) =>
                              ValueKey('expense-record-${item.sourceId}'),
                          onOpen: (item) => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ExpenseDetailScreen(
                                expenseId: item.sourceId,
                                permissions: permissions,
                              ),
                            ),
                          ),
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

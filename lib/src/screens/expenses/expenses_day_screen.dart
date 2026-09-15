part of 'expenses_screen.dart';

class ExpensesDayScreen extends StatefulWidget {
  const ExpensesDayScreen({
    required this.day,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final DateTime day;
  final ExpensePermissions permissions;

  @override
  State<ExpensesDayScreen> createState() => _ExpensesDayScreenState();
}

class _ExpensesDayScreenState extends State<ExpensesDayScreen> {
  var _preferences = const ExpenseDisplayPreferences.defaults();

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canView) {
      return const Scaffold(
        key: ValueKey('expenses-day-screen'),
        body: SafeArea(
          child: Center(
            child: Text('You do not have permission to view expenses.'),
          ),
        ),
      );
    }
    final scope = OperationalScope.of(context);
    final expenses = PrototypeOperationsScope.of(
      context,
    ).expenses.where((item) => _visibleForScope(item, scope)).toList();
    return Scaffold(
      key: const ValueKey('expenses-day-screen'),
      floatingActionButton: widget.permissions.canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _recordExpense(context),
              icon: const Icon(Icons.add_card_outlined),
              label: const Text('Add expense'),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final layout = AppLayoutEngine.detailWorkspaceFor(
              constraints.maxWidth - insets.horizontal,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 92),
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
                          showBackButton: true,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                          onSettings: _openSettings,
                          showSettings: widget.permissions.canConfigureDisplay,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          operationalDateLabel(context, widget.day),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scope.view == AppViewMode.admin
                              ? scope.selectedEmployeeId == null
                                    ? 'Company expense records for this day'
                                    : 'Employee expense records for this day'
                              : 'My expense records for this day',
                        ),
                        const SizedBox(height: 14),
                        if (widget.permissions.canViewAmounts) ...[
                          _ExpenseSummary(expenses: expenses),
                          const SizedBox(height: 16),
                        ],
                        _ExpenseList(
                          title: 'Entries',
                          expenses: expenses,
                          showJobLinks: _preferences.showJobLinks,
                          showAmounts: widget.permissions.canViewAmounts,
                          onOpen: (expense) => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ExpenseDetailScreen(
                                expenseId: expense.id,
                                permissions: widget.permissions,
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

  bool _visibleForScope(ExpenseRecord item, OperationalScopeController scope) {
    final date = item.resolvedDate;
    if (date == null || !sameDashboardDay(date, widget.day)) return false;
    final employeeId = scope.view == AppViewMode.technician
        ? scope.selectedEmployeeId ?? widget.permissions.actorEmployeeId
        : scope.selectedEmployeeId;
    return employeeId == null || item.paidByEmployeeId == employeeId;
  }

  Future<void> _recordExpense(BuildContext context) => openExpenseEntryFlow(
    context,
    expenseDate: widget.day,
    permissions: widget.permissions,
    onConfirm: (record) async =>
        PrototypeOperationsScope.of(context).addExpense(record),
  );

  Future<void> _openSettings() async {
    if (!widget.permissions.canConfigureDisplay) return;
    final result = await Navigator.of(context).push<ExpenseDisplayPreferences>(
      MaterialPageRoute(
        builder: (_) => ExpensesSettingsScreen(initial: _preferences),
      ),
    );
    if (mounted && result != null) setState(() => _preferences = result);
  }
}

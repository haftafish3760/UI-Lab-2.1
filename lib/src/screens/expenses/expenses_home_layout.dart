part of 'expenses_screen.dart';

extension _ExpensesHomeLayout on _ExpensesScreenState {
  Widget _buildExpenseHome(BuildContext context) {
    final permissions = _permissions;
    if (!permissions.canView) {
      return const Scaffold(
        key: ValueKey('expenses-module-screen'),
        body: SafeArea(
          child: Center(
            child: Text('You do not have permission to view expenses.'),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
        final detailLayout = AppLayoutEngine.detailWorkspaceFor(
          constraints.maxWidth - insets.horizontal,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final layout = OperationsWorkspaceLayout(
          columns: detailLayout.columns,
          laneWidth: detailLayout.columnWidth,
          gap: detailLayout.gap,
          workspaceWidth: detailLayout.workspaceWidth,
        );
        final attentionQuery = _attentionQuery();
        final attentionCenter = PrototypeOperationsScope.of(
          context,
        ).attentionCenter;
        final attention = permissions.canViewAmounts
            ? attentionCenter.itemsFor(attentionQuery)
            : <OperationalAttentionItem>[];
        final recurring = RecurringExpenseUiScope.maybeOf(context);
        final records = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (attention.isNotEmpty &&
                attentionCenter.shouldShow(attentionQuery, attention)) ...[
              OperationalAttentionPanel(
                key: const ValueKey('expenses-needs-attention'),
                items: attention,
                rowKeyFor: (item) =>
                    ValueKey('expense-attention-${item.sourceId}'),
                onOpen: _openAttentionItem,
                onOpenAll: () => _openAttention(attention),
                onDismiss: () =>
                    attentionCenter.dismiss(attentionQuery, attention),
              ),
              const SizedBox(height: 12),
            ],
            if (permissions.canAttachReceipt && _visibleDrafts.isNotEmpty) ...[
              _ReceiptDraftSummary(
                drafts: _visibleDrafts,
                onOpen: _openReceiptDrafts,
              ),
              const SizedBox(height: 12),
            ],
            _ExpenseEntriesSection(
              expenses: _visibleExpenses,
              showJobLinks: _preferences.showJobLinks,
              showAmounts: permissions.canViewAmounts,
              removedExpenseCount: _visibleDeletedExpenses.length,
              onOpen: _openExpense,
              onOpenRemoved: _openRemovedExpenses,
            ),
          ],
        );
        final calendar = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Expense calendar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose a day to view its expenses or add an expense for that date.',
            ),
            const SizedBox(height: 10),
            _ExpensesCalendar(
              view: _view,
              maximumWidth: AppLayoutEngine.calendarMaximum,
              expenses: _scopeExpenses,
              selectedDate: _selectedDate,
              selectedEmployeeId: _selectedEmployeeId,
              onDaySelected: _openExpenseDay,
            ),
          ],
        );
        final supporting = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_view == AppViewMode.admin && _selectedEmployeeId != null) ...[
              OutlinedButton.icon(
                onPressed: () => _changeEmployee(null),
                icon: const Icon(Icons.business_outlined),
                label: const Text('Company overview'),
              ),
              const SizedBox(height: 12),
            ],
            if (permissions.canManageScheduledExpenses) ...[
              _ScheduledExpenseShortcuts(
                records: _visibleScheduledExpenses,
                onOpen: _openScheduledExpenses,
                onAdd: _addScheduledExpense,
              ),
              const SizedBox(height: 12),
            ],
            if (_preferences.categoryMode != ExpenseCategoryDisplayMode.off)
              _ExpenseCategoriesSection(
                mode: _preferences.categoryMode,
                customCategories: _preferences.customCategories,
                records: _visibleExpenses,
                showAmounts: permissions.canViewAmounts,
                onOpen: _openCategory,
              ),
          ],
        );
        return Scaffold(
          key: const ValueKey('expenses-module-screen'),
          floatingActionButton:
              permissions.canCreate || permissions.canAttachReceipt
              ? FloatingActionButton.extended(
                  key: const ValueKey('expenses-add-fab'),
                  onPressed: permissions.canCreate
                      ? () => _recordExpense()
                      : _openReceiptIntake,
                  icon: const Icon(Icons.add),
                  label: Text(
                    permissions.canCreate ? 'Add expense' : 'Add receipt',
                  ),
                )
              : null,
          body: SafeArea(
            child: ListView(
              padding: insets.copyWith(top: 10, bottom: 112),
              children: [
                OperationsWorkspaceFrame(
                  layout: layout,
                  primaryContent: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExpensesScopeHeader(
                        view: _view,
                        selectedEmployeeId: _selectedEmployeeId,
                        onViewChanged: _changeView,
                        onEmployeeChanged: _changeEmployee,
                        onSettings: _openSettings,
                        showSettings: permissions.canConfigureDisplay,
                        showEmployeeStrip: false,
                      ),
                      const SizedBox(height: 14),
                      _ExpensesHeading(
                        view: _view,
                        selectedDate: _selectedDate,
                      ),
                      if (_view == AppViewMode.admin) ...[
                        const SizedBox(height: 6),
                        Text(
                          _selectedEmployeeId == null
                              ? 'Company overview'
                              : 'Expenses paid by ${dashboardEmployeeById(_selectedEmployeeId!).name}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                      if (permissions.canViewAmounts) ...[
                        const SizedBox(height: 12),
                        ExpenseSpendingSummary(
                          periods: const ['Day', 'Week'],
                          records: _scopeExpenses,
                          date: _selectedDate,
                          firstWeekday: _preferences.weekStartsOn,
                          onOpen: _openSpendingPeriod,
                        ),
                      ],
                      if (recurring != null &&
                          (recurring.isLoading ||
                              recurring.phase ==
                                  RecurringExpenseUiPhase.failed ||
                              recurring.showRecoveryNotice))
                        const RecurringExpenseRepositoryStatus(),
                      const SizedBox(height: 16),
                      KeyedSubtree(
                        key: ValueKey(
                          'expenses-${layout.columns}-column-layout',
                        ),
                        child: OperationsLaneGrid(
                          layout: layout,
                          children: [
                            records,
                            if (layout.columns == 3)
                              calendar
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  calendar,
                                  const SizedBox(height: 16),
                                  supporting,
                                ],
                              ),
                            if (layout.columns == 3) supporting,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

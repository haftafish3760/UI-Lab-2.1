part of 'expenses_screen.dart';

class _ExpenseEntriesSection extends StatefulWidget {
  const _ExpenseEntriesSection({
    required this.expenses,
    required this.showJobLinks,
    required this.showAmounts,
    required this.removedExpenseCount,
    required this.onOpen,
    required this.onOpenRemoved,
  });

  final List<ExpenseRecord> expenses;
  final bool showJobLinks;
  final bool showAmounts;
  final int removedExpenseCount;
  final ValueChanged<ExpenseRecord> onOpen;
  final VoidCallback onOpenRemoved;

  @override
  State<_ExpenseEntriesSection> createState() => _ExpenseEntriesSectionState();
}

class _ExpenseEntriesSectionState extends State<_ExpenseEntriesSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) => RecordedEntriesSection(
    key: const ValueKey('expense-entries-section'),
    builder: _buildEntries,
  );

  Widget _buildEntries(BuildContext context) {
    final visible = _expanded
        ? widget.expenses.length
        : widget.expenses.length.clamp(0, 3);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OperationalSectionHeading(
          headerKey: const ValueKey('expense-entries-header'),
          background: OperationalCardPalette.entries.start,
          foreground: OperationalCardPalette.entries.foreground,
          child: Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: colors.onSurface),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Today's entries",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (widget.expenses.length > 3)
                TextButton(
                  key: const ValueKey('expense-entries-expand-button'),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded
                            ? 'Show less'
                            : 'Show all ${widget.expenses.length}',
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (widget.expenses.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No expenses recorded for this day.'),
          )
        else
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$visible of ${widget.expenses.length} expenses',
                  key: const ValueKey('expense-visible-count'),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < visible; index++) ...[
                  ExpenseRecordCard(
                    expense: widget.expenses[index],
                    showJob: widget.showJobLinks,
                    showOwner: true,
                    showAmount: widget.showAmounts,
                    onTap: () => widget.onOpen(widget.expenses[index]),
                  ),
                  if (index != visible - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        if (widget.removedExpenseCount > 0)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 6),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: const ValueKey('open-removed-expenses-button'),
                onPressed: widget.onOpenRemoved,
                icon: const Icon(Icons.restore_from_trash_outlined),
                label: Text('Removed expenses (${widget.removedExpenseCount})'),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExpenseCategoriesSection extends StatelessWidget {
  const _ExpenseCategoriesSection({
    required this.mode,
    required this.customCategories,
    required this.records,
    required this.showAmounts,
    required this.onOpen,
  });

  final ExpenseCategoryDisplayMode mode;
  final List<ExpenseCategory> customCategories;
  final List<ExpenseRecord> records;
  final bool showAmounts;
  final ValueChanged<ExpenseCategory> onOpen;

  @override
  Widget build(BuildContext context) {
    final totals = <ExpenseCategory, double>{};
    for (final record in records) {
      totals.update(
        record.category,
        (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }
    final categories = switch (mode) {
      ExpenseCategoryDisplayMode.off => const <ExpenseCategory>[],
      ExpenseCategoryDisplayMode.custom => customCategories,
      ExpenseCategoryDisplayMode.topTen =>
        (totals.keys.toList()
          ..sort((a, b) => (totals[b] ?? 0).compareTo(totals[a] ?? 0))),
    };
    final visible = categories.take(10).toList();
    return SectionCard(
      key: const ValueKey('expense-categories-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Expense categories',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const Text('Choose categories in Expense settings.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 8.0;
                final width = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final category in visible)
                      SizedBox(
                        width: width,
                        child: _ExpenseCategoryTile(
                          category: category,
                          total: totals[category] ?? 0,
                          showAmount: showAmounts,
                          onTap: () => onOpen(category),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ExpenseCategoryTile extends StatelessWidget {
  const _ExpenseCategoryTile({
    required this.category,
    required this.total,
    required this.showAmount,
    required this.onTap,
  });

  final ExpenseCategory category;
  final double total;
  final bool showAmount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    key: ValueKey('expense-category-${category.name}'),
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            children: [
              Icon(category.icon, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (showAmount)
                      Text(
                        expenseMoney(total),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ExpensesCalendar extends StatelessWidget {
  const _ExpensesCalendar({
    required this.view,
    required this.maximumWidth,
    required this.expenses,
    required this.selectedDate,
    required this.selectedEmployeeId,
    required this.onDaySelected,
  });

  final AppViewMode view;
  final double maximumWidth;
  final List<ExpenseRecord> expenses;
  final DateTime selectedDate;
  final String? selectedEmployeeId;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) => WorkMonthCalendar(
    maximumWidth: maximumWidth,
    selectedDay: selectedDate,
    recordKind: CalendarRecordKind.expense,
    entryCountForDay: (day) => _visible(day).length,
    needsApprovalForDay: (day) => _visible(
      day,
    ).any((item) => item.approvalStatus == ExpenseApprovalStatus.pending),
    onDaySelected: onDaySelected,
  );

  Iterable<ExpenseRecord> _visible(DateTime day) => expenses.where((item) {
    final date = item.resolvedDate;
    if (date == null || !sameDashboardDay(date, day)) return false;
    if (view == AppViewMode.admin && selectedEmployeeId == null) return true;
    final owner = dashboardEmployeeById(selectedEmployeeId ?? 'alex').name;
    return item.owner == owner;
  });
}

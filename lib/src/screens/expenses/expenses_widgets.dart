part of 'expenses_screen.dart';

enum _ExpenseAction { expense, fuel, receipt }

Color _expenseModuleColor(BuildContext context) {
  final theme = Theme.of(context);
  final extension = theme.extension<AppModuleColors>();
  if (extension != null) return extension.expenses;
  return theme.brightness == Brightness.dark
      ? AppModuleColors.dark.expenses
      : AppModuleColors.light.expenses;
}

AppSemanticColors _expenseSemanticColors(BuildContext context) =>
    Theme.of(context).extension<AppSemanticColors>() ??
    (Theme.of(context).brightness == Brightness.dark
        ? AppSemanticColors.dark
        : AppSemanticColors.light);

class _ExpensesHeading extends StatelessWidget {
  const _ExpensesHeading({
    required this.view,
    required this.selectedDate,
    required this.dailyTotal,
    required this.showDailyTotal,
    required this.showWideActions,
    required this.onRecordExpense,
    required this.onRecordFuel,
    required this.onAttachReceipt,
  });

  final AppViewMode view;
  final DateTime selectedDate;
  final double dailyTotal;
  final bool showWideActions;
  final bool showDailyTotal;
  final VoidCallback? onRecordExpense;
  final VoidCallback? onRecordFuel;
  final VoidCallback? onAttachReceipt;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
      final colors = Theme.of(context).colorScheme;
      final module = _expenseModuleColor(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: constraints.maxWidth,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operationalDateLabel(
                        context,
                        selectedDate,
                        year: selectedDate.year != DateTime.now().year,
                      ),
                      key: const ValueKey('expenses-date-heading'),
                      style: TextStyle(
                        fontSize: type.pageTitle,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      view == AppViewMode.admin
                          ? 'Company expenses'
                          : 'My expenses',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (showDailyTotal)
                  DecoratedBox(
                    key: const ValueKey('daily-expense-total'),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        module.withValues(alpha: .16),
                        colors.surface,
                      ),
                      border: Border.all(
                        color: module.withValues(alpha: .72),
                        width: 1.25,
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Daily total',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            expenseMoney(dailyTotal),
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (showWideActions) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onRecordExpense != null)
                  FilledButton.icon(
                    onPressed: onRecordExpense,
                    icon: const Icon(Icons.add_card_outlined),
                    label: const Text('Record expense'),
                  ),
                if (onRecordFuel != null)
                  OutlinedButton.icon(
                    onPressed: onRecordFuel,
                    icon: const Icon(Icons.local_gas_station_outlined),
                    label: const Text('Add fuel'),
                  ),
                if (onAttachReceipt != null)
                  OutlinedButton.icon(
                    onPressed: onAttachReceipt,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Add receipt'),
                  ),
              ],
            ),
          ],
        ],
      );
    },
  );
}

class _ReceiptDraftSummary extends StatelessWidget {
  const _ReceiptDraftSummary({required this.drafts, required this.onOpen});

  final List<ExpenseReceiptDraft> drafts;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (drafts.isEmpty) return const SizedBox.shrink();
    final semantic = _expenseSemanticColors(context);
    return Material(
      key: const ValueKey('expense-receipt-drafts-summary'),
      color: semantic.draftSurface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: semantic.draft, width: 1.25),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        mouseCursor: SystemMouseCursors.click,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: semantic.draft),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Receipt drafts',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text('${drafts.length}'),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseLanes extends StatelessWidget {
  const _ExpenseLanes({
    required this.layout,
    required this.expenses,
    required this.selectedDate,
    required this.preferences,
    required this.scheduledExpenses,
    required this.showScheduled,
    required this.showAmounts,
    required this.removedExpenseCount,
    required this.onOpenScheduled,
    required this.onAddScheduled,
    required this.onOpenExpense,
    required this.onOpenCategory,
    required this.onOpenRemoved,
  });

  final OperationsWorkspaceLayout layout;
  final List<ExpenseRecord> expenses;
  final DateTime selectedDate;
  final ExpenseDisplayPreferences preferences;
  final List<ScheduledExpenseRecord> scheduledExpenses;
  final bool showScheduled;
  final bool showAmounts;
  final int removedExpenseCount;
  final VoidCallback onOpenScheduled;
  final VoidCallback onAddScheduled;
  final ValueChanged<ExpenseRecord> onOpenExpense;
  final ValueChanged<ExpenseCategory> onOpenCategory;
  final VoidCallback onOpenRemoved;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (showScheduled)
        _ScheduledExpenseShortcuts(
          records: scheduledExpenses,
          onOpen: onOpenScheduled,
          onAdd: onAddScheduled,
        ),
      _ExpenseEntriesSection(
        expenses: expenses,
        showJobLinks: preferences.showJobLinks,
        showAmounts: showAmounts,
        removedExpenseCount: removedExpenseCount,
        onOpen: onOpenExpense,
        onOpenRemoved: onOpenRemoved,
      ),
      if (preferences.categoryMode != ExpenseCategoryDisplayMode.off)
        _ExpenseCategoriesSection(
          mode: preferences.categoryMode,
          customCategories: preferences.customCategories,
          records: expenses,
          showAmounts: showAmounts,
          onOpen: onOpenCategory,
        ),
    ];
    return KeyedSubtree(
      key: ValueKey('expenses-${layout.columns}-column-layout'),
      child: OperationsLaneGrid(layout: layout, children: children),
    );
  }
}

class _ScheduledExpenseShortcuts extends StatelessWidget {
  const _ScheduledExpenseShortcuts({
    required this.records,
    required this.onOpen,
    required this.onAdd,
  });

  final List<ScheduledExpenseRecord> records;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final semantic = _expenseSemanticColors(context);
    final upcoming = records
        .where((item) => item.kind == ExpenseScheduleKind.oneTime)
        .length;
    final recurring = records
        .where((item) => item.kind == ExpenseScheduleKind.monthly)
        .length;
    return SectionCard(
      key: const ValueKey('planned-expenses-section'),
      backgroundColor: semantic.plannedSurface,
      borderColor: semantic.planned,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Planned expenses',
                  style: TextStyle(
                    color: semantic.planned,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onAdd,
                tooltip: 'Add planned expense',
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _CompactCountAction(
                  label: 'Upcoming',
                  count: upcoming,
                  color: semantic.planned,
                  onTap: onOpen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactCountAction(
                  label: 'Recurring',
                  count: recurring,
                  color: semantic.planned,
                  onTap: onOpen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactCountAction extends StatelessWidget {
  const _CompactCountAction({
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: Text(label)),
        const SizedBox(width: 6),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

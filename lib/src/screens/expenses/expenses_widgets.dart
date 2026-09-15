part of 'expenses_screen.dart';

AppSemanticColors _expenseSemanticColors(BuildContext context) =>
    Theme.of(context).extension<AppSemanticColors>() ??
    (Theme.of(context).brightness == Brightness.dark
        ? AppSemanticColors.dark
        : AppSemanticColors.light);

class _ExpensesHeading extends StatelessWidget {
  const _ExpensesHeading({required this.view, required this.selectedDate});

  final AppViewMode view;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
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
            fontSize: AppLayoutEngine.typographyFor(
              constraints.maxWidth,
            ).pageTitle,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          view == AppViewMode.admin ? 'Company expenses' : 'My expenses',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
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

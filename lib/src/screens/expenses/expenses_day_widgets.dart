part of 'expenses_screen.dart';

class _ExpenseSummary extends StatelessWidget {
  const _ExpenseSummary({required this.expenses});

  final List<ExpenseRecord> expenses;

  @override
  Widget build(BuildContext context) {
    final summary = ExpenseAmountSummary(expenses);
    return ExpenseTotalSummaryCard(
      label: 'Total expenses for this day',
      icon: Icons.payments_outlined,
      summary: summary,
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({
    required this.title,
    required this.expenses,
    required this.showJobLinks,
    required this.showAmounts,
    required this.onOpen,
  });

  final String title;
  final List<ExpenseRecord> expenses;
  final bool showJobLinks;
  final bool showAmounts;
  final ValueChanged<ExpenseRecord> onOpen;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (expenses.isEmpty)
          const Text('No expenses recorded for this day.')
        else
          for (var index = 0; index < expenses.length; index++) ...[
            ExpenseRecordCard(
              expense: expenses[index],
              showJob: showJobLinks,
              showOwner: true,
              showAmount: showAmounts,
              onTap: () => onOpen(expenses[index]),
            ),
            if (index != expenses.length - 1) const SizedBox(height: 8),
          ],
      ],
    ),
  );
}

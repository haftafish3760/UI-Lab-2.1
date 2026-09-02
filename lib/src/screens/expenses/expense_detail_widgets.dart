import 'package:flutter/material.dart';

import '../../shared/section_card.dart';
import 'expense_models.dart';

class ExpenseDetailSummary extends StatelessWidget {
  const ExpenseDetailSummary({required this.expense, super.key});

  final ExpenseRecord expense;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Column(
      children: [
        ExpenseDetailRow(label: 'Category', value: expense.category.label),
        ExpenseDetailRow(label: 'Submitted by', value: expense.owner),
        ExpenseDetailRow(
          label: 'Related job',
          value: expense.job ?? 'Not linked to a job',
        ),
        ExpenseDetailRow(
          label: 'Approval',
          value: expense.approvalStatus.label,
        ),
      ],
    ),
  );
}

class ExpenseAttentionReason extends StatelessWidget {
  const ExpenseAttentionReason({required this.expense, super.key});

  final ExpenseRecord expense;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reason =
        expense.submitterAttentionReason ?? expense.approvalReason ?? '';
    return SectionCard(
      padding: const EdgeInsets.all(10),
      backgroundColor: colors.surfaceContainerHighest,
      borderColor: colors.outline,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notification_important_outlined, color: colors.onSurface),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseDetailRow extends StatelessWidget {
  const ExpenseDetailRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

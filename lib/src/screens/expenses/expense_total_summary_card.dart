import 'package:flutter/material.dart';

import '../../shared/section_card.dart';
import 'expense_models.dart';

/// A period/category total that retains missing-value context at large text sizes.
class ExpenseTotalSummaryCard extends StatelessWidget {
  const ExpenseTotalSummaryCard({
    required this.label,
    required this.icon,
    required this.summary,
    this.showAmounts = true,
    super.key,
  });

  final String label;
  final IconData icon;
  final ExpenseAmountSummary summary;
  final bool showAmounts;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (showAmounts)
                    Text(
                      expenseMoney(summary.displayAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              if (showAmounts && summary.missingMessage != null) ...[
                const SizedBox(height: 8),
                Text(summary.missingMessage!),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

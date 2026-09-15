import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/operational_card_palette.dart';
import 'expense_models.dart';

class ExpenseRecordCard extends StatelessWidget {
  const ExpenseRecordCard({
    required this.expense,
    required this.onTap,
    this.showJob = true,
    this.showOwner = false,
    this.showAmount = true,
    super.key,
  });

  final ExpenseRecord expense;
  final VoidCallback onTap;
  final bool showJob;
  final bool showOwner;
  final bool showAmount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pending = expense.approvalStatus == ExpenseApprovalStatus.pending;
    final background = pending
        ? OperationalCardPalette.attention.start
        : colors.surfaceContainerLow;
    final foreground = pending
        ? OperationalCardPalette.attention.foreground
        : colors.onSurface;
    return Material(
      key: ValueKey('expense-record-${expense.id}'),
      color: background,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: pending ? foreground.withValues(alpha: .45) : colors.outline,
        ),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 8, 5),
            child: Row(
              children: [
                Icon(expense.category.icon, size: 22, color: foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: expense.displayVendor,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 13,
                                height: 1.1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: '\n$_detail',
                              style: TextStyle(
                                color: pending
                                    ? foreground
                                    : colors.onSurfaceVariant,
                                fontSize: 11.5,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showAmount && expense.amount == null)
                        Text(
                          'Amount not entered',
                          style: TextStyle(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showAmount && expense.amount != null)
                      Text(
                        expenseMoney(expense.amount),
                        style: TextStyle(
                          color: foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                      color: foreground,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _detail {
    if (expense.approvalStatus == ExpenseApprovalStatus.pending) {
      return 'Needs approval';
    }
    if (showJob && expense.job != null) {
      return expense.job!.split(' · ').first;
    }
    if (showOwner) return expense.category.label;
    return expense.category.label;
  }
}

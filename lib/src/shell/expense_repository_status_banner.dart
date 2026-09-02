import 'package:flutter/material.dart';

import '../data/expenses/expense_ui_repository_controller.dart';

class ExpenseRepositoryStatusBanner extends StatelessWidget {
  const ExpenseRepositoryStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ExpenseUiScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    if (controller.phase == ExpenseRepositoryControllerPhase.failed) {
      return _StatusBanner(
        key: const ValueKey('expense-repository-failure-banner'),
        icon: Icons.error_outline_rounded,
        message:
            controller.failure?.message ??
            'Expense records could not be loaded.',
        actionLabel: 'Retry',
        onAction: controller.load,
      );
    }
    if (controller.showRecoveryNotice) {
      return _StatusBanner(
        key: const ValueKey('expense-repository-recovery-banner'),
        icon: Icons.restore_rounded,
        message:
            'Expense records were recovered from the last valid device copy. '
            'The newest damaged copy was not used.',
        actionLabel: 'Dismiss',
        onAction: () async => controller.dismissRecoveryNotice(),
      );
    }
    return const SizedBox.shrink();
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: colors.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colors.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: colors.onErrorContainer,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../data/expenses/recurring_expense_ui_controller.dart';
import '../../shared/section_card.dart';

class RecurringExpenseRepositoryStatus extends StatelessWidget {
  const RecurringExpenseRepositoryStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = RecurringExpenseUiScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    final showLoading = controller.isLoading && controller.records.isEmpty;
    final showFailure = controller.phase == RecurringExpenseUiPhase.failed;
    final showRecovery = controller.showRecoveryNotice;
    if (!showLoading && !showFailure && !showRecovery) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return SectionCard(
      key: const ValueKey('recurring-expense-repository-status'),
      backgroundColor: showFailure
          ? colors.errorContainer
          : colors.tertiaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLoading) ...[
            const Text('Loading upcoming expenses…'),
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ] else if (showFailure) ...[
            Text(
              controller.failureMessage ??
                  'Upcoming expenses could not be loaded safely.',
              style: TextStyle(color: colors.onErrorContainer),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: controller.isLoading ? null : controller.load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ),
          ] else ...[
            const Text(
              'Upcoming expenses were recovered from the last valid saved '
              'copy. Review recent changes before continuing.',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: controller.dismissRecoveryNotice,
                child: const Text('I understand'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

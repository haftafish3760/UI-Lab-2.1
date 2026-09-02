import 'package:flutter/material.dart';

import '../../data/expenses/recurring_expense_ui_controller.dart';

Future<void> showScheduledExpenseFailure(
  BuildContext context, {
  String? message,
  String fallbackMessage =
      'The planned expense could not be changed. Try again.',
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Planned expense not changed'),
    content: Text(
      message ??
          RecurringExpenseUiScope.maybeOf(context)?.failureMessage ??
          fallbackMessage,
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('Close'),
      ),
    ],
  ),
);

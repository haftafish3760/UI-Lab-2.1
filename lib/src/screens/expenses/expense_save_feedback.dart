import 'package:flutter/material.dart';

import '../../data/expenses/expense_ui_repository_controller.dart';

Future<bool> showExpenseSaveFailure(
  BuildContext context, {
  String fallbackMessage =
      'The expense was not saved. Review it and try again.',
}) async {
  final message =
      ExpenseUiScope.maybeOf(context)?.failure?.message ?? fallbackMessage;
  final keepEditing = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Expense not saved'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Discard draft'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Keep editing'),
        ),
      ],
    ),
  );
  return keepEditing ?? true;
}

Future<void> showExpenseActionFailure(
  BuildContext context, {
  String title = 'Expense not changed',
  String fallbackMessage = 'The expense could not be changed. Try again.',
}) async {
  final message =
      ExpenseUiScope.maybeOf(context)?.failure?.message ?? fallbackMessage;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

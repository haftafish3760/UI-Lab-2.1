part of 'scheduled_expense_detail_screen.dart';

class _ScheduleActions extends StatelessWidget {
  const _ScheduleActions({
    required this.record,
    required this.occurrence,
    required this.module,
    required this.controller,
    required this.permissions,
  });

  final ScheduledExpenseRecord record;
  final ScheduledExpenseOccurrence? occurrence;
  final ExpensePrototypeStore module;
  final RecurringExpenseUiController? controller;
  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: WrapAlignment.end,
    children: [
      if (occurrence != null && record.isActive)
        OutlinedButton.icon(
          key: const ValueKey('edit-scheduled-expense-occurrence'),
          onPressed: _isPending(context)
              ? null
              : () => _editOccurrence(context),
          icon: const Icon(Icons.event_note_outlined),
          label: const Text('Edit this payment'),
        ),
      OutlinedButton.icon(
        onPressed: _isPending(context) ? null : () => _editFuture(context),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit this and future'),
      ),
      if (record.state != ScheduledExpenseState.ended)
        OutlinedButton.icon(
          onPressed: _isPending(context) ? null : () => _toggleState(context),
          icon: Icon(
            record.state == ScheduledExpenseState.paused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
          ),
          label: Text(
            record.state == ScheduledExpenseState.paused ? 'Resume' : 'Pause',
          ),
        ),
      if (occurrence != null && record.isActive) ...[
        OutlinedButton.icon(
          onPressed: _isPending(context) ? null : () => _skip(context),
          icon: const Icon(Icons.skip_next_rounded),
          label: const Text('Skip this payment'),
        ),
        FilledButton.icon(
          key: const ValueKey('mark-scheduled-expense-paid'),
          onPressed: permissions.canCreate && !_isPending(context)
              ? () => _markPaid(context)
              : null,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Mark paid'),
        ),
      ],
    ],
  );

  bool _isPending(BuildContext context) =>
      RecurringPaymentScope.maybeOf(context)?.isPending(record.id) == true ||
      controller?.isPending(record.id) == true ||
      (occurrence != null && controller?.isPending(occurrence!.id) == true);

  Future<void> _editFuture(BuildContext context) async {
    final edited = await Navigator.of(context).push<ScheduledExpenseRecord>(
      MaterialPageRoute(
        builder: (_) => ScheduledExpenseEditorScreen(
          initial: record,
          onConfirm: controller?.update,
          permissions: permissions,
        ),
      ),
    );
    if (edited == null || !context.mounted) return;
    final durable = controller;
    if (durable == null) {
      module.updateScheduledExpense(edited);
      return;
    }
  }

  Future<void> _editOccurrence(BuildContext context) async {
    final edited = await Navigator.of(context).push<ScheduledExpenseOccurrence>(
      MaterialPageRoute(
        builder: (_) => ScheduledExpenseOccurrenceEditorScreen(
          occurrence: occurrence!,
          onConfirm: controller?.updateOccurrence,
          permissions: permissions,
        ),
      ),
    );
    if (edited == null) return;
    final durable = controller;
    if (durable == null) {
      module.updateScheduledExpenseOccurrence(
        templateId: record.id,
        occurrenceId: occurrence!.id,
        dueOn: edited.dueOn,
        expectedAmount: edited.expectedAmount,
      );
      return;
    }
  }

  Future<void> _toggleState(BuildContext context) async {
    final next = record.state == ScheduledExpenseState.paused
        ? ScheduledExpenseState.active
        : ScheduledExpenseState.paused;
    final durable = controller;
    if (durable == null) {
      module.setScheduledExpenseState(record.id, next);
      return;
    }
    if (!await durable.setState(record.id, next) && context.mounted) {
      await showScheduledExpenseFailure(context);
    }
  }

  Future<void> _skip(BuildContext context) async {
    final current = occurrence;
    if (current == null) return;
    final durable = controller;
    if (durable == null) {
      module.skipScheduledExpense(
        templateId: record.id,
        occurrenceId: current.id,
      );
      return;
    }
    if (!await durable.skip(record.id, current.id) && context.mounted) {
      await showScheduledExpenseFailure(context);
    }
  }

  Future<void> _markPaid(BuildContext context) async {
    if (!permissions.canCreate || _isPending(context)) return;
    final paymentSession = RecurringPaymentScope.maybeOf(context);
    final expectedTemplateRevision = controller?.revisionForId(record.id);
    final expectedOccurrenceRevision = controller?.occurrenceRevisionForId(
      occurrence!.id,
    );
    if (paymentSession != null &&
        LocalDraftScope.maybeOf(context) != null &&
        record.amountKind == ScheduledExpenseAmountKind.enterWhenPaid) {
      final confirmed = await showScheduledPaymentDraftDialog(
        context,
        template: record,
        occurrence: occurrence!,
      );
      if (confirmed != null && context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExpenseDetailScreen(
              expenseId: confirmed.id,
              permissions: permissions,
            ),
          ),
        );
      }
      return;
    }
    double? actualAmount;
    if (record.amountKind == ScheduledExpenseAmountKind.enterWhenPaid) {
      actualAmount = await showScheduledExpensePaymentAmountDialog(
        context,
        expectedAmount: occurrence!.expectedAmount,
      );
      if (actualAmount == null || !context.mounted) return;
    }
    final paidOn = DateTime.now();
    final durable = controller;
    ExpenseRecord? expense;
    if (durable == null) {
      expense = module.markScheduledExpensePaid(
        templateId: record.id,
        occurrenceId: occurrence!.id,
        paidOn: paidOn,
        actualAmount: actualAmount,
      );
    } else {
      final expenseController = ExpenseUiScope.maybeOf(context);
      if (expenseController == null) {
        await showScheduledExpenseFailure(
          context,
          message: 'Expense storage is not ready. The payment was not changed.',
        );
        return;
      }
      final result = paymentSession != null
          ? await paymentSession.markPaid(
              templateId: record.id,
              occurrenceId: occurrence!.id,
              expectedTemplateRevision: expectedTemplateRevision!,
              expectedOccurrenceRevision: expectedOccurrenceRevision!,
              actualAmount: actualAmount ?? occurrence!.expectedAmount,
              paidOn: paidOn,
            )
          : await RecurringExpensePaymentCoordinator(
              expenses: expenseController,
              recurringExpenses: durable,
            ).markPaid(
              template: record,
              occurrence: occurrence!,
              actualAmount: actualAmount ?? occurrence!.expectedAmount,
              paidOn: paidOn,
            );
      if (!result.succeeded) {
        if (context.mounted) {
          await showScheduledExpenseFailure(
            context,
            message:
                result.message ??
                'The payment could not be recorded. Try again.',
          );
        }
        return;
      }
      expense = result.expense;
    }
    final savedExpense = expense;
    if (savedExpense == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExpenseDetailScreen(
          expenseId: savedExpense.id,
          permissions: permissions,
        ),
      ),
    );
  }
}

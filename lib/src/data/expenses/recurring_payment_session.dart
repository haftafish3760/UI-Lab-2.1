import '../storage/draft_repository.dart';
import 'package:flutter/widgets.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/serialized_async_actions.dart';
import 'atomic_recurring_expense_payment.dart';
import 'authorized_expense_service.dart';
import 'authorized_recurring_expense_service.dart';
import 'expense_ui_repository_controller.dart';
import 'recurring_expense_payment_coordinator.dart';
import 'recurring_expense_ui_controller.dart';

class RecurringPaymentSession extends ChangeNotifier {
  RecurringPaymentSession({
    required this.service,
    this.drafts,
    required this.expenses,
    required this.recurringExpenses,
    required this.expensePermissions,
    required this.recurringPermissions,
  });
  final AtomicRecurringExpensePayment service;
  final DraftRepository? drafts;
  final ExpenseUiRepositoryController expenses;
  final RecurringExpenseUiController recurringExpenses;
  final ExpenseCommandPermissions expensePermissions;
  final RecurringExpenseCommandPermissions recurringPermissions;
  final _actions = SerializedAsyncActions();
  Future<AsyncActionPause> pauseOperations() => _actions.pauseAndDrain();
  final _pending = <String>{};
  bool _disposed = false;

  void requireActiveDraftOwner() {
    if (_disposed) {
      throw StateError('The expense workflow owner is no longer active.');
    }
  }

  bool isPending(String templateId) => _pending.contains(templateId);
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<RecurringExpensePaymentResult> markPaid({
    required String templateId,
    required String occurrenceId,
    required int expectedTemplateRevision,
    required int expectedOccurrenceRevision,
    required double actualAmount,
    required DateTime paidOn,
    LocalDraftCheckpoint? draftCheckpoint,
  }) {
    if (_disposed || !_pending.add(templateId)) {
      return Future.value(
        const RecurringExpensePaymentResult.failure(
          'This payment is already being saved or its session is unavailable.',
        ),
      );
    }
    notifyListeners();
    return _actions.run(() async {
      try {
        final result = await service.markPaid(
          templateId: templateId,
          occurrenceId: occurrenceId,
          expectedTemplateRevision: expectedTemplateRevision,
          expectedOccurrenceRevision: expectedOccurrenceRevision,
          actualAmount: actualAmount,
          paidOn: paidOn,
          expensePermissions: expensePermissions,
          recurringPermissions: recurringPermissions,
          draftCheckpoint: draftCheckpoint,
        );
        if (result.succeeded) {
          // Refresh failures are controller state; the payment is already committed.
          await expenses.load();
          await recurringExpenses.load();
        }
        return result;
      } finally {
        _pending.remove(templateId);
        if (!_disposed) notifyListeners();
      }
    });
  }
}

class RecurringPaymentScope extends InheritedNotifier<RecurringPaymentSession> {
  const RecurringPaymentScope({
    required RecurringPaymentSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);
  static RecurringPaymentSession? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<RecurringPaymentScope>()
      ?.notifier;
}

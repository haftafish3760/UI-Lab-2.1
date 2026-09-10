import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/expenses/recurring_payment_session.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/expenses/recurring_payment_draft_workflow.dart';
import '../../shared/editor_draft_status.dart';
import '../../shared/draft_navigation_guard.dart';
import 'expense_models.dart';

Future<ExpenseRecord?> showScheduledPaymentDraftDialog(
  BuildContext context, {
  required ScheduledExpenseRecord template,
  required ScheduledExpenseOccurrence occurrence,
  RecurringPaymentDraftController? recoveredWorkflow,
}) => showDialog<ExpenseRecord>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _ScheduledPaymentDraftDialog(
    template: template,
    occurrence: occurrence,
    recoveredWorkflow: recoveredWorkflow,
  ),
);

class _ScheduledPaymentDraftDialog extends StatefulWidget {
  const _ScheduledPaymentDraftDialog({
    required this.template,
    required this.occurrence,
    this.recoveredWorkflow,
  });
  final ScheduledExpenseRecord template;
  final ScheduledExpenseOccurrence occurrence;
  final RecurringPaymentDraftController? recoveredWorkflow;
  @override
  State<_ScheduledPaymentDraftDialog> createState() =>
      _ScheduledPaymentDraftDialogState();
}

class _ScheduledPaymentDraftDialogState
    extends State<_ScheduledPaymentDraftDialog>
    with DraftNavigationGuard<_ScheduledPaymentDraftDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.occurrence.expectedAmount.toStringAsFixed(2),
  );
  late RecurringPaymentDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  late RecurringPaymentSession _session;
  bool _started = false;
  bool _opening = true;
  bool _saving = false;
  String? _error;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session = RecurringPaymentScope.maybeOf(context)!;
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
  }

  void _capture() {
    if (_opening || _saving) return;
    _workflow?.updateAmount(_amount.text);
  }

  Future<void> _open() async {
    if (!mounted) return;
    try {
      final workflow =
          _workflow ??
          await _session.openPaymentDraft(
            templateId: widget.template.id,
            occurrenceId: widget.occurrence.id,
          );
      if (!mounted) {
        await workflow.session.close();
        return;
      }
      if (workflow.session.organizationId !=
              _session.recurringExpenses.organizationId ||
          workflow.session.ownerId !=
              _session.recurringExpenses.actorEmployeeId ||
          workflow.input.templateId != widget.template.id ||
          workflow.input.occurrenceId != widget.occurrence.id ||
          !_session.recurringExpenses.canPayForEmployee(
            widget.template.ownerEmployeeId,
          ) ||
          !_session.expenses.canCreateForEmployee(
            widget.template.ownerEmployeeId,
          )) {
        await workflow.session.close();
        _workflow = null;
        throw StateError('Recovered payment does not match this editor.');
      }
      _workflow = workflow;
      _amount.text = workflow.input.amount;
      final draft = workflow.session;
      _amount.addListener(_capture);
      _subscription = draft.changes.listen((_) {
        if (mounted) setState(() {});
      });
      setState(() => _opening = false);
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'Saved payment input could not be opened. Leave and retry; retained input has been preserved.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    AlertDialog(
      key: const ValueKey('scheduled-expense-payment-amount-dialog'),
      title: const Text('Enter amount paid'),
      content: _opening
          ? Text(_error ?? 'Opening saved input…')
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EditorDraftStatus(
                      state: _draft!.state,
                      onRetry: _draft!.retry,
                      onDiscard: _discard,
                    ),
                    TextFormField(
                      key: const ValueKey('scheduled-expense-actual-amount'),
                      controller: _amount,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Actual amount',
                        prefixText: r'$ ',
                      ),
                      validator: (value) =>
                          RecurringPaymentDraftInput.amountError(value ?? ''),
                    ),
                    if (_error != null) Text(_error!),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _saving ? null : leaveDraftRoute,
          child: const Text('Keep unfinished'),
        ),
        FilledButton(
          key: const ValueKey('confirm-scheduled-expense-payment'),
          onPressed: _saving || _opening ? null : _confirm,
          child: Text(_saving ? 'Saving…' : 'Record payment'),
        ),
      ],
    ),
  );
  Future<void> _confirm() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await _workflow!.confirm();
      if (!mounted) return;
      if (result.succeeded) {
        await finishDraftRoute(result.expense);
      } else {
        setState(() {
          _saving = false;
          _error =
              result.message ??
              'The payment was not saved. Your input is preserved.';
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'The payment was not saved. Your input is preserved. Retry saving.';
        });
      }
    }
  }

  Future<void> _discard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished payment input?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard input'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    setState(() => _saving = true);
    try {
      await _draft!.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'The draft could not be discarded. Your input has been preserved.';
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    unawaited(_draft?.close().catchError((Object _) {}));
    _amount.dispose();
    super.dispose();
  }
}

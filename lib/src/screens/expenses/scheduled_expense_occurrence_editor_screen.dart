import 'dart:async';
import '../../data/expenses/recurring_expense_ui_controller.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/expenses/recurring_occurrence_draft_workflow.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import 'package:flutter/material.dart';

import '../../shared/localized_date.dart';
import 'expense_models.dart';
import 'expense_permission_denied.dart';
import 'expense_permissions.dart';

part 'scheduled_occurrence_draft_recovery.dart';

class ScheduledExpenseOccurrenceEditorScreen extends StatefulWidget {
  const ScheduledExpenseOccurrenceEditorScreen({
    required this.occurrence,
    this.onConfirm,
    this.recoveredWorkflow,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final ScheduledExpenseOccurrence occurrence;
  final RecurringOccurrenceDraftController? recoveredWorkflow;
  final ExpensePermissions permissions;
  final Future<ScheduledExpenseOccurrence?> Function(
    ScheduledExpenseOccurrence,
  )?
  onConfirm;

  @override
  State<ScheduledExpenseOccurrenceEditorScreen> createState() =>
      _ScheduledExpenseOccurrenceEditorScreenState();
}

class _ScheduledExpenseOccurrenceEditorScreenState
    extends State<ScheduledExpenseOccurrenceEditorScreen>
    with DraftNavigationGuard<ScheduledExpenseOccurrenceEditorScreen> {
  bool _saving = false;
  bool _opening = true;
  bool _started = false;
  String? _error;
  late RecurringOccurrenceDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  RecurringExpenseUiController? _controller;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  void _refresh(VoidCallback change) => setState(change);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = RecurringExpenseUiScope.maybeOf(context);
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openDraft());
    }
  }

  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.occurrence.expectedAmount.toStringAsFixed(2),
  );
  late var _dueOn = widget.occurrence.dueOn;

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canView ||
        !widget.permissions.canViewAmounts ||
        !widget.permissions.canManageScheduledExpenses) {
      return const ExpensePermissionDeniedScaffold(
        screenKey: ValueKey('scheduled-expense-occurrence-editor-screen'),
        message: 'You do not have permission to edit this payment.',
      );
    }
    return guardDraftNavigation(
      Scaffold(
        key: const ValueKey('scheduled-expense-occurrence-editor-screen'),
        appBar: AppBar(title: const Text('Edit this payment')),
        body: _opening
            ? Center(child: Text(_error ?? 'Opening saved input…'))
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_draft != null)
                      EditorDraftStatus(
                        state: _draft!.state,
                        onRetry: _draft!.retry,
                        onDiscard: _discardDraft,
                      ),
                    const Text(
                      'These changes apply only to this payment. The recurring setup '
                      'and later payments stay the same.',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const ValueKey('occurrence-due-date'),
                      onPressed: _chooseDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        'Due ${operationalShortDateLabel(context, _dueOn)}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('occurrence-expected-amount'),
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Expected amount for this payment',
                        prefixText: r'$ ',
                      ),
                      validator: (value) =>
                          RecurringOccurrenceDraftInput.amountError(
                            value ?? '',
                          ),
                    ),
                    const SizedBox(height: 18),
                    if (_error != null) Text(_error!),
                    FilledButton.icon(
                      key: const ValueKey('save-occurrence-edit'),
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving…' : 'Save this payment'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _dueOn,
    );
    if (mounted && chosen != null) {
      setState(() => _dueOn = DateUtils.dateOnly(chosen));
      _captureDraft();
    }
  }

  Future<void> _save() async {
    if (_saving || _opening) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final ScheduledExpenseOccurrence? confirmed;
      if (_workflow != null) {
        confirmed = await _workflow!.confirm();
      } else {
        final edited = RecurringOccurrenceDraftInput(
          occurrenceId: widget.occurrence.id,
          templateId: widget.occurrence.templateId,
          baseRevision: 0,
          baseTemplateRevision: 0,
          amount: _amount.text,
          dueOn: _dueOn,
        ).confirmedOccurrence(widget.occurrence);
        confirmed = widget.onConfirm == null
            ? edited
            : await widget.onConfirm!(edited);
      }
      if (confirmed == null) throw StateError('Confirmation failed.');
      if (mounted) await finishDraftRoute(confirmed);
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = _staleDraft
              ? 'This payment or its plan changed after editing started. Your unfinished input is preserved.'
              : 'The payment was not saved. Your input is still here. Retry saving.';
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

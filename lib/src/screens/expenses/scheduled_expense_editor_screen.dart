import 'dart:async';
import 'package:flutter/material.dart';

import '../../shared/localized_date.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/expenses/recurring_plan_draft_input.dart';
import '../../data/expenses/recurring_plan_draft_workflow.dart';
import '../../data/expenses/recurring_expense_ui_controller.dart';

import 'expense_models.dart';
import 'expense_permission_denied.dart';
import 'expense_permissions.dart';

part 'scheduled_expense_draft_recovery.dart';

class ScheduledExpenseEditorScreen extends StatefulWidget {
  const ScheduledExpenseEditorScreen({
    this.initial,
    this.recoveredWorkflow,
    this.onConfirm,
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final ScheduledExpenseRecord? initial;

  /// Transfers an already authorized workflow to this editor. The editor closes
  /// it on exit, retaining input unless the user explicitly discards or saves.
  final RecurringPlanDraftController? recoveredWorkflow;
  final Future<ScheduledExpenseRecord?> Function(ScheduledExpenseRecord)?
  onConfirm;
  final ExpensePermissions permissions;

  @override
  State<ScheduledExpenseEditorScreen> createState() =>
      _ScheduledExpenseEditorScreenState();
}

class _ScheduledExpenseEditorScreenState
    extends State<ScheduledExpenseEditorScreen>
    with DraftNavigationGuard<ScheduledExpenseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _previewInput = RecurringPlanDraftInput.initial(
    record: widget.initial,
    ownerId: 'alex',
    ownerLabel: 'Alex Morgan',
  );
  bool _saving = false;
  bool _draftOpening = true;
  bool _draftStarted = false;
  late RecurringPlanDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _draftSubscription;
  RecurringExpenseUiController? _controller;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = RecurringExpenseUiScope.maybeOf(context);
    if (!_draftStarted) {
      _draftStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPlannedDraft());
    }
  }

  void _refresh(VoidCallback change) => setState(change);
  void _change(VoidCallback change) {
    final previousDay = _dueDay;
    final previousKind = _kind;
    setState(() {
      change();
      _dueDate = recurringPlanDueDateAfterChange(
        previousKind: previousKind,
        previousDay: previousDay,
        kind: _kind,
        dueDay: _dueDay,
        dueDate: _dueDate,
        now: DateTime.now(),
      );
    });
    _capturePlannedDraft();
  }

  String? _saveError;
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _amount = TextEditingController(
    text: widget.initial?.amount.toStringAsFixed(2),
  );
  late var _category = widget.initial?.category ?? ExpenseCategory.office;
  late var _kind = widget.initial?.kind ?? ExpenseScheduleKind.monthly;
  late var _amountKind =
      widget.initial?.amountKind ?? ScheduledExpenseAmountKind.fixed;
  late var _dueDate =
      widget.initial?.nextDueOn ??
      DateUtils.dateOnly(DateTime.now().add(const Duration(days: 7)));
  late var _dueDay = widget.initial?.dueDay ?? _dueDate.day;
  late final _reminders = {...?widget.initial?.reminderDaysBefore};
  late var _inApp = widget.initial?.inAppReminder ?? true;
  late var _push = widget.initial?.pushReminder ?? true;
  late var _sound = widget.initial?.soundReminder ?? true;
  late var _receiptRequired = widget.initial?.receiptRequired ?? false;

  @override
  Widget build(BuildContext context) {
    if (!widget.permissions.canView ||
        !widget.permissions.canViewAmounts ||
        !widget.permissions.canManageScheduledExpenses) {
      return const ExpensePermissionDeniedScaffold(
        screenKey: ValueKey('scheduled-expense-editor-screen'),
        message: 'You do not have permission to manage planned expenses.',
      );
    }
    return guardDraftNavigation(
      Scaffold(
        appBar: AppBar(
          title: Text(
            widget.initial == null
                ? 'Add planned expense'
                : 'Edit planned expense',
          ),
        ),
        body: _draftOpening
            ? Center(child: Text(_saveError ?? 'Opening saved input…'))
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 32),
                  children: [
                    if (_draft != null)
                      EditorDraftStatus(
                        state: _draft!.state,
                        onRetry: _draft!.retry,
                        onDiscard: _discardPlannedDraft,
                      ),
                    TextFormField(
                      key: const ValueKey('scheduled-expense-title'),
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Expense title',
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Enter a title.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('scheduled-expense-amount'),
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Usual or expected amount',
                        prefixText: r'$ ',
                      ),
                      validator: (value) =>
                          RecurringPlanDraftInput.amountError(value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ScheduledExpenseAmountKind>(
                      initialValue: _amountKind,
                      decoration: const InputDecoration(
                        labelText: 'Amount handling',
                      ),
                      items: [
                        for (final item in ScheduledExpenseAmountKind.values)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                      ],
                      onChanged: (value) =>
                          _change(() => _amountKind = value ?? _amountKind),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ExpenseCategory>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final item in ExpenseCategory.values)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                      ],
                      onChanged: (value) =>
                          _change(() => _category = value ?? _category),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<ExpenseScheduleKind>(
                      segments: const [
                        ButtonSegment(
                          value: ExpenseScheduleKind.oneTime,
                          label: Text('One time'),
                        ),
                        ButtonSegment(
                          value: ExpenseScheduleKind.monthly,
                          label: Text('Every month'),
                        ),
                      ],
                      selected: {_kind},
                      onSelectionChanged: (value) =>
                          _change(() => _kind = value.first),
                    ),
                    const SizedBox(height: 12),
                    if (_kind == ExpenseScheduleKind.monthly)
                      DropdownButtonFormField<int>(
                        initialValue: _dueDay,
                        decoration: const InputDecoration(
                          labelText: 'Day of the month',
                        ),
                        items: [
                          for (var day = 1; day <= 31; day++)
                            DropdownMenuItem(value: day, child: Text('$day')),
                        ],
                        onChanged: (value) =>
                            _change(() => _dueDay = value ?? _dueDay),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _chooseDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          'Due ${operationalShortDateLabel(context, _dueDate)}',
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Set up reminders',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose up to five reminders before this expense is due.',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final day in const [1, 3, 7, 14, 30])
                          FilterChip(
                            label: Text(
                              '$day day${day == 1 ? '' : 's'} before',
                            ),
                            selected: _reminders.contains(day),
                            onSelected: (selected) => _change(
                              () => selected
                                  ? _reminders.add(day)
                                  : _reminders.remove(day),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('In-app reminder'),
                      value: _inApp,
                      onChanged: (value) => _change(() => _inApp = value),
                    ),
                    SwitchListTile(
                      title: const Text('Device notification'),
                      subtitle: const Text(
                        'Show this reminder even when Maintainiac is closed.',
                      ),
                      value: _push,
                      onChanged: (value) => _change(() {
                        _push = value;
                        if (!value) _sound = false;
                      }),
                    ),
                    SwitchListTile(
                      title: const Text('Play a sound'),
                      value: _sound,
                      onChanged: _push
                          ? (value) => _change(() => _sound = value)
                          : null,
                    ),
                    SwitchListTile(
                      title: const Text('Require a receipt each time'),
                      subtitle: const Text(
                        'Each paid occurrence stays open until its expense has receipt evidence.',
                      ),
                      value: _receiptRequired,
                      onChanged: (value) =>
                          _change(() => _receiptRequired = value),
                    ),
                    const SizedBox(height: 12),
                    if (_saveError != null) Text(_saveError!),
                    FilledButton.icon(
                      key: const ValueKey('save-scheduled-expense'),
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        _saving ? 'Saving…' : 'Save upcoming expense',
                      ),
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
      firstDate: DateTime(2017),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _dueDate,
    );
    if (mounted && chosen != null) _change(() => _dueDate = chosen);
  }

  Future<void> _save() async {
    if (_saving || _draftOpening) return;
    if (_workflow?.isStale ?? false) {
      setState(
        () => _saveError =
            'This planned expense changed after editing started. Your unfinished input is preserved. Review the current record before replacing it.',
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final ScheduledExpenseRecord? confirmed;
      if (_workflow != null) {
        confirmed = await _workflow!.confirm();
      } else {
        final record = _formInput.confirmedRecord();
        confirmed = widget.onConfirm == null
            ? record
            : await widget.onConfirm!(record);
      }
      if (!mounted) return;
      if (confirmed == null) throw StateError('Confirmation failed.');
      await finishDraftRoute(confirmed);
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError =
              'The planned expense was not saved. Your input is still here. Retry saving.';
        });
      }
    }
  }

  @override
  void dispose() {
    _draftSubscription?.cancel();
    unawaited(_draft?.close().catchError((Object _) {}));
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }
}

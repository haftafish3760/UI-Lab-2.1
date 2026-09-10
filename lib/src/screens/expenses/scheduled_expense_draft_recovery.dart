part of 'scheduled_expense_editor_screen.dart';

extension _ScheduledExpenseDraftRecovery on _ScheduledExpenseEditorScreenState {
  RecurringPlanDraftInput get _formInput {
    final base = _workflow?.input ?? _previewInput;
    return RecurringPlanDraftInput(
      recordId: base.recordId,
      baseRevision: base.baseRevision,
      ownerId: base.ownerId,
      ownerLabel: base.ownerLabel,
      state: base.state,
      title: _title.text,
      amount: _amount.text,
      category: _category,
      kind: _kind,
      amountKind: _amountKind,
      dueDate: _dueDate,
      dueDay: _dueDay,
      reminders: _reminders,
      inApp: _inApp,
      push: _push,
      sound: _sound,
      receiptRequired: _receiptRequired,
    );
  }

  void _capturePlannedDraft() {
    if (_draftOpening || _saving) return;
    _workflow?.updateInput(_formInput);
  }

  Future<void> _openPlannedDraft() async {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null || controller.drafts == null) {
      _refresh(() => _draftOpening = false);
      return;
    }
    try {
      if (!widget.permissions.canView ||
          !widget.permissions.canViewAmounts ||
          !widget.permissions.canManageScheduledExpenses) {
        throw StateError('Planned expense editing is unavailable.');
      }
      String? recoveryId;
      if (widget.initial == null && _workflow == null) {
        final candidates = await controller.plannedDraftRecovery.list();
        if (!mounted) return;
        if (candidates.isNotEmpty) {
          final chosen = await showDialog<String>(
            context: context,
            builder: (dialogContext) => SimpleDialog(
              title: const Text('Continue an unfinished planned expense?'),
              children: [
                for (final choice in candidates)
                  SimpleDialogOption(
                    onPressed: () =>
                        Navigator.pop(dialogContext, choice.draftId),
                    child: Text(choice.label),
                  ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, 'new'),
                  child: const Text('Start another planned expense'),
                ),
              ],
            ),
          );
          if (!mounted) return;
          if (chosen == null) {
            await leaveDraftRoute();
            return;
          }
          if (chosen != 'new') recoveryId = chosen;
        }
      }
      final workflow =
          _workflow ??
          await controller.openPlannedDraft(
            existingRecordId: widget.initial?.id,
            recoveryDraftId: recoveryId,
          );
      if (!mounted) {
        await workflow.session.close();
        return;
      }
      _workflow = workflow;
      final input = workflow.input;
      if (widget.recoveredWorkflow != null &&
          (workflow.session.organizationId != controller.organizationId ||
              workflow.session.ownerId != controller.actorEmployeeId ||
              (input.baseRevision == null
                  ? widget.initial != null
                  : widget.initial?.id != input.recordId))) {
        throw StateError('Recovered plan does not match this editor.');
      }
      _title.text = input.title;
      _amount.text = input.amount;
      _category = input.category;
      _kind = input.kind;
      _amountKind = input.amountKind;
      _dueDate = input.dueDate;
      _dueDay = input.dueDay;
      _reminders
        ..clear()
        ..addAll(input.reminders);
      _inApp = input.inApp;
      _push = input.push;
      _sound = input.sound;
      _receiptRequired = input.receiptRequired;
      _title.addListener(_capturePlannedDraft);
      _amount.addListener(_capturePlannedDraft);
      _draftSubscription = workflow.session.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      _refresh(() => _draftOpening = false);
      if (workflow.isStale) {
        _refresh(
          () => _saveError =
              'This planned expense changed after editing started. Your unfinished input is preserved. Review the current record before replacing it.',
        );
      }
    } on Object {
      if (mounted) {
        _refresh(
          () => _saveError =
              'Saved planned-expense input could not be opened. Leave and retry; retained input has been preserved.',
        );
      }
    }
  }

  Future<void> _discardPlannedDraft() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished planned expense input?'),
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
    _refresh(() => _saving = true);
    try {
      await _draft!.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _saveError =
              'The draft could not be discarded. Your input has been preserved.';
        });
      }
    }
  }
}

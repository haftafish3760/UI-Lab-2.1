part of 'scheduled_expense_occurrence_editor_screen.dart';

extension _ScheduledOccurrenceDraftRecovery
    on _ScheduledExpenseOccurrenceEditorScreenState {
  bool get _staleDraft => _workflow?.isStale ?? false;

  void _captureDraft() {
    if (_opening || _saving) return;
    _workflow?.updateValues(amount: _amount.text, dueOn: _dueOn);
  }

  Future<void> _openDraft() async {
    if (!mounted) return;
    final controller = _controller;
    if (controller == null || controller.drafts == null) {
      _refresh(() => _opening = false);
      return;
    }
    try {
      if (!controller.canManage ||
          !widget.permissions.canView ||
          !widget.permissions.canViewAmounts ||
          !widget.permissions.canManageScheduledExpenses) {
        throw StateError('Payment editing is unavailable.');
      }
      final workflow =
          _workflow ??
          await controller.openOccurrenceDraft(
            templateId: widget.occurrence.templateId,
            occurrenceId: widget.occurrence.id,
          );
      if (!mounted) {
        await workflow.session.close();
        return;
      }
      if (workflow.session.organizationId != controller.organizationId ||
          workflow.session.ownerId != controller.actorEmployeeId ||
          workflow.input.templateId != widget.occurrence.templateId ||
          workflow.input.occurrenceId != widget.occurrence.id) {
        await workflow.session.close();
        _workflow = null;
        throw StateError('Recovered occurrence does not match this editor.');
      }
      _workflow = workflow;
      _amount.text = workflow.input.amount;
      _dueOn = workflow.input.dueOn;
      final draft = workflow.session;
      _amount.addListener(_captureDraft);
      _subscription = draft.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      _refresh(() {
        _opening = false;
        if (_staleDraft) {
          _error =
              'This payment or its plan changed after editing started. Your unfinished input is preserved.';
        }
      });
    } on Object {
      if (mounted) {
        _refresh(
          () => _error =
              'Saved payment input could not be opened. Leave and retry; retained input has been preserved.',
        );
      }
    }
  }

  Future<void> _discardDraft() async {
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
    _refresh(() => _saving = true);
    try {
      await _draft!.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _error =
              'The draft could not be discarded. Your input has been preserved.';
        });
      }
    }
  }
}

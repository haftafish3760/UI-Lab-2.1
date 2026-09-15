part of 'expenses_settings_screen.dart';

extension _ExpenseSettingsDraftRecovery on _ExpensesSettingsScreenState {
  void _capture() {
    if (!_ready || _saving) return;
    _workflow?.updateInput(
      ExpenseDisplayDraftInput(
        preferences: _current,
        pendingCategories: _pendingCategories,
        pendingReceiptTypes: _pendingReceiptTypes,
      ),
    );
  }

  Future<void> _openInput() async {
    try {
      final selected = _workflow;
      if (selected != null) {
        final owner = _saved;
        if (owner == null) throw StateError('Durable preferences unavailable.');
        owner.validateExpenseDisplayHandoff(selected);
      }
      final workflow =
          selected ?? await _saved?.openExpenseDisplayDraft(initial: _current);
      if (!mounted) {
        await workflow?.session.close();
        return;
      }
      if (workflow == null) {
        _refresh(() => _ready = true);
        return;
      }
      _workflow = workflow;
      final input = workflow.input;
      final restored = input.preferences;
      _weekStartsOn = restored.weekStartsOn;
      _showJobLinks = restored.showJobLinks;
      _categoryMode = restored.categoryMode;
      _customCategories
        ..clear()
        ..addAll(restored.customCategories);
      _receiptTypes
        ..clear()
        ..addAll(restored.receiptTypes);
      _pendingCategories = input.pendingCategories == null
          ? null
          : Set.of(input.pendingCategories!);
      _pendingReceiptTypes = input.pendingReceiptTypes == null
          ? null
          : Map.of(input.pendingReceiptTypes!);
      final opening = workflow.session;
      _subscription = opening.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      _refresh(() => _ready = true);
      _capture();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        _refresh(
          () => _error =
              'Saved settings input could not be opened. Leave and retry; the saved draft has been preserved.',
        );
      }
    }
  }

  Future<void> _confirm() async {
    if (_saving || !_ready) return;
    if (_pendingCategories != null || _pendingReceiptTypes != null) {
      _refresh(
        () => _error =
            'Finish or cancel your unfinished choices before saving settings.',
      );
      return;
    }
    _capture();
    _refresh(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = _workflow != null
          ? await _workflow!.confirm()
          : await _saved?.applyExpenseDisplay(_current);
      if (saved == false) throw StateError('Settings confirmation failed.');
      if (mounted) await finishDraftRoute(_current);
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _error =
              'Expense display settings were not applied. Your unfinished choices have been kept; retry Save.';
        });
      }
    }
  }

  Future<void> _discard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unfinished Expense display settings?'),
        content: const Text(
          'Your active Expense display settings stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard input'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    _refresh(() => _saving = true);
    try {
      await _session?.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _error =
              'Unfinished settings could not be discarded. They have been preserved.';
        });
      }
    }
  }
}

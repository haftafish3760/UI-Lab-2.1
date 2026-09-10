part of 'reports_settings_screen.dart';

extension _ReportSettingsDraftRecovery on _ReportsSettingsScreenState {
  void _capture() {
    if (!_ready || _saving) return;
    _workflow?.updateInput(_draft);
  }

  Future<void> _openInput() async {
    try {
      final selected = _workflow;
      if (selected != null) {
        final owner = _saved;
        if (owner == null) throw StateError('Durable preferences unavailable.');
        owner.validateReportDisplayHandoff(selected);
      }
      final workflow =
          selected ?? await _saved?.openReportDisplayDraft(initial: _draft);
      if (!mounted) {
        await workflow?.session.close();
        return;
      }
      if (workflow == null) {
        _refresh(() => _ready = true);
        return;
      }
      _workflow = workflow;
      _draft = workflow.input;
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
    _capture();
    _refresh(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = _workflow != null
          ? await _workflow!.confirm()
          : await _saved?.applyReportDisplay(_draft);
      if (saved == false) throw StateError('Settings confirmation failed.');
      if (mounted) await finishDraftRoute(_draft);
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _error =
              'Report display settings were not applied. Your unfinished choices have been kept; retry Save.';
        });
      }
    }
  }

  Future<void> _discard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unfinished Report display settings?'),
        content: const Text(
          'Your active Report display settings stay unchanged.',
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

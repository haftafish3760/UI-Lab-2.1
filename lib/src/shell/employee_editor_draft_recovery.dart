part of 'employee_editor_screen.dart';

extension _EmployeeEditorDraftRecovery on EmployeeEditorScreenState {
  Map<String, TextEditingController> get _controllers => {
    'name': _name,
    'phone': _phone,
    'emergency': _emergency,
    'pay': _pay,
  };

  EmployeeDraftInput get _currentInput => EmployeeDraftInput(
    employeeId: _employeeId,
    baseRevision: _baseRevision,
    role: _role,
    active: _active,
    canSeeEstimates: _canSeeEstimates,
    canCreateEstimates: _canCreateEstimates,
    canApproveEstimates: _canApproveEstimates,
    canRecordExpenses: _canRecordExpenses,
    canViewCompanyReports: _canViewCompanyReports,
    name: _name.text,
    phone: _phone.text,
    emergency: _emergency.text,
    pay: _pay.text,
  );

  void _captureInput() {
    if (!_ready || _saving) return;
    _workflow?.updateInput(_currentInput);
  }

  void _changeInput(VoidCallback change) {
    _refresh(change);
    _captureInput();
  }

  Future<void> _openDraft() async {
    final directory = _directory;
    if (directory == null && widget.recoveredWorkflow != null) {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        _refresh(
          () => _error =
              'Saved input requires its directory session. It has been preserved.',
        );
      }
      return;
    }
    if (directory == null) {
      _refresh(() => _ready = true);
      return;
    }
    final permissions = directory.permissions;
    if (!permissions.canViewEmployees || !permissions.canManageEmployees) {
      _refresh(
        () => _error = 'You do not have permission to edit employee records.',
      );
      return;
    }
    DraftAutosaveSession? opening;
    try {
      if (widget.initial != null) {
        final current = directory.employees.singleWhere(
          (e) => e.id == _employeeId,
        );
        _name.text = current.name;
        _phone.text = current.phone;
        _emergency.text = current.emergencyContact;
        _pay.text = current.pay;
        _role = current.role;
        _active = current.active;
        _canSeeEstimates = current.canSeeEstimates;
        _canCreateEstimates = current.canCreateEstimates;
        _canApproveEstimates = current.canApproveEstimates;
        _canRecordExpenses = current.canRecordExpenses;
        _canViewCompanyReports = current.canViewCompanyReports;
      }
      _baseRevision = directory.employeeRevision(_employeeId);
      // One recoverable new-profile form per actor; confirmed saves consume it.
      final workflow =
          widget.recoveredWorkflow ??
          await directory.openEmployeeDraft(employeeId: widget.initial?.id);
      if (widget.recoveredWorkflow != null) {
        directory.validateEmployeeHandoff(workflow, widget.initial?.id);
      }
      opening = workflow.session;
      if (!mounted) {
        await opening.close();
        return;
      }
      final input = workflow.recoveredInput;
      if (input != null) {
        _employeeId = input.employeeId;
        _baseRevision = input.baseRevision;
        _role = input.role;
        _active = input.active;
        _canSeeEstimates = input.canSeeEstimates;
        _canCreateEstimates = input.canCreateEstimates;
        _canApproveEstimates = input.canApproveEstimates;
        _canRecordExpenses = input.canRecordExpenses;
        _canViewCompanyReports = input.canViewCompanyReports;
        _name.text = input.name;
        _phone.text = input.phone;
        _emergency.text = input.emergency;
        _pay.text = input.pay;
      }
      _workflow = workflow;
      for (final controller in _controllers.values) {
        controller.addListener(_captureInput);
      }
      _subscription = opening.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      _refresh(() => _ready = true);
      _captureInput();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      await opening?.close().catchError((Object _) {});
      if (mounted) {
        _refresh(
          () => _error =
              'Saved input could not be opened. Leave this screen and retry; the saved draft has been preserved.',
        );
      }
    }
  }

  Future<void> _confirmEmployee() async {
    _captureInput();
    _refresh(() {
      _saving = true;
      _error = null;
    });
    try {
      final workflow = _workflow;
      if (workflow == null && _directory != null) {
        throw StateError('Profile workflow unavailable.');
      }
      final employee = workflow == null
          ? _currentInput.confirmedProfile()
          : await workflow.confirm();
      if (employee == null) throw StateError('Profile save failed.');
      if (mounted) await finishDraftRoute(employee);
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _error =
              _directory?.failureMessage ??
              'Employee information was not saved. Your recovery input has been kept; retry saving.';
        });
      }
    }
  }

  Future<void> _discardDraft() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unfinished employee input?'),
        content: const Text(
          'Previously saved employee information stays unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard input'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    _refresh(() => _saving = true);
    try {
      await _draft?.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _error =
              'The recovery input could not be discarded. It has been preserved.';
        });
      }
    }
  }
}

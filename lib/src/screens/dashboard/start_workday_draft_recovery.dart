part of 'start_workday_screen.dart';

extension _StartWorkdayDraftRecovery on _StartWorkdayScreenState {
  Future<void> _openDraft() async {
    final session = WorkdayPersistenceScope.maybeOf(context);
    if (session == null) {
      if (widget.recoveredWorkflow != null) {
        await _workflow?.session.close().catchError((Object _) {});
        _workflow = null;
        if (mounted) {
          _refresh(
            () => _errorText =
                'Saved starting input requires its Workday session. It has been preserved.',
          );
        }
        return;
      }
      _refresh(() => _opening = false);
      return;
    }
    try {
      final scope = OperationalScope.of(context);
      final workflow =
          widget.recoveredWorkflow ??
          await session.openStartDraft(
            employeeId: scope.selectedEmployeeId,
            vehicleId: scope.selectedVehicleId,
            initialOdometer: formatOdometerTenths(
              session.odometerFor(scope.selectedVehicleId)!.readingTenths,
            ),
            gpsAssistance: _gpsAssistance,
          );
      if (widget.recoveredWorkflow != null) {
        session.validateStartWorkdayHandoff(workflow);
      }
      final draft = workflow.session;
      if (!mounted) {
        await draft.close();
        return;
      }
      _workflow = workflow;
      final input = workflow.input;
      scope.selectEmployee(input.employeeId);
      scope.selectVehicle(input.vehicleId);
      if (scope.selectedEmployeeId != input.employeeId ||
          scope.selectedVehicleId != input.vehicleId) {
        throw StateError('Retained input cannot be shown in this context.');
      }
      _odometerController!.text = input.odometer;
      _gpsAssistance = input.gpsAssistance;
      _odometerController!.addListener(_captureDraft);
      _draftSubscription = draft.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      _refresh(() => _opening = false);
      _captureDraft();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        _refresh(
          () => _errorText =
              'Saved workday input could not be opened. Leave and retry; retained input is preserved.',
        );
      }
    }
  }

  void _captureDraft() {
    if (_opening || _saving || !mounted) return;
    final scope = OperationalScope.of(context);
    _workflow?.update(
      employeeId: scope.selectedEmployeeId,
      vehicleId: scope.selectedVehicleId,
      odometer: _odometerController!.text,
      gpsAssistance: _gpsAssistance,
    );
  }

  Future<void> _confirmStored(StartWorkdayResult result) async {
    final draft = _draft;
    if (draft == null || _opening || _saving) return;
    final employeeId = OperationalScope.of(context).selectedEmployeeId;
    if (employeeId == null) return;
    _captureDraft();
    _refresh(() {
      _saving = true;
      _errorText = null;
    });
    try {
      final outcome = await _workflow!.confirm();
      if (!mounted) return;
      if (outcome.committed) {
        await finishDraftRoute(result);
        return;
      }
      _refresh(() {
        _saving = false;
        _errorText = outcome.message;
      });
    } on StartWorkdayInputValidation catch (error) {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _errorText = error.message;
        });
      }
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _errorText = 'Workday could not be saved. Your input is preserved.';
        });
      }
    }
  }

  Future<void> _discardDraft() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished workday input?'),
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
          _errorText = 'Unfinished input could not be discarded. Try again.';
        });
      }
    }
  }
}

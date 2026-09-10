part of 'vehicle_editor_screen.dart';

extension _VehicleEditorDraftRecovery on _VehicleEditorScreenState {
  Map<String, TextEditingController> get _controllers => {
    'name': _name,
    'model': _model,
    'odometer': _odometer,
    'assignment': _assignment,
  };
  VehicleDraftInput get _currentInput => VehicleDraftInput(
    vehicleId: _vehicleId,
    baseRevision: _baseRevision,
    odometerRevision: _odometerRevision,
    active: _active,
    name: _name.text,
    model: _model.text,
    odometer: _odometer.text,
    assignment: _assignment.text,
  );

  void _captureInput() {
    if (!_ready || _saving) return;
    _workflow?.updateInput(_currentInput);
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
    if (directory != null &&
        (!directory.permissions.canViewVehicles ||
            !directory.permissions.canManageVehicles)) {
      _refresh(
        () => _error = 'You do not have permission to edit vehicle records.',
      );
      return;
    }
    DraftAutosaveSession? opening;
    try {
      if (directory != null && !await directory.reloadVehicles()) {
        throw StateError('Vehicle directory could not be read.');
      }
      if (!mounted) return;
      final current = widget.initial == null
          ? null
          : directory == null
          ? widget.initial
          : directory.vehicles.singleWhere((v) => v.id == _vehicleId);
      _name.text = current?.name ?? '';
      _model.text = current?.yearMakeModel ?? '';
      _assignment.text = current?.assignment ?? 'Unassigned';
      _active = current?.active ?? true;
      final odometer = directory?.vehicleOdometer(_vehicleId);
      _odometer.text = odometer == null
          ? ''
          : '${odometer.readingTenths ~/ 10}.${odometer.readingTenths % 10}';
      _baseRevision = directory?.vehicleRevision(_vehicleId) ?? 0;
      _odometerRevision = odometer?.revision ?? 0;
      if (directory == null) {
        _refresh(() => _ready = true);
        return;
      }
      final workflow =
          widget.recoveredWorkflow ??
          await directory.openVehicleDraft(vehicleId: widget.initial?.id);
      if (widget.recoveredWorkflow != null) {
        directory.validateVehicleHandoff(workflow, widget.initial?.id);
      }
      opening = workflow.session;
      if (!mounted) {
        await opening.close();
        return;
      }
      final input = workflow.recoveredInput;
      if (input != null) {
        _vehicleId = input.vehicleId;
        _baseRevision = input.baseRevision;
        _odometerRevision = input.odometerRevision;
        _active = input.active;
        _name.text = input.name;
        _model.text = input.model;
        _odometer.text = input.odometer;
        _assignment.text = input.assignment;
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

  Future<void> _confirmVehicle() async {
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
      final vehicle = workflow == null
          ? _currentInput.confirmedProfile()
          : await workflow.confirm();
      if (vehicle == null) throw StateError('Profile save failed.');
      // A reload failure marks the workday cache unavailable; it must not undo
      // or retry an already committed vehicle confirmation.
      await _workday?.reload();
      if (mounted) await finishDraftRoute(vehicle);
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _error =
              _directory?.failureMessage ??
              'Vehicle information was not saved. Your recovery input has been kept; retry saving.';
        });
      }
    }
  }

  Future<void> _discardDraft() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unfinished vehicle input?'),
        content: const Text(
          'Previously saved vehicle information and mileage stay unchanged.',
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

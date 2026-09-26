part of 'work_job_editor.dart';

extension _WorkJobDraftRecovery on _WorkJobEditorState {
  Map<String, TextEditingController> get _controllers => {
    'title': _title,
    'purchaseOrderNumber': _purchaseOrder,
    'scope': _scope,
    'notes': _notes,
  };
  void _changeJobInput(VoidCallback change) {
    _refresh(change);
    _captureJobInput();
  }

  JobDraftInput get _jobInput => JobDraftInput(
    jobId: _jobId,
    number: _number,
    purchaseOrderNumber: _purchaseOrder.text,
    assignedEmployeeIds: _employeeIds,
    sourceEstimate: _sourceEstimate,
    sourceStorageRevision: _sourceStorageRevision,
    scheduledStart: _startDateTime,
    scheduledEnd: _endDateTime,
    scheduleBufferMinutes: _bufferMinutes,
    client: _client,
    location: _location,
    assignee: _assignee,
    vehicle: _vehicle,
    pricing: _pricing,
    items: _items,
    pendingLineItem: _itemDraftInput,
    title: _title.text,
    scope: _scope.text,
    notes: _notes.text,
  );

  void _captureJobInput() {
    if (!_draftReady || _saving) return;
    _workflow?.updateInput(_jobInput);
    if (mounted) _refresh(() {});
  }

  Future<void> _openJobDraft() async {
    final work = _store.workSession;
    if (work == null) {
      if (widget.recoveredWorkflow != null) {
        await _workflow?.session.close().catchError((Object _) {});
        _workflow = null;
        if (mounted) {
          _refresh(
            () => _formError =
                'The saved job requires its Work session. Saved input has been preserved.',
          );
        }
        return;
      }
      _entryInput = canonicalJson(_jobInput.toPayload());
      _refresh(() => _draftReady = true);
      return;
    }
    try {
      _entryInput = canonicalJson(_jobInput.toPayload());
      final sourceId = widget.sourceEstimate?.id;
      final workflow =
          widget.recoveredWorkflow ??
          await work.openJobDraft(sourceEstimateId: sourceId);
      if (widget.recoveredWorkflow != null) {
        work.validateJobHandoff(workflow, sourceEstimateId: sourceId);
      }
      final draft = workflow.session;
      if (!mounted) {
        await draft.close();
        return;
      }
      final recovered = workflow.recoveredInput;
      if (recovered != null) _restoreJobInput(recovered);
      _workflow = workflow;
      for (final controller in _controllers.values) {
        controller.addListener(_captureJobInput);
      }
      _draftSubscription = draft.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      _refresh(() => _draftReady = true);
      _captureJobInput();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        _refresh(
          () => _formError =
              'Saved job input could not be opened. Leave this screen and retry; saved data has been preserved.',
        );
      }
    }
  }

  void _restoreJobInput(JobDraftInput input) {
    _jobId = input.jobId;
    _number = input.number;
    _purchaseOrder.text = input.purchaseOrderNumber;
    _employeeIds = input.assignedEmployeeIds;
    _sourceEstimate = input.sourceEstimate;
    _sourceStorageRevision = input.sourceStorageRevision;
    _client = input.client;
    _location = input.location;
    _assignee = input.assignee;
    _vehicle = input.vehicle;
    _pricing = input.pricing;
    _items = input.items;
    _itemDraftInput = input.pendingLineItem;
    _title.text = input.title;
    _scope.text = input.scope;
    _notes.text = input.notes;
    _startDay = DateUtils.dateOnly(input.scheduledStart);
    _startTime = TimeOfDay.fromDateTime(input.scheduledStart);
    _endDay = DateUtils.dateOnly(input.scheduledEnd);
    _endTime = TimeOfDay.fromDateTime(input.scheduledEnd);
    _bufferMinutes = input.scheduleBufferMinutes;
  }

  Future<void> _discardJobDraft() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished job input?'),
        content: const Text(
          'Previously saved jobs and estimates stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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
          _formError =
              'Unfinished input could not be discarded. It has been preserved.';
        });
      }
    }
  }
}

part of 'estimate_editor_screen.dart';

extension _EstimateEditorPersistence on _EstimateEditorScreenState {
  Future<String> _retainEstimatePhoto(String path) =>
      _work!.retainEstimatePhoto(path, baseRecord: _baseRecord);

  Map<String, TextEditingController> get _inputControllers => {
    'title': _title,
    'purchaseOrderNumber': _purchaseOrder,
    'scope': _scope,
    'discount': _discount,
    'tax': _tax,
    'terms': _terms,
  };
  void _changeEstimateInput(VoidCallback change) {
    _refresh(change);
    _captureEstimateInput();
  }

  EstimateDraftInput get _estimateInput => EstimateDraftInput(
    creatorId: _creatorId,
    number: _number,
    purchaseOrderNumber: _purchaseOrder.text,
    baseStorageRevision: _baseStorageRevision,
    title: _title.text,
    discount: _discount.text,
    tax: _tax.text,
    terms: _terms.text,
    client: _client,
    pricing: _pricing,
    template: _template,
    createdOn: _createdOn,
    items: _items,
    baseRecord: _baseRecord,
    estimateId: _estimateId,
    scope: _scope.text,
    expiresOn: _expiresOn,
    followUpOn: _followUpOn,
    proposedServiceOn: _proposedServiceOn,
    pendingLineItems: _itemDraftInputs,
    pendingPhotos: _photoDraftInput,
    sitePhotos: _sitePhotos,
  );

  void _captureEstimateInput() {
    if (!_draftReady || _saving) return;
    _workflow?.updateInput(_estimateInput);
  }

  Future<void> _openEstimateDraft() async {
    final work = _work;
    if (work == null) {
      if (widget.recoveredWorkflow != null) {
        await _workflow?.session.close().catchError((Object _) {});
        _workflow = null;
        if (mounted) {
          _refresh(
            () => _saveError =
                'The saved estimate requires its Work session. Saved input has been preserved.',
          );
        }
        return;
      }
      _refresh(() => _draftReady = true);
      return;
    }
    try {
      if (widget.initialRecord != null) {
        _applyCurrentEstimate(work.editableEstimate(_estimateId));
      }
      _baseStorageRevision = work.storageRevisionFor(_estimateId);
      final workflow =
          widget.recoveredWorkflow ??
          await work.openEstimateDraft(
            creatorId: _creatorId,
            existingRecordId: widget.initialRecord?.id,
          );
      if (widget.recoveredWorkflow != null) {
        work.validateEstimateHandoff(
          workflow,
          creatorId: _creatorId,
          existingRecordId: widget.initialRecord?.id,
        );
      }
      final draft = workflow.session;
      if (!mounted) {
        await draft.close();
        return;
      }
      final recovered = workflow.recoveredInput;
      if (recovered != null) _restoreEstimateInput(recovered);
      _workflow = workflow;
      for (final controller in _inputControllers.values) {
        controller.addListener(_captureEstimateInput);
      }
      _draftSubscription = draft.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      _refresh(() => _draftReady = true);
      _captureEstimateInput();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        _refresh(
          () => _saveError =
              'The estimate or its saved input could not be opened. Leave this screen and retry; saved data has been preserved.',
        );
      }
    }
  }

  void _applyCurrentEstimate(WorkRecord record) {
    _baseRecord = record;
    _number = record.number;
    _purchaseOrder.text = record.purchaseOrderNumber;
    _creatorId = record.createdByEmployeeId;
    _title.text = record.title;
    _scope.text = record.detail;
    _discount.text = record.discount.toStringAsFixed(2);
    _tax.text = record.tax.toStringAsFixed(2);
    _terms.text = record.terms;
    _createdOn =
        record.estimateDates?.createdOn ??
        record.createdOn ??
        widget.initialDay;
    _expiresOn =
        record.estimateDates?.expiresOn ??
        _createdOn.add(const Duration(days: 30));
    _followUpOn = record.estimateDates?.followUpOn;
    _proposedServiceOn = record.estimateDates?.proposedServiceOn;
    _client = record.client;
    _pricing = record.pricing;
    _template = record.template;
    _items = [...record.items];
    _sitePhotos = [...record.sitePhotos];
  }

  void _restoreEstimateInput(EstimateDraftInput input) {
    _creatorId = input.creatorId;
    _number = input.number;
    _purchaseOrder.text = input.purchaseOrderNumber;
    _baseStorageRevision = input.baseStorageRevision;
    _title.text = input.title;
    _discount.text = input.discount;
    _tax.text = input.tax;
    _terms.text = input.terms;
    _client = input.client;
    _pricing = input.pricing;
    _template = input.template;
    _createdOn = input.createdOn;
    _items = input.items;
    _baseRecord = input.baseRecord;
    _estimateId = input.estimateId;
    _scope.text = input.scope;
    _expiresOn = input.expiresOn;
    _followUpOn = input.followUpOn;
    _proposedServiceOn = input.proposedServiceOn;
    _itemDraftInputs = input.pendingLineItems;
    _photoDraftInput = input.pendingPhotos;
    _sitePhotos = input.sitePhotos;
  }

  Future<void> _confirmEstimate() async {
    _captureEstimateInput();
    _refresh(() => _saving = true);
    try {
      final WorkRecord? estimate;
      if (_work == null) {
        estimate = buildConfirmedEstimate(_estimateInput, now: DateTime.now());
      } else {
        final workflow = _workflow;
        if (workflow == null) {
          throw StateError('Estimate workflow is unavailable.');
        }
        estimate = await workflow.confirm();
      }
      if (estimate == null) throw StateError('Estimate was not saved.');
      if (mounted) await finishDraftRoute(estimate);
    } on EstimateInputValidation catch (error) {
      if (mounted) {
        _refresh(() => _saving = false);
        _message(error.message);
      }
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _saveError =
              _work?.failureMessage ??
              'The estimate was not saved. Your recovery input has been kept; retry saving.';
        });
      }
    }
  }

  Future<void> _discardEstimateDraft() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unfinished estimate input?'),
        content: const Text(
          'Previously saved estimates and their approvals stay unchanged.',
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
          _saveError =
              'The recovery input could not be discarded. It has been preserved.';
        });
      }
    }
  }
}

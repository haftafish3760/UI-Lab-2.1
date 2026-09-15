part of 'invoice_editor_screen.dart';

extension _InvoiceEditorPersistence on _InvoiceEditorScreenState {
  void _updateInput(VoidCallback change) {
    _refresh(change);
    _captureDraft();
  }

  InvoiceDraftInput _draftInput() => InvoiceDraftInput(
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
    existingRecordId: widget.initialRecord?.id,
    recordId: _recordId,
    summary: _summary.text,
    issuedOn: _issuedOn,
    dueOn: _dueOn,
    sourceJobId: _sourceJobId,
    location: _location,
    paymentMethod: _paymentMethod,
    pendingLineItem: _itemDraftInput,
  );

  void _captureDraft() {
    if (!_draftReady || _submitting) return;
    _workflow?.updateInput(_draftInput());
  }

  Future<void> _openDraft() async {
    final work = _store.workSession;
    if (work == null) {
      if (widget.recoveredWorkflow != null) {
        await _workflow?.session.close().catchError((Object _) {});
        _workflow = null;
        if (mounted) {
          _refresh(
            () => _formError =
                'The saved invoice requires its Work session. Saved input has been preserved.',
          );
        }
        return;
      }
      _refresh(() => _draftReady = true);
      return;
    }
    try {
      _baseStorageRevision = work.storageRevisionFor(_recordId);
      final workflow =
          widget.recoveredWorkflow ??
          await work.openInvoiceDraft(
            existingRecordId: widget.initialRecord?.id,
          );
      if (widget.recoveredWorkflow != null) {
        work.validateInvoiceHandoff(
          workflow,
          existingRecordId: widget.initialRecord?.id,
        );
      }
      final draft = workflow.session;
      if (!mounted) {
        await draft.close();
        return;
      }
      final recovered = workflow.recoveredInput;
      if (recovered != null) _restoreDraft(recovered);
      _workflow = workflow;
      _draftSubscription = draft.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      _refresh(() => _draftReady = true);
      _captureDraft();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        _refresh(
          () => _formError =
              'Saved input could not be opened. Leave this screen and retry; the saved draft has been preserved.',
        );
      }
    }
  }

  void _restoreDraft(InvoiceDraftInput input) {
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
    _recordId = input.recordId;
    _summary.text = input.summary;
    _issuedOn = input.issuedOn;
    _dueOn = input.dueOn;
    _sourceJobId = input.sourceJobId;
    _location = input.location;
    _paymentMethod = input.paymentMethod;
    _itemDraftInput = input.pendingLineItem;
  }

  Future<void> _leaveEditor() async {
    if (_submitting) return;
    _refresh(() => _submitting = true);
    try {
      await _draft?.flush();
      if (mounted) await _popEditor();
    } on Object {
      if (mounted) {
        _refresh(() {
          _submitting = false;
          _formError =
              'Your latest input has not been saved. Retry saving before leaving.';
        });
      }
    }
  }

  Future<void> _popEditor([WorkRecord? record]) async {
    _refresh(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(record);
  }

  Future<void> _discardDraft() async {
    if (_submitting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unfinished input?'),
        content: const Text(
          'This removes this recovery draft. Previously saved invoice records stay unchanged.',
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
    if (!mounted || confirmed != true) return;
    _refresh(() => _submitting = true);
    try {
      await _draft?.discard();
      if (mounted) await _popEditor();
    } on Object {
      if (mounted) {
        _refresh(() {
          _submitting = false;
          _formError =
              'The unfinished input could not be discarded. It has been preserved.';
        });
      }
    }
  }

  Future<void> _confirmDraft() async {
    _captureDraft();
    _refresh(() => _submitting = true);
    try {
      final WorkRecord? record;
      if (_store.workSession == null) {
        record = buildConfirmedInvoice(
          _draftInput(),
          existing: widget.initialRecord,
        );
      } else {
        final workflow = _workflow;
        if (workflow == null) {
          throw StateError('Invoice workflow is unavailable.');
        }
        record = await workflow.confirm();
      }
      if (record == null) throw StateError('The invoice was not saved.');
      if (mounted) await _popEditor(record);
    } on InvoiceInputValidation catch (error) {
      if (mounted) {
        _refresh(() {
          _submitting = false;
          _formError = error.message;
        });
      }
    } on Object {
      if (mounted) {
        _refresh(() {
          _submitting = false;
          _formError =
              _store.workSession?.failureMessage ??
              'The invoice was not saved. Your recovery draft has been kept; retry saving.';
        });
      }
    }
  }
}

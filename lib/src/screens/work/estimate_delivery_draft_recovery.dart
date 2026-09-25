// ignore_for_file: invalid_use_of_protected_member

part of 'estimate_delivery_screen.dart';

extension _DeliveryRecovery on _EstimateDeliveryScreenState {
  Future<void> _openDeliveryDraft() async {
    try {
      _work = PrototypeOperationsScope.maybeOf(context)?.workSession;
      final work = _work;
      final customers =
          PrototypeOperationsScope.maybeOf(context)?.customers ??
          const <WorkCustomerProfile>[];
      if (work == null && widget.recoveredWorkflow != null) {
        throw StateError('Recovered input requires its Work session.');
      }
      if (work != null) {
        final workflow =
            widget.recoveredWorkflow ??
            await work.openEstimateDeliveryDraft(
              widget.record.id,
              customers: customers,
            );
        if (widget.recoveredWorkflow != null) {
          work.validateEstimateDeliveryHandoff(workflow, widget.record.id);
        }
        if (!mounted) {
          await workflow.session.close();
          return;
        }
        _workflow = workflow;
        _subscription = workflow.session.changes.listen((_) {
          if (mounted) setState(() {});
        });
      } else {
        _previewInput = EstimateDeliveryInput.initial(
          widget.record,
          baseRevision: 0,
          customers: customers,
        );
      }
      final input = _workflow?.input ?? _previewInput!;
      _base = input.base;
      _method = input.method;
      _recipient.text = input.recipient;
      _reviewed = input.reviewed;
      if (!mounted) return;
      _recipient.addListener(_recipientChanged);
      setState(() => _ready = true);
      _captureDelivery();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        setState(
          () => _error =
              'Saved delivery could not be opened. Its input has been preserved.',
        );
      }
    }
  }

  void _recipientChanged() {
    if (_bindingRecipient || !_ready || _saving || _preparedRecord != null) {
      return;
    }
    if (_workflow != null) {
      _workflow!.updateRecipient(_recipient.text);
    } else {
      _previewInput = _previewInput!.withRecipient(_recipient.text);
    }
    setState(() => _reviewed = false);
  }

  void _captureDelivery() {
    if (!_ready || _saving || _preparedRecord != null) return;
    if (_workflow != null) {
      _workflow!.setReviewed(_reviewed);
    } else {
      _previewInput = _previewInput!.withReviewed(_reviewed);
    }
  }

  Future<void> _confirm() async {
    if (!_ready || _saving || !_reviewed) return;
    if (_recipient.text.trim().isEmpty) {
      setState(() => _error = 'Enter or confirm the recipient.');
      return;
    }
    _captureDelivery();
    setState(() => _saving = true);
    try {
      WorkRecord? record = _preparedRecord;
      if (record != null) {
        // A native export retry reuses the already saved preparation.
      } else if (_workflow != null) {
        record = await _workflow!.confirm();
      } else {
        _previewInput = _previewInput!.prepare();
        record = _previewInput!.confirmedRecord();
      }
      if (record == null) {
        throw StateError(
          _work?.failureMessage ?? 'Delivery preparation was not saved.',
        );
      }
      _preparedRecord = record;
      if (mounted) {
        await deliverWorkPdf(
          context,
          record,
          switch (_method) {
            EstimateDeliveryMethod.print => WorkPdfAction.print,
            EstimateDeliveryMethod.savedPdf => WorkPdfAction.save,
            _ => WorkPdfAction.share,
          },
          recipient: _recipient.text,
          composeMethod: switch (_method) {
            EstimateDeliveryMethod.email => 'email',
            EstimateDeliveryMethod.textMessage => 'textMessage',
            _ => null,
          },
        );
        if (mounted) await finishDraftRoute(record);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is StateError
              ? error.message.toString()
              : _preparedRecord != null
              ? 'The sharing app could not open. Your estimate is saved; try again.'
              : 'Delivery preparation was not saved. Your input is retained.';
        });
      }
    }
  }

  Future<void> _discardDelivery() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished delivery?'),
        content: const Text(
          'The saved estimate and delivery history stay unchanged.',
        ),
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
    setState(() => _saving = true);
    try {
      await _draft?.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Delivery input could not be discarded. It has been preserved.';
        });
      }
    }
  }
}

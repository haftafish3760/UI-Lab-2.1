part of 'invoice_payment_entry_screen.dart';

extension _InvoicePaymentDraftRecovery on _InvoicePaymentEntryScreenState {
  void _capturePaymentInput() {
    if (!_draftReady || _saving) return;
    final current = _workflow?.input ?? _previewInput;
    if (current == null) return;
    final input = current.withValues(
      amount: _amount.text,
      note: _note.text,
      method: _method,
      receivedOn: _receivedOn,
    );
    if (_workflow != null) {
      _workflow!.updateInput(input);
    } else {
      _previewInput = input;
    }
  }

  void _changePaymentInput(VoidCallback change) {
    _refresh(change);
    _capturePaymentInput();
  }

  Future<void> _openPaymentDraft() async {
    final work = _work;
    if (work == null) {
      if (widget.recoveredWorkflow != null) {
        await _workflow?.session.close().catchError((Object _) {});
        _workflow = null;
        if (mounted) {
          _refresh(
            () => _error =
                'The saved payment requires its Work session. Saved input has been preserved.',
          );
        }
        return;
      }
      _previewInput = InvoicePaymentInput.initial(
        invoiceId: widget.invoice.id,
        balanceCents: widget.balanceCents,
        day: widget.initialDay,
      );
      _refresh(() => _draftReady = true);
      return;
    }
    try {
      final workflow =
          widget.recoveredWorkflow ??
          await work.openInvoicePaymentDraft(
            invoiceId: widget.invoice.id,
            initialDay: widget.initialDay,
          );
      if (widget.recoveredWorkflow != null) {
        work.validateInvoicePaymentHandoff(
          workflow,
          invoiceId: widget.invoice.id,
        );
      }
      if (!mounted) {
        await workflow.session.close();
        return;
      }
      _workflow = workflow;
      final input = workflow.input;
      _amount.text = input.amount;
      _note.text = input.note;
      _method = input.method;
      _receivedOn = input.receivedOn;
      final draft = workflow.session;
      _amount.addListener(_capturePaymentInput);
      _note.addListener(_capturePaymentInput);
      _draftSubscription = draft.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      _refresh(() => _draftReady = true);
      _capturePaymentInput();
    } on InvoicePaymentInputValidation catch (error) {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) _refresh(() => _error = error.message);
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        _refresh(
          () => _error =
              'Saved input could not be opened. Leave this screen and retry; the saved draft has been preserved.',
        );
      }
    }
  }

  Future<void> _confirmPayment() async {
    _capturePaymentInput();
    _refresh(() => _saving = true);
    try {
      final payment = _workflow != null
          ? await _workflow!.confirm()
          : _previewInput!.confirmedPayment(
              invoice: widget.invoice,
              balanceCents: widget.balanceCents,
            );
      if (payment == null) throw StateError('Payment was not saved.');
      if (mounted) await finishDraftRoute(payment);
    } on InvoicePaymentInputValidation catch (error) {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _error = error.message;
        });
      }
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _error =
              _work?.failureMessage ??
              'Payment was not saved. Your recovery input has been kept; retry saving.';
        });
      }
    }
  }

  Future<void> _discardPaymentDraft() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unfinished payment input?'),
        content: const Text(
          'Previously saved payments and invoice balances stay unchanged.',
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

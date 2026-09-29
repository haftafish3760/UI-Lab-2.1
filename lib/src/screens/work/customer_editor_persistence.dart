part of 'customer_edit_screen.dart';

extension _CustomerEditorPersistence on CustomerEditScreenState {
  Map<String, TextEditingController> get _inputControllers => {
    'name': _name,
    'company': _company,
    'phone': _phone,
    'email': _email,
    'billing': _billing,
    'notes': _notes,
    'locationLabel': _locationLabel,
    'locationAddress': _locationAddress,
    'accessNotes': _accessNotes,
  };

  CustomerDraftInput get _customerInput => CustomerDraftInput(
    customerId: _customerId,
    existingCustomer: _editingCustomer,
    baseRevision: _baseRevision,
    preferredContact: _preferredContact,
    name: _name.text,
    company: _company.text,
    phone: _phone.text,
    email: _email.text,
    billing: _billing.text,
    notes: _notes.text,
    locationLabel: _locationLabel.text,
    locationAddress: _locationAddress.text,
    accessNotes: _accessNotes.text,
  );

  void _captureCustomerInput() {
    if (!_draftReady || _saving) return;
    // Merely opening an empty form is not unfinished customer work. Once a
    // draft has input, persist subsequent clearing as well; never resurrect it.
    if (_editingCustomer == null &&
        (_draft?.input.isEmpty ?? true) &&
        _inputControllers.values.every((value) => value.text.trim().isEmpty) &&
        _preferredContact == 'Phone call') {
      return;
    }
    _workflow?.updateInput(_customerInput);
  }

  void _changeCustomerInput(VoidCallback change) {
    _refresh(change);
    _captureCustomerInput();
  }

  Future<void> _openCustomerDraft() async {
    final directory = _directory;
    if (directory == null && widget.recoveredWorkflow != null) {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        _refresh(
          () => _saveError =
              'Saved input requires its directory session. It has been preserved.',
        );
      }
      return;
    }
    if (directory == null) {
      _refresh(() => _draftReady = true);
      return;
    }
    final permissions = directory.permissions;
    if (!permissions.canViewCustomers || !permissions.canManageCustomers) {
      _refresh(
        () => _saveError = 'You do not have permission to edit customers.',
      );
      return;
    }
    try {
      final id = widget.initialCustomer?.id;
      if (id != null) {
        final current = directory.customers
            .where((value) => value.id == id)
            .firstOrNull;
        if (current == null) throw StateError('Customer is unavailable.');
        _recoveredCustomer = current;
        final location = current.locations.firstOrNull;
        final values = {
          'name': current.name,
          'company': current.companyName,
          'phone': current.phone,
          'email': current.email,
          'billing': current.billingAddress,
          'notes': current.notes,
          'locationLabel': location?.label ?? 'Primary service location',
          'locationAddress': location?.address ?? '',
          'accessNotes': location?.accessNotes ?? '',
        };
        for (final entry in _inputControllers.entries) {
          entry.value.text = values[entry.key]!;
        }
        _preferredContact = current.preferredContact;
      }
      _baseRevision = directory.customerRevision(_customerId);
      String? recoveryId;
      if (!widget.embedded &&
          widget.initialCustomer == null &&
          widget.recoveredWorkflow == null) {
        final candidates = await directory.customerDraftRecovery.list();
        if (!mounted) return;
        if (candidates.isNotEmpty) {
          final chosen = await showDialog<String>(
            context: context,
            builder: (dialogContext) => SimpleDialog(
              title: const Text('Continue an unfinished client?'),
              children: [
                for (final row in candidates)
                  SimpleDialogOption(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(row.draftId),
                    child: Text(row.label),
                  ),
                SimpleDialogOption(
                  onPressed: () => Navigator.of(dialogContext).pop('new'),
                  child: const Text('Start another client'),
                ),
              ],
            ),
          );
          if (!mounted) return;
          if (chosen == null) {
            if (widget.embedded) {
              widget.onCancelled?.call();
            } else {
              await leaveDraftRoute();
            }
            return;
          }
          if (chosen != 'new') recoveryId = chosen;
        }
      }
      final workflow =
          widget.recoveredWorkflow ??
          await directory.openCustomerDraft(
            existingCustomerId: widget.initialCustomer?.id,
            recoveryDraftId: recoveryId,
          );
      if (widget.recoveredWorkflow != null) {
        directory.validateCustomerHandoff(workflow, widget.initialCustomer?.id);
      }
      final draft = workflow.session;
      if (!mounted) {
        await draft.close();
        return;
      }
      final input = workflow.recoveredInput;
      if (input != null) {
        _customerId = input.customerId;
        _recoveredCustomer = input.existingCustomer;
        _baseRevision = input.baseRevision;
        _preferredContact = input.preferredContact;
        _name.text = input.name;
        _company.text = input.company;
        _phone.text = input.phone;
        _email.text = input.email;
        _billing.text = input.billing;
        _notes.text = input.notes;
        _locationLabel.text = input.locationLabel;
        _locationAddress.text = input.locationAddress;
        _accessNotes.text = input.accessNotes;
      }
      _workflow = workflow;
      for (final controller in _inputControllers.values) {
        controller.addListener(_captureCustomerInput);
      }
      _draftSubscription = draft.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      _refresh(() => _draftReady = true);
      _captureCustomerInput();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        _refresh(
          () => _saveError =
              'Saved input could not be opened. Leave this screen and retry; the saved draft has been preserved.',
        );
      }
    }
  }

  Future<void> _confirmCustomer() async {
    final phoneDigits = UsPhoneInputFormatter.digits(_phone.text);
    if (phoneDigits.isNotEmpty && phoneDigits.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter the 10-digit phone number, including area code.',
          ),
        ),
      );
      return;
    }

    bool saveToDirectory = true;
    if (widget.offerEstimateOnly && _editingCustomer == null) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Save as a new client?'),
          content: const Text(
            'Keep this customer in your client list for future work, or use their information only for this estimate.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('This estimate only'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Save new client'),
            ),
          ],
        ),
      );
      if (!mounted || choice == null) return;
      saveToDirectory = choice;
    }
    _captureCustomerInput();
    _refresh(() => _saving = true);
    try {
      final WorkCustomerProfile? customer;
      if (_directory == null || !saveToDirectory) {
        customer = buildConfirmedCustomer(_customerInput);
        if (saveToDirectory) {
          final store = PrototypeOperationsScope.of(context);
          await store.replaceCustomers([
            ...store.customers.where((entry) => entry.id != customer!.id),
            customer,
          ]);
        }
        // Keep the recovery copy until the estimate itself is durably saved.
        await _draft?.flush();
      } else {
        final workflow = _workflow;
        if (workflow == null) {
          throw StateError('Client workflow is unavailable.');
        }
        customer = await workflow.confirm();
      }
      if (customer == null) throw StateError('Client save failed.');
      if (mounted) {
        if (widget.embedded) {
          await widget.onSaved?.call(customer);
        } else {
          await finishDraftRoute(customer);
        }
      }
    } on CustomerInputValidation catch (error) {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _nameError = error.message;
        });
      }
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _saveError =
              _directory?.failureMessage ??
              'The client was not saved. Your recovery input has been kept; retry saving.';
        });
      }
    }
  }

  Future<void> _discardCustomerDraft() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unfinished client input?'),
        content: const Text(
          'Previously saved client information stays unchanged.',
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
      if (!mounted) return;
      await finishDraftRoute();
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

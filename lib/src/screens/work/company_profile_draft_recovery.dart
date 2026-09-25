part of 'company_profile_editor.dart';

extension _CompanyProfileDraftRecovery on _CompanyProfileEditScreenState {
  Map<String, TextEditingController> get _inputControllers => {
    'name': _name,
    'category': _category,
    'phone': _phone,
    'email': _email,
    'website': _website,
    'street': _street,
    'unit': _unit,
    'city': _city,
    'state': _state,
    'zip': _zip,
    'terms': _terms,
  };

  CompanyDraftInput get _currentInput => CompanyDraftInput(
    baseProfile: _editingProfile,
    baseRevision: _baseRevision,
    logoLabel: _logoLabel,
    logoReference: _logoReference,
    name: _name.text,
    category: _category.text,
    phone: _phone.text,
    email: _email.text,
    website: _website.text,
    address: _addressChanged
        ? _companyAddress.formatted
        : _editingProfile.address,
    addressParts: _companyAddress.toMap(),
    terms: _terms.text,
  );

  void _captureCompanyInput() {
    if (!_draftReady || _saving) return;
    if (_hasCompanyChanges || (_draft?.input.isNotEmpty ?? false)) {
      _workflow?.updateInput(_currentInput);
    }
    if (mounted) _refresh(() {});
  }

  void _changeCompanyInput(VoidCallback change) {
    _refresh(change);
    _captureCompanyInput();
  }

  Future<void> _openCompanyDraft() async {
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
      for (final controller in _inputControllers.values) {
        controller.addListener(_captureCompanyInput);
      }
      _refresh(() => _draftReady = true);
      return;
    }
    final permissions = directory.permissions;
    if (!permissions.canViewCompany || !permissions.canManageCompany) {
      _refresh(
        () => _saveError =
            'You do not have permission to edit company information.',
      );
      return;
    }
    try {
      _draftBaseProfile = directory.company;
      final workflow =
          widget.recoveredWorkflow ?? await directory.openCompanyDraft();
      if (widget.recoveredWorkflow != null) {
        directory.validateCompanyHandoff(workflow);
      }
      final draft = workflow.session;
      if (!mounted) {
        await draft.close();
        return;
      }
      final input = workflow.recoveredInput;
      if (input != null) {
        _draftBaseProfile = input.baseProfile;
        _baseRevision = input.baseRevision;
        _logoLabel = input.logoLabel;
        _logoReference = input.logoReference;
        _name.text = input.name;
        _category.text = input.category;
        _phone.text = input.phone;
        _email.text = input.email;
        _website.text = input.website;
        final address = input.addressParts.isEmpty
            ? CompanyAddress.fromLegacy(input.address)
            : CompanyAddress.fromMap(input.addressParts);
        _street.text = address.street;
        _unit.text = address.unit;
        _city.text = address.city;
        _state.text = address.state;
        _zip.text = address.zip;
        _legacyAddress = address.legacy;
        _terms.text = input.terms;
      }
      _workflow = workflow;
      for (final controller in _inputControllers.values) {
        controller.addListener(_captureCompanyInput);
      }
      _draftSubscription = draft.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      _refresh(() => _draftReady = true);
      _captureCompanyInput();
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

  Future<void> _confirmCompany() async {
    _refresh(() {
      _saving = true;
      _saveError = null;
    });
    try {
      _workflow?.updateInput(_currentInput);
      final workflow = _workflow;
      if (workflow == null && _directory != null) {
        throw StateError('Profile workflow unavailable.');
      }
      final company = workflow == null
          ? _currentInput.confirmedProfile()
          : await workflow.confirm();
      if (company == null) throw StateError('Profile save failed.');
      if (mounted) await finishDraftRoute(company);
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _saveError =
              _directory?.failureMessage ??
              'Company information was not saved. Your recovery input has been kept; retry saving.';
        });
      }
    }
  }
}

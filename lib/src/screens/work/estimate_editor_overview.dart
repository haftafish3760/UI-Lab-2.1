part of 'estimate_editor_screen.dart';

extension _EstimateEditorOverview on _EstimateEditorScreenState {
  Widget _buildOverview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_approving)
        const Text(
          'Customer approval — review the estimate below before accepting.',
        ),
      EstimateDocumentHeading(
        number: _number,
        onEditCompany:
            _approving ||
                PrototypeOperationsScope.of(
                      context,
                    ).directorySession?.permissions.canManageCompany !=
                    true
            ? null
            : _editDocumentCompany,
        status:
            'Estimate status: ${_baseRecord?.resolvedEstimateStage.label ?? 'Draft'}',
      ),
      AbsorbPointer(
        absorbing: _approving,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EstimateFormSection(
              key: const ValueKey('estimate-information'),
              title: 'Estimate details',
              onEdit: () => _openSectionEditor(
                'Estimate details',
                () => _identity(customerOnly: false),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_title.text.trim().isNotEmpty &&
                      _title.text != 'Untitled estimate')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_title.text),
                    ),
                  Text('Document number: $_number'),
                  const SizedBox(height: 10),
                  Text(
                    'Purchase order number: ${_purchaseOrder.text.trim().isEmpty ? 'Not provided' : _purchaseOrder.text}',
                  ),
                ],
              ),
            ),
            EstimateFormSection(
              key: const ValueKey('estimate-customer'),
              title: 'Prepared for',
              actionLabel: _client == null || _client == 'Client not selected'
                  ? 'Add customer'
                  : 'Edit',
              onEdit: () => _openSectionEditor(
                'Client information',
                () => _identity(customerOnly: true),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _client == null || _client == 'Client not selected'
                        ? 'Add the customer who will receive this estimate.'
                        : _client!,
                  ),
                  if (_customerSnapshot case final customer?)
                    for (final detail in [
                      customer.companyName,
                      customer.phone,
                      customer.email,
                      customer.billingAddress,
                    ])
                      if (detail.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(detail),
                        ),
                ],
              ),
            ),
            EstimateFormSection(
              key: const ValueKey('estimate-dates'),
              title: 'Dates and validity',
              onEdit: () =>
                  _openSectionEditor('Dates and validity', _timingEditor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DateRow(label: 'Created', value: _date(context, _createdOn)),
                  _DateRow(
                    label: 'Date finished',
                    value: _finishedOn == null
                        ? 'Not finished'
                        : _date(context, _finishedOn!),
                  ),
                  _DateRow(
                    label: 'Sent to customer',
                    value: _sentOn == null
                        ? 'Not recorded'
                        : _date(context, _sentOn!),
                  ),
                  _DateRow(
                    label: 'Price validity',
                    value: _validityDescription,
                  ),
                  _DateRow(
                    label: 'Follow up',
                    value: _followUpOn == null
                        ? 'Not set'
                        : _date(context, _followUpOn!),
                  ),
                  const SizedBox(height: 12),
                  const Text('Proposed service dates and times'),
                  if (_proposedServiceDates.isEmpty)
                    const Text('No dates proposed.'),
                  for (final date in _proposedServiceDates)
                    Text(
                      '${_date(context, date)} at ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
                    ),
                ],
              ),
            ),
            EstimateFormSection(
              key: const ValueKey('estimate-work'),
              title: 'Description of work',
              onEdit: () => _openSectionEditor(
                'Work description',
                () => EstimateFormField(
                  inputKey: const ValueKey('estimate-work-description'),
                  label: 'Work to be completed',
                  controller: _scope,
                  multiline: true,
                  hint: 'Describe the work to be completed.',
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _scope.text.trim().isEmpty
                        ? 'No work description added.'
                        : _scope.text,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _sitePhotos.isEmpty
                        ? 'No photos attached.'
                        : '${_sitePhotos.length} photos attached',
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      key: const ValueKey('estimate-site-photos'),
                      onPressed: _editSitePhotos,
                      child: const Text('Add or view photos'),
                    ),
                  ),
                ],
              ),
            ),
            EstimateFormSection(
              key: const ValueKey('estimate-items'),
              title: 'Labor, materials and pricing',
              onEdit: () => _editItemCategory(EstimateItemCategory.all, _items),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_items.isEmpty ||
                      canUseEstimateServicePrice(_estimateId, _items))
                    const Text(
                      'Individual items are optional. You can enter one price below.',
                    )
                  else ...[
                    EstimateDocumentItems(
                      items: _items
                          .where(
                            (item) => item.type != WorkLineItemType.material,
                          )
                          .toList(),
                    ),
                    EstimateMaterialsPanel(
                      items: _items
                          .where(
                            (item) => item.type == WorkLineItemType.material,
                          )
                          .toList(),
                      onEdit: () =>
                          _editItemCategory(EstimateItemCategory.all, _items),
                    ),
                  ],
                  const SizedBox(height: 12),
                  EstimatePriceSummary(
                    key: const ValueKey('estimate-price-summary'),
                    grouped: true,
                    subtotal: _currency(_subtotal),
                    discount: _currency(_money(_discount)),
                    tax: _currency(_money(_tax)),
                    total: _currency(_total),
                    onEdit: () => _openSectionEditor(
                      'Price summary',
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (canUseEstimateServicePrice(_estimateId, _items))
                            EstimateFormField(
                              inputKey: const ValueKey(
                                'estimate-service-price',
                              ),
                              label: context.l10n.workPriceBeforeAdjustments,
                              controller: _servicePrice,
                              money: true,
                            ),
                          EstimateFormField(
                            inputKey: const ValueKey('estimate-discount-input'),
                            label: 'Discount',
                            controller: _discount,
                            money: true,
                          ),
                          EstimateFormField(
                            label: 'Tax',
                            controller: _tax,
                            money: true,
                          ),
                          Text('Estimate total: ${_currency(_total)}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            EstimateFormSection(
              key: const ValueKey('estimate-terms'),
              title: 'Terms and conditions',
              onEdit: () =>
                  _openSectionEditor('Terms and conditions', _termsEditor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _terms.text.trim().isEmpty
                        ? 'No terms selected. Use Edit to add terms.'
                        : _terms.text,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _requiresDeposit
                        ? 'Required deposit: ${_currency(_money(_deposit))}'
                        : 'No deposit required',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      _buildInlineApproval(),
    ],
  );

  Future<void> _editDocumentCompany() async {
    final store = PrototypeOperationsScope.of(context);
    final directory = store.directorySession;
    if (directory == null || !directory.permissions.canManageCompany) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CompanyProfileEditScreen(
          initialProfile: directory.company,
          selectedDay: _createdOn,
        ),
      ),
    );
    if (mounted) _refresh(() {});
  }

  Widget _timingEditor() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _DateRow(
        label: 'Created',
        value: _date(context, _createdOn),
        onTap: () => _pickDate(_createdOn, (value) => _createdOn = value),
      ),
      _DateRow(
        label: 'Date finished',
        value: _finishedOn == null
            ? 'Not finished'
            : _date(context, _finishedOn!),
        onTap: () => _pickDate(
          _finishedOn ?? DateTime.now(),
          (value) => _finishedOn = value,
        ),
      ),
      const SizedBox(height: 16),
      _DateRow(
        label: 'Date sent to customer',
        value: _sentOn == null ? 'Not recorded' : _date(context, _sentOn!),
        onTap: () =>
            _pickDate(_sentOn ?? DateTime.now(), (value) => _sentOn = value),
      ),
      const Text(
        'Record the date you actually sent this estimate. This does not confirm customer receipt or approval. Price validity starts on this date.',
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        key: ValueKey(
          'estimate-validity-$_validityDays-$_validityPickerVersion',
        ),
        initialValue: [7, 30, 90, 365].contains(_validityDays)
            ? _validityDays
            : _validityDays == null
            ? null
            : -1,
        decoration: const InputDecoration(labelText: 'Choose validity period'),
        items: const [
          DropdownMenuItem(value: 7, child: Text('7 days')),
          DropdownMenuItem(value: 30, child: Text('30 days')),
          DropdownMenuItem(value: 90, child: Text('90 days')),
          DropdownMenuItem(value: 365, child: Text('One year (365 days)')),
          DropdownMenuItem(value: -1, child: Text('Custom')),
        ],
        onChanged: (days) async {
          if (days == -1) {
            await _chooseCustomValidity();
            if (mounted) _refresh(() => _validityPickerVersion++);
            return;
          }
          _changeEstimateInput(() {
            _validityDays = days;
            _expiresOn = null;
          });
        },
      ),
      const SizedBox(height: 12),
      Text(_validityDescription),
      _DateRow(
        label: 'Follow up',
        value: _followUpOn == null ? 'Not set' : _date(context, _followUpOn!),
        onTap: () => _pickDate(
          _followUpOn ?? _createdOn,
          (value) => _followUpOn = value,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Proposed service dates and times',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      const Text(
        'Offer the customer available options. These do not book a job.',
      ),
      if (_proposedServiceDates.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('No dates proposed.'),
        ),
      for (var i = 0; i < _proposedServiceDates.length; i++)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              '${_date(context, _proposedServiceDates[i])} at ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_proposedServiceDates[i]))}',
            ),
            TextButton(
              onPressed: () => _editServiceOption(i),
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () => _changeEstimateInput(() {
                _proposedServiceDates.removeAt(i);
                _proposedServiceOn = _proposedServiceDates.firstOrNull;
              }),
              child: const Text('Remove'),
            ),
          ],
        ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton(
          onPressed: () => _editServiceOption(null),
          child: const Text('Add proposed date and time'),
        ),
      ),
    ],
  );

  Future<void> _editServiceOption(int? index) async {
    final initial = index == null
        ? DateTime.now()
        : _proposedServiceDates[index];
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _createdOn.subtract(const Duration(days: 365)),
      lastDate: _createdOn.add(const Duration(days: 3650)),
    );
    if (!mounted || day == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: index == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay.fromDateTime(initial),
    );
    if (!mounted || time == null) return;
    final chosen = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );
    if (_proposedServiceDates.indexed.any(
      (entry) => entry.$1 != index && entry.$2 == chosen,
    )) {
      _message('That date and time is already listed.');
      return;
    }
    _changeEstimateInput(() {
      if (index == null) {
        _proposedServiceDates.add(chosen);
      } else {
        _proposedServiceDates[index] = chosen;
      }
      _proposedServiceDates.sort();
      _proposedServiceOn = _proposedServiceDates.firstOrNull;
    });
  }

  Widget _termsEditor() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Require a deposit'),
        subtitle: const Text(
          'Include a deposit requirement in this estimate. This does not record a payment.',
        ),
        value: _requiresDeposit,
        onChanged: (value) =>
            _changeEstimateInput(() => _requiresDeposit = value),
      ),
      if (_requiresDeposit)
        DocumentAmountField(
          label: 'Required deposit amount',
          controller: _deposit,
        ),
      const SizedBox(height: 20),
      EstimateTermsEditor(controller: _terms),
    ],
  );

  Widget _identity({required bool customerOnly}) {
    if (!customerOnly) {
      return _EstimateIdentitySection(
        number: _number,
        canEditNumber: widget.initialRecord == null,
        onNumberChanged: (value) => _changeEstimateInput(() => _number = value),
        title: _title,
        purchaseOrder: _purchaseOrder,
      );
    }
    return EstimateClientInformation(
      key: _clientInformation,
      selectedDay: _createdOn,
      selectedClient: _customerSnapshot,
      onSelected: (customer) => _changeEstimateInput(() {
        _client = customer.name;
        _customerSnapshot = customer;
      }),
    );
  }

  Future<bool> _openSectionEditor(
    String title,
    Widget Function() content, {
    bool fromReview = false,
  }) async {
    var saved = false;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DocumentSectionEditor(
          title: fromReview ? 'Editing ${title.toLowerCase()}' : title,
          saveLabel: fromReview ? 'Save changes' : 'Done',
          changes: _formChanges,
          onBackStep: () async =>
              await _clientInformation.currentState?.backStep() ?? false,
          beforeClose: () async {
            await _clientInformation.currentState?.flushPendingInput();
            _captureEstimateInput();
            await _draft?.flush();
          },
          onSave: () async {
            if (fromReview) {
              buildConfirmedEstimate(_estimateInput, now: DateTime.now());
            }
            saved = true;
          },
          errorMessage: (error) => error is EstimateInputValidation
              ? error.message
              : 'Your changes could not be saved. Keep this form open and try again.',
          builder: (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_draft != null && _draft!.state == DraftSaveState.notSaved)
                EditorDraftStatus(state: _draft!.state, onRetry: _draft!.retry),
              content(),
            ],
          ),
        ),
      ),
    );
    if (mounted) _refresh(() {});
    return saved;
  }
}

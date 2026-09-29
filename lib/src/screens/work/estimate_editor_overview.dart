part of 'estimate_editor_screen.dart';

extension _EstimateEditorOverview on _EstimateEditorScreenState {
  Widget _buildOverview() => DocumentFormOverview(
    groups: [
      [
        _section(
          'estimate-customer',
          'Client information',
          _client ?? 'Select or add a client',
          Icons.person_outline,
          () => _identity(customerOnly: true),
        ),
        _section(
          'estimate-information',
          'Estimate information',
          _title.text.trim().isEmpty
              ? 'Add the description of work'
              : _title.text,
          Icons.description_outlined,
          () => _identity(customerOnly: false),
        ),
        DocumentFormSection(
          borderColor: Theme.of(context).colorScheme.onSurfaceVariant,
          key: const ValueKey('estimate-template'),
          title: 'Select a template',
          summary: DocumentTemplate.resolve(_template).label,
          icon: Icons.dashboard_customize_outlined,
          onTap: _chooseTemplate,
        ),
        _section(
          'estimate-dates',
          'Proposed schedule and dates',
          _proposedServiceOn == null
              ? 'When could this work be done?'
              : 'Proposed ${_date(context, _proposedServiceOn!)}',
          Icons.calendar_month_outlined,
          _timingEditor,
        ),
      ],
      [
        if (canUseEstimateServicePrice(_estimateId, _items))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.l10n.workOverallPriceHint),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('estimate-service-price'),
                  controller: _servicePrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _captureEstimateInput(),
                  decoration: InputDecoration(
                    labelText: context.l10n.workPriceBeforeAdjustments,
                  ),
                ),
              ],
            ),
          ),
        DocumentFormSection(
          borderColor: Theme.of(context).colorScheme.onSurfaceVariant,
          key: const ValueKey('estimate-items'),
          title: context.l10n.workOptionalItems,
          summary:
              '${_items.length} ${_items.length == 1 ? 'item' : 'items'} · ${_currency(_subtotal)}',
          icon: Icons.list_alt_outlined,
          onTap: () => _editItemCategory(EstimateItemCategory.all, _items),
        ),
        EstimatePriceSummary(
          subtotal: _currency(_subtotal),
          discount: _currency(_money(_discount)),
          tax: _currency(_money(_tax)),
          total: _currency(_total),
          onDiscount: () => _openSectionEditor(
            'Discount',
            () => DocumentAmountField(label: 'Discount', controller: _discount),
          ),
          onTax: () => _openSectionEditor(
            'Tax',
            () => DocumentAmountField(label: 'Tax', controller: _tax),
          ),
        ),
      ],
      [
        _section(
          'estimate-terms',
          'Service terms and deposit',
          _terms.text.trim().isEmpty
              ? 'Add terms'
              : 'Terms added - Tap to review',
          Icons.rule_outlined,
          _termsEditor,
        ),
        _EstimateSitePhotosSection(
          photoCount: _sitePhotos.length,
          onOpen: _editSitePhotos,
        ),
        if (_work?.permissions.canRecordCustomerApproval == true ||
            _work?.permissions.canCollectSignature == true)
          DocumentFormSection(
            borderColor: Theme.of(context).colorScheme.onSurfaceVariant,
            key: const ValueKey('estimate-customer-approval'),
            title: 'Customer signature and approval',
            summary: _hasCurrentApproval
                ? 'Approved — View approval'
                : 'Sign in person or record approval',
            icon: Icons.check_circle_outline,
            onTap: _draftReady && !_saving
                ? () => _confirmEstimate(recordApproval: true)
                : null,
          ),
      ],
    ],
  );

  Widget _timingEditor() => _EstimateTimingSection(
    createdOn: _createdOn,
    expiresOn: _expiresOn,
    followUpOn: _followUpOn,
    proposedServiceOn: _proposedServiceOn,
    onProposedTime: () async {
      final day = _proposedServiceOn ?? _createdOn;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(day),
      );
      if (time != null && mounted) {
        _changeEstimateInput(
          () => _proposedServiceOn = DateTime(
            day.year,
            day.month,
            day.day,
            time.hour,
            time.minute,
          ),
        );
      }
    },
    onExpires: () => _pickDate(_expiresOn, (value) => _expiresOn = value),
    onFollowUp: () =>
        _pickDate(_followUpOn ?? _createdOn, (value) => _followUpOn = value),
    onProposedService: () => _pickDate(
      _proposedServiceOn ?? _createdOn,
      (value) => _proposedServiceOn = DateTime(
        value.year,
        value.month,
        value.day,
        _proposedServiceOn?.hour ?? 0,
        _proposedServiceOn?.minute ?? 0,
      ),
    ),
  );

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
        scope: _scope,
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

  Widget _section(
    String id,
    String title,
    String summary,
    IconData icon,
    Widget Function() content,
  ) => DocumentFormSection(
    borderColor: Theme.of(context).colorScheme.onSurfaceVariant,
    key: ValueKey(id),
    title: title,
    summary: summary,
    icon: icon,
    onTap: () => _openSectionEditor(title, content),
  );

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

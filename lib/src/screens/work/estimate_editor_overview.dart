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
          _title.text.trim().isEmpty ? 'Add the proposed work' : _title.text,
          Icons.description_outlined,
          () => _identity(customerOnly: false),
        ),
        DocumentFormSection(
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
          () => _EstimateTimingSection(
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
            onExpires: () =>
                _pickDate(_expiresOn, (value) => _expiresOn = value),
            onFollowUp: () => _pickDate(
              _followUpOn ?? _createdOn,
              (value) => _followUpOn = value,
            ),
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
          ),
        ),
      ],
      [
        DocumentFormSection(
          key: const ValueKey('estimate-items'),
          title: 'Items',
          summary: '${_items.length} items · ${_currency(_subtotal)}',
          icon: Icons.list_alt_outlined,
          onTap: () => _editItemCategory(EstimateItemCategory.all, _items),
        ),
        DocumentFormSection(
          title: 'Subtotal',
          summary: _currency(_subtotal),
          icon: Icons.receipt_outlined,
        ),
        _section(
          'estimate-discount',
          'Discount',
          _currency(_money(_discount)),
          Icons.percent_rounded,
          () => DocumentAmountField(label: 'Discount', controller: _discount),
        ),
        _section(
          'estimate-tax',
          'Tax',
          _currency(_money(_tax)),
          Icons.calculate_outlined,
          () => DocumentAmountField(label: 'Tax', controller: _tax),
        ),
        DocumentFormSection(
          title: 'Estimate total',
          summary: _currency(_total),
          icon: Icons.summarize_outlined,
        ),
      ],
      [
        _section(
          'estimate-terms',
          'Terms and conditions',
          _terms.text.trim().isEmpty
              ? 'Add terms'
              : 'Terms added - Tap to review',
          Icons.rule_outlined,
          () => EstimateTermsEditor(controller: _terms),
        ),
        _EstimateSitePhotosSection(
          photoCount: _sitePhotos.length,
          onOpen: _editSitePhotos,
        ),
        const DocumentFormSection(
          title: 'Customer approval',
          summary:
              'Save the draft to review the customer copy and record approval for that revision.',
          icon: Icons.draw_outlined,
        ),
      ],
    ],
  );

  Widget _identity({required bool customerOnly}) => _EstimateIdentitySection(
    customerOnly: customerOnly,
    number: _number,
    title: _title,
    purchaseOrder: _purchaseOrder,
    scope: _scope,
    customers: [
      ...PrototypeOperationsScope.of(context).customers,
      if (_customerSnapshot != null &&
          !PrototypeOperationsScope.of(
            context,
          ).customers.any((customer) => customer.id == _customerSnapshot!.id))
        _customerSnapshot!,
    ],
    selectedClient: _customerSnapshot?.id ?? _client,
    pricing: _pricing,
    onClientChanged: (value) => _changeEstimateInput(() {
      final customer = [
        ...PrototypeOperationsScope.of(context).customers,
        ?_customerSnapshot,
      ].where((customer) => customer.id == value).firstOrNull;
      _client = customer?.name ?? value;
      _customerSnapshot = customer;
    }),
    onAddClient: _addClient,
    onPricingChanged: (value) => _changeEstimateInput(() => _pricing = value),
  );

  Widget _section(
    String id,
    String title,
    String summary,
    IconData icon,
    Widget Function() content,
  ) => DocumentFormSection(
    key: ValueKey(id),
    title: title,
    summary: summary,
    icon: icon,
    onTap: () async {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DocumentSectionEditor(
            title: title,
            changes: _formChanges,
            beforeClose: () async {
              await _draft?.flush();
            },
            builder: (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_draft != null)
                  EditorDraftStatus(
                    state: _draft!.state,
                    onRetry: _draft!.retry,
                  ),
                content(),
              ],
            ),
          ),
        ),
      );
      if (mounted) _refresh(() {});
    },
  );
}

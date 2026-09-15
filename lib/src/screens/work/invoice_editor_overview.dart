part of 'invoice_editor_screen.dart';

extension _InvoiceEditorOverview on _InvoiceEditorScreenState {
  Widget _buildOverview() => DocumentFormOverview(
    groups: [
      [
        _section(
          'invoice-customer',
          'Client information',
          _client ?? 'Select or add a client',
          Icons.person_outline,
          () => _identity(customerOnly: true),
        ),
        _section(
          'invoice-information',
          'Invoice information',
          _title.text.trim().isEmpty
              ? '$_number · Add work completed'
              : '$_number · ${_title.text}',
          Icons.description_outlined,
          () => _identity(customerOnly: false),
        ),
        DocumentFormSection(
          key: const ValueKey('invoice-template'),
          title: 'Select a template',
          summary: DocumentTemplate.resolve(_template).label,
          icon: Icons.dashboard_customize_outlined,
          onTap: _chooseTemplate,
        ),
        DocumentFormSection(
          key: const ValueKey('invoice-live-pdf-preview'),
          title: 'Preview customer PDF',
          summary: 'Full-screen preview using the current form and template',
          icon: Icons.picture_as_pdf_outlined,
          onTap: _previewPdf,
        ),
        _section(
          'invoice-source',
          'Invoice source',
          _jobs.where((job) => job.id == _sourceJobId).firstOrNull?.number ??
              'Direct invoice',
          Icons.link_rounded,
          () => _InvoiceSourceSection(
            jobs: _jobs,
            selectedValue: _jobs.any((job) => job.id == _sourceJobId)
                ? _sourceJobId!
                : _InvoiceEditorScreenState._directInvoice,
            directValue: _InvoiceEditorScreenState._directInvoice,
            onChanged: _selectSource,
          ),
        ),
        _section(
          'invoice-dates',
          'Invoice and due dates',
          '${_invoiceDate(context, _issuedOn)} · Due ${_invoiceDate(context, _dueOn)}',
          Icons.calendar_month_outlined,
          () => _InvoiceDatesSection(
            issuedOn: _issuedOn,
            dueOn: _dueOn,
            onIssuedOn: () => _pickDate(issueDate: true),
            onDueOn: () => _pickDate(issueDate: false),
          ),
        ),
      ],
      [
        _InvoiceItemsSection(
          itemCount: _items.length,
          subtotal: _subtotal,
          onOpen: _editItems,
        ),
        DocumentFormSection(
          title: 'Subtotal',
          summary: _invoiceMoney(_subtotal),
          icon: Icons.receipt_outlined,
        ),
        _section(
          'invoice-discount',
          'Discount',
          _invoiceMoney(_moneyValue(_discount)),
          Icons.percent_rounded,
          () => DocumentAmountField(label: 'Discount', controller: _discount),
        ),
        _section(
          'invoice-tax',
          'Tax',
          _invoiceMoney(_moneyValue(_tax)),
          Icons.calculate_outlined,
          () => DocumentAmountField(label: 'Tax', controller: _tax),
        ),
        DocumentFormSection(
          title: 'Invoice total',
          summary: _invoiceMoney(_total),
          icon: Icons.summarize_outlined,
        ),
      ],
      [
        _section(
          'invoice-payment-method',
          'Payment method',
          _paymentMethod,
          Icons.payments_outlined,
          () => DocumentChoiceField(
            label: 'Expected payment method',
            value: _paymentMethod,
            options: const [
              'Not selected',
              'Card',
              'Check',
              'Cash',
              'Bank transfer',
            ],
            onChanged: (value) => _updateInput(() => _paymentMethod = value),
          ),
        ),
        _section(
          'invoice-terms',
          'Terms and conditions',
          _terms.text.trim().isEmpty
              ? 'Add payment terms'
              : 'Terms added - Tap to review',
          Icons.rule_outlined,
          () => DocumentTermsField(controller: _terms),
        ),
        const DocumentFormSection(
          title: 'Draft',
          summary:
              'Save the draft to review, issue, and record linked payments. Nothing has been sent.',
          icon: Icons.edit_note_outlined,
        ),
      ],
    ],
  );

  Widget _identity({required bool customerOnly}) => _InvoiceIdentitySection(
    customerOnly: customerOnly,
    number: _number,
    title: _title,
    purchaseOrder: _purchaseOrder,
    summary: _summary,
    customers: _store.customers,
    selectedClient: _client,
    locations: _locationsFor(_client),
    selectedLocation: _location,
    pricing: _pricing,
    onClientChanged: _selectClient,
    onLocationChanged: (value) => _updateInput(() => _location = value),
    onAddClient: _addClient,
    onPricingChanged: (value) => _updateInput(() => _pricing = value),
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

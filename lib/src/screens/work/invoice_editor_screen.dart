import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'customer_edit_screen.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';
import 'work_items_editor.dart';
import 'work_models.dart';

part 'invoice_editor_sections.dart';
part 'invoice_editor_feedback.dart';

class InvoiceEditorScreen extends StatefulWidget {
  const InvoiceEditorScreen({
    required this.initialDay,
    this.sourceJob,
    this.initialRecord,
    this.createdByEmployeeId,
    super.key,
  });

  final DateTime initialDay;
  final WorkRecord? sourceJob;
  final WorkRecord? initialRecord;
  final String? createdByEmployeeId;

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  static const _directInvoice = 'direct-invoice';

  late final String _number;
  late final TextEditingController _title;
  late final TextEditingController _summary;
  late final TextEditingController _discount;
  late final TextEditingController _tax;
  late final TextEditingController _terms;
  late DateTime _issuedOn;
  late DateTime _dueOn;
  String? _sourceJobId;
  String? _client;
  String? _location;
  var _pricing = WorkPricingModel.flatRate;
  var _items = <WorkLineItem>[];
  var _template = 'Service standard';
  var _paymentMethod = 'Not selected';
  String? _formError;

  PrototypeOperationsStore get _store => PrototypeOperationsScope.of(context);

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _total => (_subtotal - _moneyValue(_discount) + _moneyValue(_tax))
      .clamp(0, double.infinity);

  List<WorkRecord> get _jobs =>
      _store.workRecords
          .where(
            (record) =>
                record.kind == WorkRecordKind.job &&
                record.status == WorkRecordStatus.completed,
          )
          .toList()
        ..sort((a, b) {
          final left = a.scheduledStart ?? a.createdOn ?? DateTime(1970);
          final right = b.scheduledStart ?? b.createdOn ?? DateTime(1970);
          return right.compareTo(left);
        });

  @override
  void initState() {
    super.initState();
    final existing = widget.initialRecord;
    final source = widget.sourceJob;
    _number =
        existing?.number ??
        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _title = TextEditingController(
      text: existing?.title ?? source?.title ?? '',
    );
    _summary = TextEditingController(
      text: existing?.detail ?? source?.detail ?? '',
    );
    _discount = TextEditingController(
      text: (existing?.discount ?? 0).toStringAsFixed(2),
    );
    _tax = TextEditingController(text: (existing?.tax ?? 0).toStringAsFixed(2));
    _terms = TextEditingController(
      text:
          existing?.terms ??
          'Payment is due within 14 days of the invoice date.',
    );
    _issuedOn = DateUtils.dateOnly(existing?.issuedOn ?? widget.initialDay);
    _dueOn = DateUtils.dateOnly(
      existing?.dueOn ?? _issuedOn.add(const Duration(days: 14)),
    );
    _sourceJobId = existing?.sourceId ?? source?.id;
    _client = existing?.client ?? source?.client;
    _location = existing?.serviceLocation ?? source?.serviceLocation;
    _pricing =
        existing?.pricing ?? source?.pricing ?? WorkPricingModel.flatRate;
    _items = [
      ...(existing?.items ??
          source?.items.where((item) => item.includedInInvoiceFromJob) ??
          const <WorkLineItem>[]),
    ];
    _template = existing?.template ?? 'Service standard';
    _paymentMethod = existing?.paymentMethod ?? 'Not selected';
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _discount.dispose();
    _tax.dispose();
    _terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('invoice-editor-screen'),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final width = AppLayoutEngine.formWorkspaceWidthFor(
            constraints.maxWidth - insets.horizontal,
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 96),
            children: [
              Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkDetailHeader(
                        label: widget.initialRecord == null
                            ? 'New invoice'
                            : 'Edit invoice',
                        selectedDay: _issuedOn,
                        onBack: () => Navigator.of(context).pop(),
                        showDateContext: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.initialRecord == null
                            ? 'Prepare an invoice'
                            : 'Edit invoice $_number',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Review the customer, completed work, charges, and due date before saving the draft.',
                      ),
                      if (_formError case final error?) ...[
                        const SizedBox(height: 10),
                        _InvoiceFormError(message: error),
                      ],
                      const SizedBox(height: 12),
                      _InvoiceSourceSection(
                        jobs: _jobs,
                        selectedValue:
                            _jobs.any((job) => job.id == _sourceJobId)
                            ? _sourceJobId!
                            : _directInvoice,
                        directValue: _directInvoice,
                        onChanged: _selectSource,
                      ),
                      const SizedBox(height: 12),
                      _InvoiceIdentitySection(
                        number: _number,
                        title: _title,
                        summary: _summary,
                        customers: _store.customers,
                        selectedClient: _client,
                        locations: _locationsFor(_client),
                        selectedLocation: _location,
                        pricing: _pricing,
                        onClientChanged: _selectClient,
                        onLocationChanged: (value) =>
                            setState(() => _location = value),
                        onAddClient: _addClient,
                        onPricingChanged: (value) =>
                            setState(() => _pricing = value),
                      ),
                      const SizedBox(height: 12),
                      _InvoiceItemsSection(
                        itemCount: _items.length,
                        subtotal: _subtotal,
                        onOpen: _editItems,
                      ),
                      const SizedBox(height: 12),
                      _InvoiceDatesSection(
                        issuedOn: _issuedOn,
                        dueOn: _dueOn,
                        onIssuedOn: () => _pickDate(issueDate: true),
                        onDueOn: () => _pickDate(issueDate: false),
                      ),
                      const SizedBox(height: 12),
                      _InvoiceCustomerCopySection(
                        subtotal: _subtotal,
                        total: _total,
                        discount: _discount,
                        tax: _tax,
                        terms: _terms,
                        template: _template,
                        paymentMethod: _paymentMethod,
                        onTemplateChanged: (value) =>
                            setState(() => _template = value),
                        onPaymentMethodChanged: (value) =>
                            setState(() => _paymentMethod = value),
                        onMoneyChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.all(12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: FilledButton.icon(
            key: const ValueKey('save-invoice-draft'),
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save invoice draft'),
          ),
        ),
      ),
    ),
  );

  List<WorkServiceLocation> _locationsFor(String? customerName) {
    if (customerName == null) return const [];
    for (final customer in _store.customers) {
      if (customer.name == customerName) return customer.locations;
    }
    return const [];
  }

  void _selectSource(String? value) {
    if (value == _directInvoice) {
      setState(() => _sourceJobId = null);
      return;
    }
    final source = _jobs.where((job) => job.id == value).firstOrNull;
    if (source == null) return;
    setState(() {
      _sourceJobId = source.id;
      _client = source.client;
      _location = source.serviceLocation;
      _title.text = source.title;
      _summary.text = source.detail;
      _pricing = source.pricing;
      _items = [...source.items.where((item) => item.includedInInvoiceFromJob)];
    });
  }

  void _selectClient(String? value) {
    final locations = _locationsFor(value);
    setState(() {
      _client = value;
      _location = locations.firstOrNull?.address;
    });
  }

  Future<void> _addClient() async {
    final customer = await Navigator.of(context).push<WorkCustomerProfile>(
      MaterialPageRoute(
        builder: (_) => CustomerEditScreen(selectedDay: _issuedOn),
      ),
    );
    if (!mounted || customer == null) return;
    _store.replaceCustomers([..._store.customers, customer]);
    setState(() {
      _client = customer.name;
      _location = customer.locations.firstOrNull?.address;
    });
  }

  Future<void> _editItems() async {
    final items = await Navigator.of(context).push<List<WorkLineItem>>(
      MaterialPageRoute(
        builder: (_) => WorkItemsEditor(
          initialItems: _items,
          pricing: _pricing,
          workspaceLabel: 'Invoice Items',
          allowTruckStock: true,
          selectedDay: _issuedOn,
        ),
      ),
    );
    if (mounted && items != null) setState(() => _items = items);
  }

  Future<void> _pickDate({required bool issueDate}) async {
    final current = issueDate ? _issuedOn : _dueOn;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: issueDate ? 'Choose invoice date' : 'Choose payment due date',
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (issueDate) {
        final previous = _issuedOn;
        _issuedOn = DateUtils.dateOnly(picked);
        if (_dueOn.isBefore(_issuedOn) ||
            _dueOn.difference(previous).inDays == 14) {
          _dueOn = _issuedOn.add(const Duration(days: 14));
        }
      } else {
        _dueOn = DateUtils.dateOnly(picked);
      }
    });
  }

  void _save() {
    if (_client == null ||
        _title.text.trim().isEmpty ||
        _summary.text.trim().isEmpty ||
        _items.isEmpty) {
      setState(
        () => _formError =
            'Choose a customer and enter the work completed with at least one invoice item.',
      );
      return;
    }
    if (_dueOn.isBefore(_issuedOn)) {
      setState(
        () => _formError =
            'The payment due date cannot be before the invoice date.',
      );
      return;
    }
    final existing = widget.initialRecord;
    Navigator.of(context).pop(
      WorkRecord(
        id: existing?.id ?? 'invoice-${DateTime.now().microsecondsSinceEpoch}',
        kind: WorkRecordKind.invoice,
        number: _number,
        title: _title.text.trim(),
        client: _client!,
        detail: _summary.text.trim(),
        pricing: _pricing,
        sourceId: _sourceJobId,
        serviceLocation: _location ?? '',
        createdOn: existing?.createdOn ?? DateUtils.dateOnly(DateTime.now()),
        issuedOn: _issuedOn,
        dueOn: _dueOn,
        createdByEmployeeId:
            existing?.createdByEmployeeId ??
            widget.createdByEmployeeId ??
            'alex',
        status: existing?.status ?? WorkRecordStatus.draft,
        items: List.unmodifiable(_items),
        template: _template,
        terms: _terms.text.trim(),
        paymentMethod: _paymentMethod,
        discount: _moneyValue(_discount),
        tax: _moneyValue(_tax),
        total: _total,
      ),
    );
  }
}

double _moneyValue(TextEditingController controller) =>
    double.tryParse(controller.text.trim()) ?? 0;

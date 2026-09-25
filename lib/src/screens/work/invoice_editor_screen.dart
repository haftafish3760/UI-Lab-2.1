import 'documents/customer_pdf_screen.dart';
import 'documents/document_template.dart';
import 'document_template_screen.dart';
import 'work_customer_document.dart';
import '../../shared/utility_form_section.dart';
import '../../data/work/work_items_draft_input.dart';
import '../../shared/editor_input_lock.dart';
import '../../data/work/invoice_confirmation.dart';
import '../../data/work/invoice_draft_workflow.dart';
import '../../data/work/invoice_draft_controller.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../shared/document_form_section.dart';
import '../../shared/document_form_fields.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/storage/local_record_identity.dart';
import '../../shared/editor_draft_status.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'customer_edit_screen.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';
import 'work_items_editor.dart';
import 'work_models.dart';

part 'invoice_editor_sections.dart';
part 'invoice_editor_overview.dart';
part 'invoice_editor_document_preview.dart';
part 'invoice_editor_feedback.dart';
part 'invoice_editor_persistence.dart';
part 'invoice_editor_confirmation.dart';

class InvoiceEditorScreen extends StatefulWidget {
  const InvoiceEditorScreen({
    required this.initialDay,
    this.sourceJob,
    this.initialRecord,
    this.createdByEmployeeId,
    this.recoveredWorkflow,
    super.key,
  });

  final DateTime initialDay;
  final WorkRecord? sourceJob;
  final WorkRecord? initialRecord;

  /// This editor owns closing the already-selected workflow on exit.
  final InvoiceDraftController? recoveredWorkflow;
  final String? createdByEmployeeId;

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  static const _directInvoice = 'direct-invoice';

  late String _number;
  late String _recordId;
  late String _creatorId;
  late DateTime _createdOn;
  late InvoiceDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _draftSubscription;
  bool _draftStarted = false;
  bool _draftReady = false;
  bool _submitting = false;
  bool _allowPop = false;
  int _baseStorageRevision = 0;
  WorkItemsDraftInput? _itemDraftInput;
  late final _purchaseOrder = TextEditingController(
    text: widget.initialRecord?.purchaseOrderNumber ?? '',
  );
  late final TextEditingController _title;
  late final TextEditingController _summary;
  late final TextEditingController _discount;
  late final TextEditingController _tax;
  late final TextEditingController _terms;
  late DateTime _issuedOn;
  late DateTime _dueOn;
  String? _sourceJobId;
  WorkCustomerProfile? _customerSnapshot;
  String? _client;
  String? _location;
  var _pricing = WorkPricingModel.flatRate;
  var _items = <WorkLineItem>[];
  var _template = 'Service standard';
  var _paymentMethod = 'Not selected';
  String? _formError;

  final _sectionChanges = ValueNotifier<int>(0);
  late final Listenable _formChanges = Listenable.merge([
    _sectionChanges,
    _purchaseOrder,
    _title,
    _summary,
    _discount,
    _tax,
    _terms,
  ]);
  void _refresh(VoidCallback change) {
    setState(change);
    _sectionChanges.value++;
  }

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
    _customerSnapshot = existing?.customerSnapshot ?? source?.customerSnapshot;
    _recordId = existing?.id ?? newLocalRecordIdentity('invoice');
    _creatorId =
        existing?.createdByEmployeeId ?? widget.createdByEmployeeId ?? 'alex';
    _createdOn = existing?.createdOn ?? DateUtils.dateOnly(DateTime.now());
    _number =
        existing?.number ??
        'Invoice ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _title = TextEditingController(
      text: existing?.title ?? source?.title ?? '',
    );
    _summary = TextEditingController(
      text: existing?.detail ?? source?.detail ?? '',
    );
    _discount = TextEditingController(
      text: (existing?.discount ?? source?.discount ?? 0).toStringAsFixed(2),
    );
    _tax = TextEditingController(
      text: (existing?.tax ?? source?.tax ?? 0).toStringAsFixed(2),
    );
    _terms = TextEditingController(
      text:
          existing?.terms ??
          source?.terms ??
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
    for (final controller in [
      _purchaseOrder,
      _title,
      _summary,
      _discount,
      _tax,
      _terms,
    ]) {
      controller.addListener(_captureDraft);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_draftStarted) {
      _draftStarted = true;
      unawaited(_openDraft());
    }
  }

  @override
  void dispose() {
    unawaited(_draftSubscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _sectionChanges.dispose();
    _purchaseOrder.dispose();
    _title.dispose();
    _summary.dispose();
    _discount.dispose();
    _tax.dispose();
    _terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop || _draft == null,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(_leaveEditor());
    },
    child: Scaffold(
      key: const ValueKey('invoice-editor-screen'),
      body: SafeArea(
        child: EditorInputLock(
          locked: _submitting,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final insets = AppLayoutEngine.pageInsetsFor(
                constraints.maxWidth,
              );
              final width = AppLayoutEngine.workFor(
                constraints.maxWidth - insets.horizontal,
                textScaler: MediaQuery.textScalerOf(context),
              ).workspaceWidth;
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
                            onBack: _leaveEditor,
                            showDateContext: true,
                          ),
                          if (_draft != null)
                            EditorDraftStatus(
                              state: _draft!.state,
                              onRetry: _draft!.retry,
                              onDiscard: _discardDraft,
                            ),
                          if (!_draftReady && _formError == null)
                            const Text('Opening saved input…'),
                          if (_formError != null)
                            _InvoiceFormError(message: _formError!),
                          if (_draftReady) ...[
                            const SizedBox(height: 12),
                            AnimatedBuilder(
                              animation: _formChanges,
                              builder: (context, _) => _buildOverview(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
              key: const ValueKey('save-invoice-draft'),
              onPressed: _draftReady && !_submitting ? _save : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save invoice draft'),
            ),
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
    if (_itemDraftInput != null) {
      _updateInput(
        () => _formError =
            'Finish or discard the unfinished item changes before changing the source job.',
      );
      return;
    }
    if (value == _directInvoice) {
      _updateInput(() => _sourceJobId = null);
      return;
    }
    final source = _jobs.where((job) => job.id == value).firstOrNull;
    if (source == null) return;
    _updateInput(() {
      _sourceJobId = source.id;
      _customerSnapshot = source.customerSnapshot;
      _client = source.client;
      _location = source.serviceLocation;
      _title.text = source.title;
      _summary.text = source.detail;
      _pricing = source.pricing;
      _discount.text = source.discount.toStringAsFixed(2);
      _tax.text = source.tax.toStringAsFixed(2);
      _terms.text = source.terms;
      _items = [...source.items.where((item) => item.includedInInvoiceFromJob)];
    });
  }

  void _selectClient(String? value) {
    final locations = _locationsFor(value);
    _updateInput(() {
      _client = value;
      _customerSnapshot = _store.customers
          .where((customer) => customer.name == value)
          .firstOrNull;
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
    if (_store.directorySession == null) {
      _store.replaceCustomers([..._store.customers, customer]);
    }
    _updateInput(() {
      _client = customer.name;
      _customerSnapshot = customer;
      _location = customer.locations.firstOrNull?.address;
    });
  }

  Future<void> _editItems() async {
    final items = await Navigator.of(context).push<List<WorkLineItem>>(
      MaterialPageRoute(
        builder: (_) => WorkItemsEditor(
          initialItems: _items,
          draftSession: _draft,
          recoveryInput: _itemDraftInput,
          onDraftChanged: _draft == null
              ? null
              : (input) => _updateInput(() => _itemDraftInput = input),
          pricing: _pricing,
          workspaceLabel: 'Invoice Items',
          allowTruckStock: true,
          selectedDay: _issuedOn,
        ),
      ),
    );
    if (mounted && items != null) {
      _updateInput(() {
        _items = items;
        _itemDraftInput = null;
      });
    }
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
    _updateInput(() {
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
}

double _moneyValue(TextEditingController controller) =>
    double.tryParse(controller.text.trim()) ?? 0;

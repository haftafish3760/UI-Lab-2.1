import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/storage/local_record_command.dart';
import '../../data/storage/local_record_identity.dart';
import '../../data/work/estimate_confirmation.dart';
import '../../data/work/estimate_draft_controller.dart';
import '../../data/work/estimate_draft_workflow.dart';
import '../../data/work/work_items_draft_input.dart';
import '../../data/work/work_persistence_session.dart';
import '../../data/work/work_service_price.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/document_form_fields.dart';
import '../../shared/document_form_section.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import 'saved_clients_screen.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';
import 'work_items_editor.dart';
import 'work_models.dart';

part 'quote_editor_form.dart';

class QuoteEditorScreen extends StatefulWidget {
  const QuoteEditorScreen({
    required this.initialDay,
    this.initialRecord,
    this.recoveredWorkflow,
    super.key,
  });
  final DateTime initialDay;
  final WorkRecord? initialRecord;
  final EstimateDraftController? recoveredWorkflow;
  @override
  State<QuoteEditorScreen> createState() => _QuoteEditorScreenState();
}

class _QuoteEditorScreenState extends State<QuoteEditorScreen>
    with DraftNavigationGuard {
  final _title = TextEditingController(),
      _description = TextEditingController();
  final _price = TextEditingController(), _terms = TextEditingController();
  final _discount = TextEditingController(), _tax = TextEditingController();
  final _number = TextEditingController();
  WorkPersistenceSession? _work;
  EstimateDraftController? _workflow;
  StreamSubscription<DraftSaveState>? _subscription;
  WorkRecord? _base;
  WorkCustomerProfile? _customer;
  String? _client, _initialInput, _error;
  late String _id, _actor;
  late DateTime _created;
  DateTime? _expires;
  int _revision = 0;
  List<WorkLineItem> _items = [];
  WorkItemsDraftInput? _pendingItems;
  bool _started = false, _ready = false, _saving = false;
  Iterable<TextEditingController> get _fields => [
    _title,
    _description,
    _price,
    _terms,
    _discount,
    _tax,
    _number,
  ];
  @override
  DraftAutosaveSession? get navigationDraft => _workflow?.session;
  @override
  bool get blockDraftNavigation => _saving;
  @override
  bool get confirmDraftExit =>
      _ready && canonicalJson(_input.toPayload()) != _initialInput;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      unawaited(_open());
    }
  }

  Future<void> _open() async {
    try {
      final work = PrototypeOperationsScope.of(context).workSession;
      if (work == null) throw StateError('Saved Work storage is unavailable.');
      _work = work;
      _base = widget.initialRecord == null
          ? null
          : work.editableEstimate(
              widget.initialRecord!.id,
              documentKind: WorkRecordKind.quote,
            );
      _id = _base?.id ?? newLocalRecordIdentity('quote');
      _actor =
          _base?.createdByEmployeeId ??
          widget.recoveredWorkflow?.recoveredInput?.creatorId ??
          work.permissions.actorEmployeeId;
      _revision = work.storageRevisionFor(_id);
      _created = _base?.createdOn ?? widget.initialDay;
      _expires = _base?.estimateDates?.expiresOn;
      _number.text =
          _base?.number ?? await work.nextDocumentNumber(WorkRecordKind.quote);
      _title.text = _base?.title ?? '';
      _description.text = _base?.detail ?? '';
      _terms.text = _base?.terms ?? '';
      _discount.text = _base?.discount.toStringAsFixed(2) ?? '';
      _tax.text = _base?.tax.toStringAsFixed(2) ?? '';
      _items = [...?_base?.items];
      _customer = _base?.customerSnapshot;
      _client = _base?.client;
      if (_items.isNotEmpty && canUseWorkServicePrice(_id, _items)) {
        _price.text = _items.single.customerPrice.toStringAsFixed(2);
      }
      _initialInput = canonicalJson(_input.toPayload());
      final workflow =
          widget.recoveredWorkflow ??
          await work.openEstimateDraft(
            documentKind: WorkRecordKind.quote,
            creatorId: _actor,
            existingRecordId: _base?.id,
          );
      if (widget.recoveredWorkflow != null) {
        work.validateEstimateHandoff(
          workflow,
          documentKind: WorkRecordKind.quote,
          creatorId: _actor,
          existingRecordId: _base?.id,
        );
      }
      _workflow = workflow;
      if (!mounted) {
        await workflow.session.close();
        return;
      }
      final input = workflow.recoveredInput;
      if (input != null) {
        _id = input.estimateId;
        _actor = input.creatorId;
        _base = input.baseRecord;
        _revision = input.baseStorageRevision;
        _created = input.createdOn;
        _expires = input.expiresOn;
        _number.text = input.number;
        _title.text = input.title;
        _description.text = input.scope;
        _terms.text = input.terms;
        _discount.text = input.discount;
        _tax.text = input.tax;
        _price.text = input.servicePrice;
        _customer = input.customerSnapshot;
        _client = input.client;
        _items = input.items;
        _pendingItems = input.pendingLineItems['quote-items'];
      }
      for (final field in _fields) {
        field.addListener(_capture);
      }
      _subscription = workflow.session.changes.listen((_) {
        if (mounted) setState(() {});
      });
      setState(() => _ready = true);
      _capture();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'This quote could not be opened. Saved information has been kept.',
        );
      }
    }
  }

  EstimateDraftInput get _input => EstimateDraftInput(
    documentKind: WorkRecordKind.quote,
    creatorId: _actor,
    number: _number.text,
    baseStorageRevision: _revision,
    title: _title.text,
    discount: _discount.text,
    tax: _tax.text,
    terms: _terms.text,
    client: _client,
    customerSnapshot: _customer,
    pricing: WorkPricingModel.flatRate,
    documentPresentation: canUseWorkServicePrice(_id, _items)
        ? WorkDocumentPresentation.summary
        : WorkDocumentPresentation.detailed,
    template: _base?.template ?? 'Service standard',
    createdOn: _created,
    items: _items,
    servicePrice: _price.text,
    baseRecord: _base,
    estimateId: _id,
    scope: _description.text,
    expiresOn: _expires,
    validityDays: _base?.estimateDates?.validityDays,
    finishedOn: _base?.estimateDates?.finishedOn,
    sentOn: _base?.estimateDates?.sentOn,
    followUpOn: _base?.estimateDates?.followUpOn,
    proposedServiceOn: _base?.estimateDates?.proposedServiceOn,
    proposedServiceDates:
        _base?.estimateDates?.proposedServiceDates ?? const [],
    purchaseOrderNumber: _base?.purchaseOrderNumber ?? '',
    requiresDeposit: (_base?.requiredDepositCents ?? 0) > 0,
    depositAmount: ((_base?.requiredDepositCents ?? 0) / 100).toStringAsFixed(
      2,
    ),
    pendingLineItems: {'quote-items': ?_pendingItems},
    pendingPhotos: null,
    sitePhotos: _base?.sitePhotos ?? const [],
  );
  void _capture() {
    if (!_ready || _saving) return;
    _workflow!.updateInput(_input);
  }

  Future<void> _clientPicker() async {
    final store = PrototypeOperationsScope.of(context);
    final customer = await Navigator.of(context).push<WorkCustomerProfile>(
      MaterialPageRoute(
        builder: (_) => SavedClientsScreen(
          initialClients: store.customers,
          selectedDay: _created,
          selectForDocument: true,
          onClientsChanged: store.replaceCustomers,
        ),
      ),
    );
    if (!mounted ||
        customer == null ||
        store.directorySession?.permissions.canViewCustomers == false) {
      return;
    }
    final current = store.customers
        .where((c) => c.id == customer.id)
        .firstOrNull;
    if (current == null) return;
    setState(() {
      _customer = current;
      _client = current.name;
    });
    _capture();
  }

  Future<void> _editItems() async {
    var starting = _items;
    try {
      if (_price.text.trim().isNotEmpty) {
        starting = workServicePricedItems(
          recordId: _id,
          title: _title.text,
          description: _description.text,
          priceText: _price.text,
          items: _items,
        );
      }
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    final items = await Navigator.of(context).push<List<WorkLineItem>>(
      MaterialPageRoute(
        builder: (_) => WorkItemsEditor(
          initialItems: starting,
          pricing: WorkPricingModel.flatRate,
          workspaceLabel: 'Quote items',
          draftSession: navigationDraft,
          recoveryInput: _pendingItems,
          allowExpenseEvidence: false,
          allowTruckStock: false,
          onDraftChanged: (input) {
            _pendingItems = input;
            _capture();
          },
        ),
      ),
    );
    if (!mounted) return;
    if (items != null) {
      setState(() {
        _items = items;
        _pendingItems = null;
        _price.clear();
      });
      _capture();
    }
  }

  Future<void> _save() async {
    _capture();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await _workflow!.confirm();
      if (saved == null) {
        throw StateError(_work?.failureMessage ?? 'Quote was not saved.');
      }
      if (mounted) await finishDraftRoute(saved);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is EstimateInputValidation
              ? error.message
              : _work?.failureMessage ??
                    'Quote was not saved. Your input has been kept; try again.';
        });
      }
    }
  }

  Future<void> _chooseExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expires ?? _created,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      setState(() => _expires = date);
      _capture();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(navigationDraft?.close().catchError((Object _) {}));
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  void _clearExpiry() {
    setState(() => _expires = null);
    _capture();
  }

  double get _subtotal => _price.text.trim().isNotEmpty
      ? double.tryParse(_price.text) ?? 0
      : _items.fold<double>(0, (sum, item) => sum + item.total);
  String _money(num value) => '\$${value.toStringAsFixed(2)}';
  @override
  Widget build(BuildContext context) => _buildForm();
}

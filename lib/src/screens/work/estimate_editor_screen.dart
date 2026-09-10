import '../../data/work/work_items_draft_input.dart';
import '../../data/work/estimate_photos_draft_input.dart';
import '../../data/work/estimate_confirmation.dart';
import '../../data/work/estimate_draft_workflow.dart';
import '../../data/work/estimate_draft_controller.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/storage/local_record_identity.dart';
import '../../data/work/work_persistence_session.dart';
import '../../data/work/estimate_photo_media_workflow.dart';
import '../../shared/native_media_picker_scope.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../dashboard/dashboard_models.dart';
import 'customer_edit_screen.dart';
import 'estimate_items_screen.dart';
import 'estimate_site_photos_screen.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

part 'estimate_editor_sections.dart';
part 'estimate_editor_persistence.dart';
part 'estimate_editor_confirmation.dart';

class EstimateEditorScreen extends StatefulWidget {
  const EstimateEditorScreen({
    required this.initialDay,
    this.initialClient,
    this.createdByEmployeeId,
    this.initialRecord,
    this.recoveredWorkflow,
    super.key,
  });

  final DateTime initialDay;
  final String? initialClient;
  final String? createdByEmployeeId;
  final WorkRecord? initialRecord;

  /// Already-selected input; this editor owns closing the workflow on exit.
  final EstimateDraftController? recoveredWorkflow;

  @override
  State<EstimateEditorScreen> createState() => _EstimateEditorScreenState();
}

class _EstimateEditorScreenState extends State<EstimateEditorScreen>
    with DraftNavigationGuard {
  WorkPersistenceSession? _work;
  late EstimateDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _draftSubscription;
  WorkRecord? _baseRecord;
  int _baseStorageRevision = 0;
  bool _initialized = false;
  bool _draftReady = false;
  bool _saving = false;
  String? _saveError;
  late String _estimateId;
  late String _creatorId;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  void _refresh(VoidCallback change) => setState(change);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _work = PrototypeOperationsScope.of(context).workSession;
      unawaited(_openEstimateDraft());
    }
  }

  late String _number;
  late final TextEditingController _title;
  late final TextEditingController _scope;
  late final TextEditingController _discount;
  late final TextEditingController _tax;
  late final TextEditingController _terms;
  late DateTime _createdOn;
  late DateTime _expiresOn;
  DateTime? _followUpOn;
  DateTime? _proposedServiceOn;
  String? _client;
  var _pricing = WorkPricingModel.flatRate;
  var _template = 'Service standard';
  var _items = <WorkLineItem>[];
  var _itemDraftInputs = <String, WorkItemsDraftInput>{};
  var _sitePhotos = <WorkSitePhoto>[];
  EstimatePhotosDraftInput? _photoDraftInput;

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _total =>
      (_subtotal - _money(_discount) + _money(_tax)).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    final existing = widget.initialRecord;
    _baseRecord = existing;
    _estimateId = existing?.id ?? newLocalRecordIdentity('estimate');
    _creatorId =
        existing?.createdByEmployeeId ??
        widget.createdByEmployeeId ??
        demoEmployees.first.id;
    _number =
        existing?.number ??
        'EST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _title = TextEditingController(text: existing?.title ?? '');
    _scope = TextEditingController(text: existing?.detail ?? '');
    _discount = TextEditingController(
      text: (existing?.discount ?? 0).toStringAsFixed(2),
    );
    _tax = TextEditingController(text: (existing?.tax ?? 0).toStringAsFixed(2));
    _terms = TextEditingController(
      text:
          existing?.terms ??
          'Estimate is valid for 30 days. Work begins only after customer approval and company scheduling.',
    );
    _createdOn = DateUtils.dateOnly(
      existing?.estimateDates?.createdOn ?? widget.initialDay,
    );
    _expiresOn =
        existing?.estimateDates?.expiresOn ??
        _createdOn.add(const Duration(days: 30));
    _followUpOn = existing?.estimateDates?.followUpOn;
    _proposedServiceOn = existing?.estimateDates?.proposedServiceOn;
    _client = existing?.client ?? widget.initialClient;
    _pricing = existing?.pricing ?? WorkPricingModel.flatRate;
    _template = existing?.template ?? 'Service standard';
    _items = [...?existing?.items];
    _sitePhotos = [...?existing?.sitePhotos];
  }

  @override
  void dispose() {
    unawaited(_draftSubscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _title.dispose();
    _scope.dispose();
    _discount.dispose();
    _tax.dispose();
    _terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = PrototypeOperationsScope.of(context).customers;
    return guardDraftNavigation(
      Scaffold(
        key: const ValueKey('estimate-editor-screen'),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final insets = AppLayoutEngine.pageInsetsFor(
                constraints.maxWidth,
              );
              final layout = AppLayoutEngine.detailWorkspaceFor(
                constraints.maxWidth - insets.horizontal,
                textScaler: MediaQuery.textScalerOf(context),
              );
              return Center(
                child: SizedBox(
                  width: layout.columnWidth,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 96),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          WorkDetailHeader(
                            label: widget.initialRecord == null
                                ? 'New estimate'
                                : 'Edit estimate',
                            selectedDay: _createdOn,
                            onBack: () => leaveDraftRoute(),
                            showDateContext: true,
                          ),
                          if (_draft != null)
                            EditorDraftStatus(
                              state: _draft!.state,
                              onRetry: _draft!.retry,
                              onDiscard: _discardEstimateDraft,
                            ),
                          if (_saveError != null) Text(_saveError!),
                          if (!_draftReady && _saveError == null)
                            const Text('Opening saved input…'),
                          if (_draftReady) ...[
                            const SizedBox(height: 16),
                            Text(
                              widget.initialRecord == null
                                  ? 'Create an estimate'
                                  : 'Edit estimate ${widget.initialRecord!.revision}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Describe the proposed work, build labor and materials, then review the exact customer copy before sending it.',
                            ),
                            const SizedBox(height: 14),
                            _EstimateDraftBanner(
                              number: _number,
                              createdOn: _createdOn,
                            ),
                            const SizedBox(height: 12),
                            _EstimateIdentitySection(
                              number: _number,
                              title: _title,
                              scope: _scope,
                              customers: customers,
                              selectedClient: _client,
                              pricing: _pricing,
                              onClientChanged: (value) =>
                                  _changeEstimateInput(() => _client = value),
                              onAddClient: _addClient,
                              onPricingChanged: (value) =>
                                  _changeEstimateInput(() => _pricing = value),
                            ),
                            const SizedBox(height: 12),
                            _EstimateSitePhotosSection(
                              photoCount: _sitePhotos.length,
                              onOpen: _editSitePhotos,
                            ),
                            const SizedBox(height: 12),
                            _EstimateWorkBuildingSection(
                              laborCount: _items
                                  .where(
                                    (item) =>
                                        item.type == WorkLineItemType.labor,
                                  )
                                  .length,
                              laborTotal: _items
                                  .where(
                                    (item) =>
                                        item.type == WorkLineItemType.labor,
                                  )
                                  .fold<double>(
                                    0,
                                    (sum, item) => sum + item.total,
                                  ),
                              materialCount: _items
                                  .where(
                                    (item) =>
                                        item.type != WorkLineItemType.labor,
                                  )
                                  .length,
                              materialTotal: _items
                                  .where(
                                    (item) =>
                                        item.type != WorkLineItemType.labor,
                                  )
                                  .fold<double>(
                                    0,
                                    (sum, item) => sum + item.total,
                                  ),
                              onLabor: _editLabor,
                              onMaterials: _editMaterials,
                            ),
                            const SizedBox(height: 12),
                            _EstimateTimingSection(
                              createdOn: _createdOn,
                              expiresOn: _expiresOn,
                              followUpOn: _followUpOn,
                              proposedServiceOn: _proposedServiceOn,
                              onExpires: () => _pickDate(
                                _expiresOn,
                                (value) => _expiresOn = value,
                              ),
                              onFollowUp: () => _pickDate(
                                _followUpOn ?? _createdOn,
                                (value) => _followUpOn = value,
                              ),
                              onProposedService: () => _pickDate(
                                _proposedServiceOn ?? _createdOn,
                                (value) => _proposedServiceOn = value,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _EstimatePricingSection(
                              subtotal: _subtotal,
                              total: _total,
                              discount: _discount,
                              tax: _tax,
                              template: _template,
                              terms: _terms,
                              onTemplate: _chooseTemplate,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
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
                key: ValueKey(
                  widget.initialRecord == null
                      ? 'save-estimate-draft'
                      : 'save-estimate-changes',
                ),
                onPressed: _draftReady && !_saving ? _save : null,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  widget.initialRecord == null
                      ? 'Save estimate draft'
                      : 'Save estimate changes',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editLabor() async => _editItemCategory(
    EstimateItemCategory.labor,
    _items.where((item) => item.type == WorkLineItemType.labor).toList(),
  );

  Future<void> _editMaterials() async => _editItemCategory(
    EstimateItemCategory.materialsAndCharges,
    _items.where((item) => item.type != WorkLineItemType.labor).toList(),
  );

  Future<void> _editItemCategory(
    EstimateItemCategory category,
    List<WorkLineItem> initialItems,
  ) async {
    final revised = await Navigator.of(context).push<List<WorkLineItem>>(
      MaterialPageRoute(
        builder: (_) => EstimateItemsScreen(
          initialItems: initialItems,
          pricing: _pricing,
          category: category,
          draftSession: _draft,
          recoveryInput: _itemDraftInputs[category.name],
          onDraftChanged: (input) => _changeEstimateInput(() {
            _itemDraftInputs[category.name] = input;
          }),
          selectedDay: _createdOn,
        ),
      ),
    );
    if (!mounted || revised == null) return;
    _changeEstimateInput(() {
      _itemDraftInputs.remove(category.name);
      final keepLabor = category != EstimateItemCategory.labor;
      final retained = _items.where(
        (item) => (item.type == WorkLineItemType.labor) == keepLabor,
      );
      _items = [...retained, ...revised];
    });
  }

  Future<void> _editSitePhotos() async {
    final coordinator = NativeMediaPickerScope.maybeOf(context);
    final media = _work == null || _draft == null || coordinator == null
        ? null
        : _work!.photoMediaWorkflow(draft: _draft!, coordinator: coordinator);
    final photos = await Navigator.of(context).push<List<WorkSitePhoto>>(
      MaterialPageRoute(
        builder: (_) => EstimateSitePhotosScreen(
          initialDay: _createdOn,
          initialPhotos: _sitePhotos,
          retainPhotoFile: _work == null ? null : _retainEstimatePhoto,
          draftSession: _draft,
          mediaWorkflow: media,
          recoveryInput: _photoDraftInput,
          onDraftChanged: (input) =>
              _changeEstimateInput(() => _photoDraftInput = input),
        ),
      ),
    );
    if (mounted && photos != null) {
      _changeEstimateInput(() {
        _sitePhotos = photos;
        _photoDraftInput = null;
      });
    }
  }

  Future<void> _addClient() async {
    final customer = await Navigator.of(context).push<WorkCustomerProfile>(
      MaterialPageRoute(
        builder: (_) => CustomerEditScreen(selectedDay: _createdOn),
      ),
    );
    if (!mounted || customer == null) return;
    final store = PrototypeOperationsScope.of(context);
    if (store.directorySession == null) {
      store.replaceCustomers([...store.customers, customer]);
    }
    _changeEstimateInput(() => _client = customer.name);
  }

  Future<void> _pickDate(
    DateTime initial,
    ValueChanged<DateTime> assign,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _createdOn.subtract(const Duration(days: 365)),
      lastDate: _createdOn.add(const Duration(days: 3650)),
    );
    if (mounted && date != null) _changeEstimateInput(() => assign(date));
  }

  Future<void> _chooseTemplate() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final template in const [
              'Plain professional',
              'Service standard',
              'Detailed commercial',
            ])
              ListTile(
                title: Text(template),
                trailing: template == _template
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(template),
              ),
          ],
        ),
      ),
    );
    if (mounted && selected != null) {
      _changeEstimateInput(() => _template = selected);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

double _money(TextEditingController controller) =>
    double.tryParse(controller.text.trim()) ?? 0;

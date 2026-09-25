import '../../data/work/directory_persistence_session.dart';
import 'add_job_employee_button.dart';
import '../../shared/utility_form_section.dart';
import '../../data/work/work_items_draft_input.dart';
import '../../data/work/job_confirmation.dart';
import '../../data/work/job_draft_workflow.dart';
import '../../data/work/job_draft_controller.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../shared/editor_draft_status.dart';
import '../../data/storage/local_record_identity.dart';
import '../../shared/draft_navigation_guard.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';
import '../dashboard/dashboard_models.dart';
import 'customer_edit_screen.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';
import 'work_items_editor.dart';
import 'work_models.dart';

part 'work_job_editor_sections.dart';
part 'work_job_draft_recovery.dart';
part 'work_job_confirmation.dart';

class WorkJobEditor extends StatefulWidget {
  const WorkJobEditor({
    this.sourceEstimate,
    this.initialDay,
    this.recoveredWorkflow,
    super.key,
  });

  final WorkRecord? sourceEstimate;

  /// This editor owns closing the already-selected workflow on exit.
  final JobDraftController? recoveredWorkflow;
  final DateTime? initialDay;

  @override
  State<WorkJobEditor> createState() => _WorkJobEditorState();
}

class _WorkJobEditorState extends State<WorkJobEditor>
    with DraftNavigationGuard {
  bool _saving = false;
  int _sourceStorageRevision = 0;
  late String _jobId = newLocalRecordIdentity('job');
  late JobDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _draftSubscription;
  bool _draftReady = false;
  WorkRecord? _sourceEstimate;
  WorkItemsDraftInput? _itemDraftInput;
  void _refresh(VoidCallback change) => setState(change);
  @override
  bool get blockDraftNavigation => _saving;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;

  late String _number;
  List<String> _employeeIds = [];
  late final _purchaseOrder = TextEditingController(
    text: widget.sourceEstimate?.purchaseOrderNumber ?? '',
  );
  late final TextEditingController _title;
  late final TextEditingController _scope;
  late final TextEditingController _notes;
  late DateTime _startDay;
  late DateTime _endDay;
  var _startTime = const TimeOfDay(hour: 9, minute: 0);
  var _endTime = const TimeOfDay(hour: 11, minute: 0);
  String? _client;
  String? _location;
  String? _assignee;
  String? _vehicle;
  var _pricing = WorkPricingModel.timeAndMaterials;
  var _items = <WorkLineItem>[];
  String? _formError;
  var _didInitializeLocation = false;

  PrototypeOperationsStore get _store => PrototypeOperationsScope.of(context);
  bool get _fromApprovedEstimate => _sourceEstimate != null;

  @override
  void initState() {
    super.initState();
    final source = widget.sourceEstimate;
    _sourceEstimate = source;
    _number =
        'Job ${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _title = TextEditingController(text: source?.title ?? '');
    _scope = TextEditingController(text: source?.detail ?? '');
    _notes = TextEditingController();
    _client = source?.client;
    _pricing = source?.pricing ?? WorkPricingModel.timeAndMaterials;
    _items = [...?source?.items];
    _startDay = DateUtils.dateOnly(widget.initialDay ?? DateTime.now());
    _endDay = _startDay;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeLocation) return;
    _didInitializeLocation = true;
    _location = _locationsFor(_client).firstOrNull?.address;
    _sourceStorageRevision =
        _store.workSession?.storageRevisionFor(
          widget.sourceEstimate?.id ?? '',
        ) ??
        0;
    unawaited(_openJobDraft());
  }

  @override
  void dispose() {
    unawaited(_draftSubscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _purchaseOrder.dispose();
    _title.dispose();
    _scope.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return guardDraftNavigation(
      Scaffold(
        key: const ValueKey('job-editor-screen'),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final insets = AppLayoutEngine.pageInsetsFor(
                constraints.maxWidth,
              );
              final available = constraints.maxWidth - insets.horizontal;
              final width = AppLayoutEngine.formWorkspaceWidthFor(available);
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
                            label: _fromApprovedEstimate
                                ? 'Create Job'
                                : 'New Job',
                            selectedDay: _startDay,
                            onBack: () => leaveDraftRoute(),
                          ),
                          if (_draft != null)
                            EditorDraftStatus(
                              state: _draft!.state,
                              onRetry: _draft!.retry,
                              onDiscard: _discardJobDraft,
                            ),
                          if (!_draftReady)
                            Text(_formError ?? 'Opening saved input…'),
                          if (_draftReady) ...[
                            const SizedBox(height: 16),
                            Text(
                              _fromApprovedEstimate
                                  ? 'Create and plan the approved work'
                                  : 'Create and plan a job',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Confirm the customer, location, schedule, assignment, and work scope before saving.',
                            ),
                            if (_formError case final error?) ...[
                              const SizedBox(height: 10),
                              _JobFormError(message: error),
                            ],
                            if (_sourceEstimate case final source?) ...[
                              const SizedBox(height: 12),
                              _SourceEstimateBanner(record: source),
                            ],
                            const SizedBox(height: 12),
                            _JobIdentitySection(
                              number: _number,
                              title: _title,
                              purchaseOrder: _purchaseOrder,
                              scope: _scope,
                              customers: _jobCustomers,
                              selectedClient: _client,
                              selectedLocation: _location,
                              locations: _locationsFor(_client),
                              pricing: _pricing,
                              onClientChanged: _selectClient,
                              onLocationChanged: (value) =>
                                  _changeJobInput(() => _location = value),
                              onAddClient: _addClient,
                              onPricingChanged: _fromApprovedEstimate
                                  ? null
                                  : (value) =>
                                        _changeJobInput(() => _pricing = value),
                            ),
                            const SizedBox(height: 12),
                            _JobScheduleSection(
                              start: _startDateTime,
                              end: _endDateTime,
                              onStartDay: () => _pickDay(start: true),
                              onStartTime: () => _pickTime(start: true),
                              onEndDay: () => _pickDay(start: false),
                              onEndTime: () => _pickTime(start: false),
                            ),
                            const SizedBox(height: 12),
                            _JobAssignmentSection(
                              beforeAddEmployee: () async {
                                _captureJobInput();
                                await _draft?.flush();
                              },
                              assignee: _assignee,
                              employeeIds: _employeeIds,
                              onEmployeesChanged: (ids) => _changeJobInput(() {
                                _employeeIds = ids;
                                _assignee = _store.directorySession?.employees
                                    .where((e) => ids.contains(e.id))
                                    .map((e) => e.name)
                                    .join(', ');
                              }),
                              vehicle: _vehicle,
                              onAssigneeChanged: (value) =>
                                  _changeJobInput(() => _assignee = value),
                              onVehicleChanged: (value) =>
                                  _changeJobInput(() => _vehicle = value),
                            ),
                            const SizedBox(height: 12),
                            _JobItemsSection(
                              itemCount: _items.length,
                              total: _items.fold(
                                0,
                                (sum, item) => sum + item.total,
                              ),
                              lockedToEstimate: _fromApprovedEstimate,
                              onOpen: _editItems,
                            ),
                            const SizedBox(height: 12),
                            SectionCard(
                              child: TextField(
                                key: const ValueKey('job-notes-field'),
                                controller: _notes,
                                minLines: 3,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Internal job notes',
                                  helperText:
                                      'Instructions for the assigned team. These are not customer-facing terms.',
                                ),
                              ),
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
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: FilledButton.icon(
                key: const ValueKey('save-job'),
                onPressed: _draftReady && !_saving ? _save : null,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _fromApprovedEstimate ? 'Create Linked Job' : 'Save Job',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<WorkCustomerProfile> get _jobCustomers => [
    ..._store.customers,
    if (_sourceEstimate?.customerSnapshot != null &&
        !_store.customers.any(
          (customer) => customer.id == _sourceEstimate!.customerSnapshot!.id,
        ))
      _sourceEstimate!.customerSnapshot!,
  ];

  List<WorkServiceLocation> _locationsFor(String? customerName) {
    final snapshot = _sourceEstimate?.customerSnapshot;
    if (snapshot != null && snapshot.name == customerName) {
      return snapshot.locations;
    }
    if (customerName == null) return const [];
    for (final customer in _store.customers) {
      if (customer.name == customerName) return customer.locations;
    }
    return const [];
  }

  DateTime get _startDateTime => DateTime(
    _startDay.year,
    _startDay.month,
    _startDay.day,
    _startTime.hour,
    _startTime.minute,
  );

  DateTime get _endDateTime => DateTime(
    _endDay.year,
    _endDay.month,
    _endDay.day,
    _endTime.hour,
    _endTime.minute,
  );

  void _selectClient(String? value) {
    final locations = _locationsFor(value);
    _changeJobInput(() {
      _client = value;
      _location = locations.firstOrNull?.address;
    });
  }

  Future<void> _addClient() async {
    final customer = await Navigator.of(context).push<WorkCustomerProfile>(
      MaterialPageRoute(
        builder: (_) => CustomerEditScreen(selectedDay: _startDay),
      ),
    );
    if (!mounted || customer == null) return;
    if (_store.directorySession == null) {
      _store.replaceCustomers([..._store.customers, customer]);
    }
    _changeJobInput(() {
      _client = customer.name;
      _location = customer.locations.firstOrNull?.address;
    });
  }

  Future<void> _pickDay({required bool start}) async {
    final current = start ? _startDay : _endDay;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: start ? 'Choose job start date' : 'Choose job end date',
    );
    if (!mounted || picked == null) return;
    _changeJobInput(() {
      if (start) {
        _startDay = DateUtils.dateOnly(picked);
        if (_endDay.isBefore(_startDay)) _endDay = _startDay;
      } else {
        _endDay = DateUtils.dateOnly(picked);
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
      helpText: start ? 'Choose start time' : 'Choose expected end time',
    );
    if (!mounted || picked == null) return;
    _changeJobInput(() => start ? _startTime = picked : _endTime = picked);
  }

  Future<void> _editItems() async {
    if (_fromApprovedEstimate) return;
    final items = await Navigator.of(context).push<List<WorkLineItem>>(
      MaterialPageRoute(
        builder: (_) => WorkItemsEditor(
          initialItems: _items,
          pricing: _pricing,
          workspaceLabel: 'Job Items',
          draftSession: _draft,
          recoveryInput: _itemDraftInput,
          onDraftChanged: (input) =>
              _changeJobInput(() => _itemDraftInput = input),
          allowTruckStock: true,
          selectedDay: _startDay,
        ),
      ),
    );
    if (mounted && items != null) {
      _changeJobInput(() {
        _items = items;
        _itemDraftInput = null;
      });
    }
  }
}

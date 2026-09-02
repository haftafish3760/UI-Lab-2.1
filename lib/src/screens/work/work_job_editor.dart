import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';
import '../dashboard/dashboard_models.dart';
import 'customer_edit_screen.dart';
import 'estimate_models.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';
import 'work_items_editor.dart';
import 'work_models.dart';

part 'work_job_editor_sections.dart';

class WorkJobEditor extends StatefulWidget {
  const WorkJobEditor({this.sourceEstimate, this.initialDay, super.key});

  final WorkRecord? sourceEstimate;
  final DateTime? initialDay;

  @override
  State<WorkJobEditor> createState() => _WorkJobEditorState();
}

class _WorkJobEditorState extends State<WorkJobEditor> {
  late final String _number;
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
  bool get _fromApprovedEstimate => widget.sourceEstimate != null;

  @override
  void initState() {
    super.initState();
    final source = widget.sourceEstimate;
    _number =
        'JOB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
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
  }

  @override
  void dispose() {
    _title.dispose();
    _scope.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('job-editor-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
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
                          onBack: () => Navigator.of(context).pop(),
                        ),
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
                        if (widget.sourceEstimate case final source?) ...[
                          const SizedBox(height: 12),
                          _SourceEstimateBanner(record: source),
                        ],
                        const SizedBox(height: 12),
                        _JobIdentitySection(
                          number: _number,
                          title: _title,
                          scope: _scope,
                          customers: _store.customers,
                          selectedClient: _client,
                          selectedLocation: _location,
                          locations: _locationsFor(_client),
                          pricing: _pricing,
                          onClientChanged: _selectClient,
                          onLocationChanged: (value) =>
                              setState(() => _location = value),
                          onAddClient: _addClient,
                          onPricingChanged: _fromApprovedEstimate
                              ? null
                              : (value) => setState(() => _pricing = value),
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
                          assignee: _assignee,
                          vehicle: _vehicle,
                          onAssigneeChanged: (value) =>
                              setState(() => _assignee = value),
                          onVehicleChanged: (value) =>
                              setState(() => _vehicle = value),
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
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _fromApprovedEstimate ? 'Create Linked Job' : 'Save Job',
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<WorkServiceLocation> _locationsFor(String? customerName) {
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
    setState(() {
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
    _store.replaceCustomers([..._store.customers, customer]);
    setState(() {
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
    setState(() {
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
    setState(() => start ? _startTime = picked : _endTime = picked);
  }

  Future<void> _editItems() async {
    if (_fromApprovedEstimate) return;
    final items = await Navigator.of(context).push<List<WorkLineItem>>(
      MaterialPageRoute(
        builder: (_) => WorkItemsEditor(
          initialItems: _items,
          pricing: _pricing,
          workspaceLabel: 'Job Items',
          allowTruckStock: true,
          selectedDay: _startDay,
        ),
      ),
    );
    if (mounted && items != null) setState(() => _items = items);
  }

  void _save() {
    final source = widget.sourceEstimate;
    if (source != null &&
        (source.resolvedEstimateStage != EstimateStage.approved ||
            !source.hasCurrentCustomerSignature)) {
      setState(
        () => _formError =
            'This estimate revision is not currently customer-approved.',
      );
      return;
    }
    if (_title.text.trim().isEmpty || _client == null || _location == null) {
      setState(
        () => _formError =
            'Enter a job title, choose a client, and choose a service location.',
      );
      return;
    }
    if (!_endDateTime.isAfter(_startDateTime)) {
      setState(() => _formError = 'Expected end must be after the job start.');
      return;
    }
    Navigator.of(context).pop(
      WorkRecord(
        id: 'job-${DateTime.now().microsecondsSinceEpoch}',
        kind: WorkRecordKind.job,
        number: _number,
        title: _title.text.trim(),
        client: _client!,
        detail: _scope.text.trim(),
        pricing: _pricing,
        sourceId: source?.id,
        assignee: _assignee,
        vehicle: _vehicle,
        serviceLocation: _location!,
        jobNotes: _notes.text.trim(),
        createdOn: DateUtils.dateOnly(DateTime.now()),
        scheduledStart: _startDateTime,
        scheduledEnd: _endDateTime,
        status: WorkRecordStatus.scheduled,
        items: List.unmodifiable(_items),
        total: source?.total ?? _items.fold(0, (sum, item) => sum + item.total),
      ),
    );
  }
}

import '../../data/work/directory_persistence_session.dart';
import '../../data/prototype_operations_store.dart';
import 'dart:async';
import 'add_job_employee_button.dart';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/work/job_assignment_draft_workflow.dart';
import '../../data/work/work_persistence_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import 'work_models.dart';

class JobAssignmentEditorSheet extends StatefulWidget {
  const JobAssignmentEditorSheet({
    required this.record,
    this.work,
    this.recoveredWorkflow,
    super.key,
  });
  final WorkRecord record;
  final WorkPersistenceSession? work;
  final JobAssignmentDraftController? recoveredWorkflow;
  @override
  State<JobAssignmentEditorSheet> createState() =>
      _JobAssignmentEditorSheetState();
}

class _JobAssignmentEditorSheetState extends State<JobAssignmentEditorSheet>
    with DraftNavigationGuard {
  String _assignee = 'Unassigned';
  Set<String> _employeeIds = {};
  String _vehicle = 'No vehicle assigned';
  late WorkRecord _base;
  late JobAssignmentDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  bool _ready = false;
  bool _saving = false;
  String? _error;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  @override
  void initState() {
    super.initState();
    _base = widget.record;
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final work = widget.work;
      if (work == null && widget.recoveredWorkflow != null) {
        throw StateError('Recovered assignment requires its Work session.');
      }
      if (work != null) {
        final workflow =
            widget.recoveredWorkflow ??
            await work.openJobAssignmentDraft(widget.record.id);
        if (widget.recoveredWorkflow != null) {
          work.validateJobAssignmentHandoff(workflow, widget.record.id);
        }
        if (!mounted) {
          await workflow.session.close();
          return;
        }
        _workflow = workflow;
        _assignee = workflow.input.assignee;
        _employeeIds = workflow.input.employeeIds.toSet();
        _vehicle = workflow.input.vehicle;
        final draft = workflow.session;
        _subscription = draft.changes.listen((_) {
          if (mounted) setState(() {});
        });
      } else {
        _assignee = _base.assignee ?? 'Unassigned';
        _employeeIds = _base.assignedEmployeeIds.toSet();
        _vehicle = _base.vehicle ?? 'No vehicle assigned';
      }
      if (!mounted) return;
      setState(() => _ready = true);
      _capture();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        setState(
          () => _error =
              'Saved assignment could not be opened. Leave and retry; saved input has been preserved.',
        );
      }
    }
  }

  void _capture() {
    if (!_ready || _saving) return;
    _workflow?.updateAssignment(
      assignee: _assignee,
      vehicle: _vehicle,
      employeeIds: _employeeIds.toList(),
    );
  }

  Future<void> _save() async {
    if (!_ready || _saving) return;
    _capture();
    setState(() => _saving = true);
    try {
      final record = _workflow == null
          ? _base.copyWith(
              assignee: _assignee,
              vehicle: _vehicle,
              assignedEmployeeIds: _employeeIds.toList(),
            )
          : await _workflow!.confirm();
      if (record == null) throw StateError('Assignment was not saved.');
      if (mounted) await finishDraftRoute(record);
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              widget.work?.failureMessage ??
              'The assignment was not saved. Your unfinished input has been kept. Retry saving.';
        });
      }
    }
  }

  Future<void> _discard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished assignment?'),
        content: const Text('Previously saved job assignment stay unchanged.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard input'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    setState(() => _saving = true);
    try {
      await _draft?.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Unfinished assignment could not be discarded. They have been preserved.';
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    super.dispose();
  }

  void _change(VoidCallback change) {
    setState(change);
    _capture();
  }

  Widget _choice(
    String label,
    String selected,
    List<String> choices,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    key: ValueKey(label),
    initialValue: selected,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: {selected, ...choices}
        .map((value) => DropdownMenuItem(value: value, child: Text(value)))
        .toList(),
    onChanged: (value) {
      if (value != null) onChanged(value);
    },
  );
  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Assign job', style: Theme.of(context).textTheme.titleLarge),
              if (_draft != null)
                EditorDraftStatus(
                  state: _draft!.state,
                  onRetry: _draft!.retry,
                  onDiscard: _discard,
                ),
              if (_error != null) Text(_error!),
              if (!_ready && _error == null) const Text('Opening saved input…'),
              if (_ready) ...[
                const SizedBox(height: 16),
                Text(
                  'Assign employees',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text('Select one or more people for this job.'),
                if ((PrototypeOperationsScope.of(
                          context,
                        ).directorySession?.employees ??
                        [])
                    .where((e) => e.active)
                    .isEmpty)
                  const Text(
                    'No active employees yet. Add an employee to assign this job.',
                  ),
                for (final employee
                    in (PrototypeOperationsScope.of(
                              context,
                            ).directorySession?.employees ??
                            [])
                        .where((e) => e.active || _employeeIds.contains(e.id)))
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      employee.active
                          ? employee.name
                          : "${employee.name} (inactive)",
                    ),
                    value:
                        _employeeIds.contains(employee.id) ||
                        (_employeeIds.isEmpty && _assignee == employee.name),
                    onChanged: (selected) => _change(() {
                      if (_employeeIds.isEmpty) {
                        _employeeIds.addAll(
                          (PrototypeOperationsScope.of(
                                    context,
                                  ).directorySession?.employees ??
                                  [])
                              .where((e) => e.name == _assignee)
                              .map((e) => e.id),
                        );
                      }
                      if (selected == true) {
                        _employeeIds.add(employee.id);
                      } else {
                        _employeeIds.remove(employee.id);
                      }
                      _assignee =
                          (PrototypeOperationsScope.of(
                                    context,
                                  ).directorySession?.employees ??
                                  [])
                              .where((e) => _employeeIds.contains(e.id))
                              .map((e) => e.name)
                              .join(', ');
                      if (_assignee.isEmpty) _assignee = 'Unassigned';
                    }),
                  ),
                AddJobEmployeeButton(
                  beforeOpen: () async {
                    _capture();
                    await _draft?.flush();
                  },
                  onCreated: (employee) => _change(() {
                    _employeeIds.add(employee.id);
                    _assignee = PrototypeOperationsScope.of(context)
                        .directorySession!
                        .employees
                        .where((e) => _employeeIds.contains(e.id))
                        .map((e) => e.name)
                        .join(', ');
                  }),
                ),
                const SizedBox(height: 12),
                _choice('Vehicle', _vehicle, [
                  'No vehicle assigned',
                  ...?PrototypeOperationsScope.of(
                    context,
                  ).directorySession?.vehicles.map((v) => v.name),
                ], (value) => _change(() => _vehicle = value)),
              ],
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => leaveDraftRoute(),
                child: const Text('Keep unfinished assignment'),
              ),
              FilledButton(
                onPressed: _ready && !_saving ? _save : null,
                child: const Text('Save assignment'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

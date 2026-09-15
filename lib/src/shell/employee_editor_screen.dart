import '../data/work/directory_draft_handoff.dart';
import '../data/work/directory_draft_workflows.dart';
import '../data/work/employee_draft_controller.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../data/prototype_operations_store.dart';
import '../data/work/directory_persistence_session.dart';
import '../data/work/employee_directory_profile.dart';
import '../data/storage/draft_autosave_session.dart';
import '../data/storage/local_record_identity.dart';
import '../shared/draft_navigation_guard.dart';
import '../shared/editor_draft_status.dart';
import '../shared/section_card.dart';
import '../layout/app_layout_engine.dart';

part 'employee_editor_draft_recovery.dart';

class EmployeeEditorScreen extends StatefulWidget {
  const EmployeeEditorScreen({this.initial, this.recoveredWorkflow, super.key});
  final EmployeeDirectoryProfile? initial;
  final EmployeeDraftController? recoveredWorkflow;

  @override
  State<EmployeeEditorScreen> createState() => EmployeeEditorScreenState();
}

class EmployeeEditorScreenState extends State<EmployeeEditorScreen>
    with DraftNavigationGuard {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _phone = TextEditingController(text: widget.initial?.phone ?? '');
  late final _emergency = TextEditingController(
    text: widget.initial?.emergencyContact ?? '',
  );
  late final _pay = TextEditingController(text: widget.initial?.pay ?? '');
  late var _role = widget.initial?.role ?? 'Technician';
  late var _active = widget.initial?.active ?? true;
  late var _canSeeEstimates = widget.initial?.canSeeEstimates ?? true;
  late var _canCreateEstimates = widget.initial?.canCreateEstimates ?? false;
  late var _canApproveEstimates = widget.initial?.canApproveEstimates ?? false;
  late var _canRecordExpenses = widget.initial?.canRecordExpenses ?? true;
  late var _canViewCompanyReports =
      widget.initial?.canViewCompanyReports ?? false;

  DirectoryPersistenceSession? _directory;
  late EmployeeDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  bool _initialized = false;
  bool _ready = false;
  bool _saving = false;
  String? _error;
  late String _employeeId =
      widget.initial?.id ?? newLocalRecordIdentity('employee');
  int _baseRevision = 0;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  void _refresh(VoidCallback change) => setState(change);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _directory = PrototypeOperationsScope.maybeOf(context)?.directorySession;
    unawaited(_openDraft());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _name.dispose();
    _phone.dispose();
    _emergency.dispose();
    _pay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Add employee' : 'Edit employee'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_draft != null)
                      EditorDraftStatus(
                        state: _draft!.state,
                        onRetry: _draft!.retry,
                        onDiscard: _discardDraft,
                      ),
                    if (_error != null) Text(_error!),
                    if (!_ready && _error == null)
                      const Text('Opening saved input…'),
                    if (_ready) ...[
                      Text(
                        'Employee information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'These access choices are saved with the profile. Company account permissions are not connected yet.',
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        child: Column(
                          children: [
                            _field(_name, 'Employee name'),
                            _field(_phone, 'Phone number'),
                            _field(_emergency, 'Emergency contact'),
                            _field(_pay, 'Pay arrangement (private)'),
                            DropdownButtonFormField<String>(
                              initialValue: _role,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                              ),
                              items:
                                  const [
                                        'Helper',
                                        'Technician',
                                        'Supervisor',
                                        'Office',
                                      ]
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) =>
                                  _changeInput(() => _role = value ?? _role),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'What may this employee do?',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            _PermissionQuestion(
                              controlKey: const ValueKey(
                                'permission-view-estimates',
                              ),
                              question: 'Can this employee see estimates?',
                              value: _canSeeEstimates,
                              onChanged: (value) => _changeInput(() {
                                _canSeeEstimates = value;
                                if (!value) {
                                  _canCreateEstimates = false;
                                  _canApproveEstimates = false;
                                }
                              }),
                            ),
                            _PermissionQuestion(
                              controlKey: const ValueKey(
                                'permission-create-estimates',
                              ),
                              question: 'Can this employee create estimates?',
                              value: _canCreateEstimates,
                              enabled: _canSeeEstimates,
                              onChanged: (value) => _changeInput(
                                () => _canCreateEstimates = value,
                              ),
                            ),
                            _PermissionQuestion(
                              controlKey: const ValueKey(
                                'permission-approve-estimates',
                              ),
                              question: 'Can this employee approve estimates?',
                              value: _canApproveEstimates,
                              enabled: _canSeeEstimates,
                              onChanged: (value) => _changeInput(
                                () => _canApproveEstimates = value,
                              ),
                            ),
                            _PermissionQuestion(
                              controlKey: const ValueKey(
                                'permission-record-expenses',
                              ),
                              question: 'Can this employee record expenses?',
                              value: _canRecordExpenses,
                              onChanged: (value) => _changeInput(
                                () => _canRecordExpenses = value,
                              ),
                            ),
                            _PermissionQuestion(
                              controlKey: const ValueKey(
                                'permission-view-company-reports',
                              ),
                              question:
                                  'Can this employee see company reports?',
                              value: _canViewCompanyReports,
                              onChanged: (value) => _changeInput(
                                () => _canViewCompanyReports = value,
                              ),
                            ),
                            _PermissionQuestion(
                              controlKey: const ValueKey(
                                'permission-active-employee',
                              ),
                              question: 'Is this employee currently active?',
                              value: _active,
                              onChanged: (value) =>
                                  _changeInput(() => _active = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        key: const ValueKey('save-employee-button'),
                        onPressed: _saving ? null : _save,
                        child: const Text('Save employee'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Future<void> _save() async {
    if (_saving || !_ready) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter the employee name.');
      return;
    }
    await _confirmEmployee();
  }
}

class _PermissionQuestion extends StatelessWidget {
  const _PermissionQuestion({
    required this.controlKey,
    required this.question,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final Key controlKey;
  final String question;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    key: controlKey,
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final choices = SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Yes')),
            ButtonSegment(value: false, label: Text('No')),
          ],
          selected: {value},
          onSelectionChanged: enabled
              ? (selection) => onChanged(selection.first)
              : null,
        );
        if (AppLayoutEngine.stackFormFieldsFor(
          constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        )) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(question),
              const SizedBox(height: 7),
              Align(alignment: Alignment.centerRight, child: choices),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: Text(question)),
            const SizedBox(width: 10),
            choices,
          ],
        );
      },
    ),
  );
}

import '../data/work/directory_draft_handoff.dart';
import '../data/work/directory_draft_workflows.dart';
import '../data/work/vehicle_draft_controller.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../data/prototype_operations_store.dart';
import '../data/work/directory_persistence_session.dart';
import '../data/work/vehicle_directory_profile.dart';
import '../data/workday/workday_persistence_session.dart';
import '../data/storage/draft_autosave_session.dart';
import '../data/storage/local_record_identity.dart';
import '../shared/draft_navigation_guard.dart';
import '../shared/editor_draft_status.dart';
import '../shared/section_card.dart';

part 'vehicle_editor_draft_recovery.dart';

class VehicleEditorScreen extends StatefulWidget {
  const VehicleEditorScreen({this.initial, this.recoveredWorkflow, super.key});
  final VehicleDirectoryProfile? initial;
  final VehicleDraftController? recoveredWorkflow;
  @override
  State<VehicleEditorScreen> createState() => _VehicleEditorScreenState();
}

class _VehicleEditorScreenState extends State<VehicleEditorScreen>
    with DraftNavigationGuard {
  final _name = TextEditingController();
  final _model = TextEditingController();
  final _odometer = TextEditingController();
  final _assignment = TextEditingController();
  bool _active = true;
  DirectoryPersistenceSession? _directory;
  WorkdayPersistenceSession? _workday;
  late VehicleDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  bool _initialized = false;
  bool _ready = false;
  bool _saving = false;
  String? _error;
  late String _vehicleId =
      widget.initial?.id ?? newLocalRecordIdentity('vehicle');
  int _baseRevision = 0;
  int _odometerRevision = 0;
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
    _workday = WorkdayPersistenceScope.maybeOf(context);
    unawaited(_openDraft());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Add vehicle' : 'Edit vehicle'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SectionCard(
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
                          'Vehicle information',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Save confirms the odometer for this vehicle. Assignment text is a note; it does not grant account access.',
                        ),
                        const SizedBox(height: 14),
                        _field(_name, 'Vehicle name or unit number'),
                        _field(_model, 'Year, make, and model'),
                        _field(
                          _odometer,
                          'Confirmed odometer reading (mi)',
                          helper:
                              'Miles, up to one decimal place. Leave blank to keep the saved reading.',
                        ),
                        _field(_assignment, 'Assigned employee or crew'),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Vehicle is active'),
                          value: _active,
                          onChanged: (value) {
                            setState(() => _active = value);
                            _captureInput();
                          },
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          key: const ValueKey('save-vehicle-button'),
                          onPressed: _saving ? null : _save,
                          child: const Text('Save vehicle'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? helper,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, helperText: helper),
    ),
  );

  Future<void> _save() async {
    if (_saving || !_ready) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter the vehicle name.');
      return;
    }
    try {
      _currentInput.confirmedOdometerTenths();
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    await _confirmVehicle();
  }
}

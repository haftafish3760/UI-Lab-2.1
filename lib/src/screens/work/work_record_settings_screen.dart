import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/preferences/work_record_display_preferences.dart';
import '../../data/storage/preference_draft_workflow.dart';
import '../../shared/secondary_display_draft_workflows.dart';
export '../../data/preferences/work_record_display_preferences.dart';
export '../../shared/preference_display_readers.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../shared/app_preferences.dart';

part 'work_record_settings_draft_recovery.dart';

class WorkRecordSettingsScreen extends StatefulWidget {
  const WorkRecordSettingsScreen({
    required this.workspaceLabel,
    required this.workspaceId,
    required this.initial,
    this.recoveredWorkflow,
    super.key,
  });

  final String workspaceLabel;
  final String workspaceId;
  final WorkRecordDisplayPreferences initial;

  final PreferenceDraftWorkflow<WorkRecordDisplayPreferences>?
  recoveredWorkflow;

  @override
  State<WorkRecordSettingsScreen> createState() =>
      _WorkRecordSettingsScreenState();
}

class _WorkRecordSettingsScreenState extends State<WorkRecordSettingsScreen>
    with DraftNavigationGuard {
  late var _draft = widget.initial;
  AppPreferencesController? get _saved => AppPreferencesScope.maybeOf(context);

  late PreferenceDraftWorkflow<WorkRecordDisplayPreferences>? _workflow =
      widget.recoveredWorkflow;
  DraftAutosaveSession? get _session => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  bool _initialized = false;
  bool _ready = false;
  bool _saving = false;
  String? _error;
  @override
  DraftAutosaveSession? get navigationDraft => _session;
  @override
  bool get blockDraftNavigation => _saving;
  void _refresh(VoidCallback change) => setState(change);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    unawaited(_openInput());
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_session?.close().catchError((Object _) {}));
    super.dispose();
  }

  void _change(WorkRecordDisplayPreferences value) {
    setState(() => _draft = value);
    _capture();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      appBar: AppBar(title: Text('${widget.workspaceLabel} settings')),
      body: !_ready
          ? Center(child: Text(_error ?? 'Opening saved input…'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              children: [
                if (_session != null)
                  EditorDraftStatus(
                    state: _session!.state,
                    onRetry: _session!.retry,
                    onDiscard: _discard,
                  ),
                if (_error != null) Text(_error!),
                if (_session != null)
                  const Text(
                    'Back keeps unfinished choices. Save applies them to this list.',
                  ),
                Text(
                  'Choose what appears in the ${widget.workspaceLabel} list. These choices do not change records or permissions.',
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  key: const ValueKey('show-work-record-status-details'),
                  title: const Text('Show status details'),
                  subtitle: const Text(
                    'Shows the current state and supporting note.',
                  ),
                  value: _draft.showStatusDetails,
                  onChanged: _saving
                      ? null
                      : (value) => _change(
                          WorkRecordDisplayPreferences(
                            showStatusDetails: value,
                            showAssignments: _draft.showAssignments,
                            includeClosedRecords: _draft.includeClosedRecords,
                          ),
                        ),
                ),
                SwitchListTile(
                  key: const ValueKey('show-work-record-assignments'),
                  title: const Text('Show job assignments'),
                  subtitle: const Text(
                    'Shows assigned employee and vehicle on jobs.',
                  ),
                  value: _draft.showAssignments,
                  onChanged: _saving
                      ? null
                      : (value) => _change(
                          WorkRecordDisplayPreferences(
                            showStatusDetails: _draft.showStatusDetails,
                            showAssignments: value,
                            includeClosedRecords: _draft.includeClosedRecords,
                          ),
                        ),
                ),
                SwitchListTile(
                  key: const ValueKey('include-closed-work-records'),
                  title: const Text('Include completed or paid records'),
                  value: _draft.includeClosedRecords,
                  onChanged: _saving
                      ? null
                      : (value) => _change(
                          WorkRecordDisplayPreferences(
                            showStatusDetails: _draft.showStatusDetails,
                            showAssignments: _draft.showAssignments,
                            includeClosedRecords: value,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('save-work-record-settings'),
                  onPressed: _saving ? null : _confirm,
                  icon: const Icon(Icons.check_rounded),
                  label: Text('Save ${widget.workspaceLabel} settings'),
                ),
              ],
            ),
    ),
  );
}

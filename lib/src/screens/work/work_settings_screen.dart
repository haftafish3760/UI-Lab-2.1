import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/preferences/work_display_preferences.dart';
import '../../data/storage/preference_draft_workflow.dart';
import '../../shared/work_display_draft_workflow.dart';
export '../../data/preferences/work_display_preferences.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../shared/app_preferences.dart';

part 'work_settings_draft_recovery.dart';

class WorkSettingsScreen extends StatefulWidget {
  const WorkSettingsScreen({
    required this.initial,
    this.recoveredWorkflow,
    super.key,
  });

  final WorkDisplayPreferences initial;
  final PreferenceDraftWorkflow<WorkDisplayPreferences>? recoveredWorkflow;

  @override
  State<WorkSettingsScreen> createState() => _WorkSettingsScreenState();
}

class _WorkSettingsScreenState extends State<WorkSettingsScreen>
    with DraftNavigationGuard {
  late var _draft = widget.initial;
  AppPreferencesController? get _saved => AppPreferencesScope.maybeOf(context);
  WorkDisplayPreferences get _current => _draft;
  late PreferenceDraftWorkflow<WorkDisplayPreferences>? _workflow =
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

  void _change({
    bool? showEmployeeCards,
    bool? showDailySummaries,
    bool? includeCompletedWork,
  }) {
    setState(
      () => _draft = _draft.copyWith(
        showEmployeeCards: showEmployeeCards,
        showDailySummaries: showDailySummaries,
        includeCompletedWork: includeCompletedWork,
      ),
    );
    _capture();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      appBar: AppBar(title: const Text('Work settings')),
      body: !_ready
          ? Center(child: Text(_error ?? 'Opening saved input…'))
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                if (_session != null)
                  EditorDraftStatus(
                    state: _session!.state,
                    onRetry: _session!.retry,
                    onDiscard: _discard,
                  ),
                if (_error != null) Text(_error!),
                Text(
                  'Choose what appears on Work home',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'These choices change presentation only. They do not change access, assignments, records, or the required Work calendar.',
                ),
                if (_session != null)
                  const Text(
                    'Back keeps unfinished choices. Save applies them to Work.',
                  ),
                const SizedBox(height: 14),
                SwitchListTile(
                  key: const ValueKey('show-work-employee-cards'),
                  value: _current.showEmployeeCards,
                  title: const Text('Show employee status cards'),
                  subtitle: const Text(
                    'Shown in Admin view for quick employee selection and status.',
                  ),
                  onChanged: _saving
                      ? null
                      : (value) => _change(showEmployeeCards: value),
                ),
                SwitchListTile(
                  key: const ValueKey('show-work-daily-summaries'),
                  value: _current.showDailySummaries,
                  title: const Text('Show daily Jobs, Estimates, and Invoices'),
                  subtitle: const Text(
                    'The labeled Work shortcuts and required Work calendar remain visible.',
                  ),
                  onChanged: _saving
                      ? null
                      : (value) => _change(showDailySummaries: value),
                ),
                SwitchListTile(
                  key: const ValueKey('show-completed-work'),
                  value: _current.includeCompletedWork,
                  title: const Text(
                    'Include completed work in daily summaries',
                  ),
                  subtitle: const Text(
                    'Completed records remain available from Jobs and Calendar Day.',
                  ),
                  onChanged: _saving
                      ? null
                      : (value) => _change(includeCompletedWork: value),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  key: const ValueKey('save-work-settings'),
                  onPressed: _saving ? null : _confirm,
                  child: const Text('Save Work settings'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => _change(
                          showEmployeeCards: true,
                          showDailySummaries: true,
                          includeCompletedWork: true,
                        ),
                  child: const Text('Reset to recommended'),
                ),
              ],
            ),
    ),
  );
}

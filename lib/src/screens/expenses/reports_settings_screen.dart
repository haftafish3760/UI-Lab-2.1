import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/storage/preference_draft_workflow.dart';
import '../../shared/report_display_draft_workflow.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../shared/app_preferences.dart';

import 'report_period.dart';

part 'report_settings_draft_recovery.dart';

class ReportsSettingsScreen extends StatefulWidget {
  const ReportsSettingsScreen({
    required this.initial,
    this.recoveredWorkflow,
    super.key,
  });

  final ReportDisplayPreferences initial;

  final PreferenceDraftWorkflow<ReportDisplayPreferences>? recoveredWorkflow;

  @override
  State<ReportsSettingsScreen> createState() => _ReportsSettingsScreenState();
}

class _ReportsSettingsScreenState extends State<ReportsSettingsScreen>
    with DraftNavigationGuard {
  late var _draft = widget.initial;
  AppPreferencesController? get _saved => AppPreferencesScope.maybeOf(context);

  late PreferenceDraftWorkflow<ReportDisplayPreferences>? _workflow =
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

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      appBar: AppBar(
        title: const Text('Reports screen settings'),
        actions: [
          TextButton(
            key: const ValueKey('save-report-settings'),
            onPressed: !_ready || _saving ? null : _confirm,
            child: const Text('Save'),
          ),
        ],
      ),
      body: !_ready
          ? Center(child: Text(_error ?? 'Opening saved input…'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.all(16),
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
                        'Back keeps unfinished choices. Save applies them to Reports.',
                      ),
                    const Text(
                      'Choose which authorized summaries appear on Reports. These choices do not change accounting records or employee access.',
                    ),
                    const SizedBox(height: 12),
                    _switch(
                      title: 'Invoiced revenue',
                      subtitle: 'Work billed during the selected period.',
                      value: _draft.showInvoicedRevenue,
                      onChanged: (value) =>
                          _update(_draft.copyWith(showInvoicedRevenue: value)),
                    ),
                    _switch(
                      title: 'Money collected',
                      subtitle: 'Payments actually received during the period.',
                      value: _draft.showMoneyCollected,
                      onChanged: (value) =>
                          _update(_draft.copyWith(showMoneyCollected: value)),
                    ),
                    _switch(
                      title: 'Recorded expenses',
                      subtitle:
                          'Confirmed business costs in the selected period.',
                      value: _draft.showRecordedExpenses,
                      onChanged: (value) =>
                          _update(_draft.copyWith(showRecordedExpenses: value)),
                    ),
                    _switch(
                      title: 'Estimated gross profit and margin',
                      subtitle: 'Invoiced revenue minus recorded costs.',
                      value: _draft.showEstimatedGrossProfit,
                      onChanged: (value) => _update(
                        _draft.copyWith(showEstimatedGrossProfit: value),
                      ),
                    ),
                    _switch(
                      title: 'Vehicles and fuel',
                      subtitle:
                          'Recorded fuel, repair, and maintenance costs. Mileage appears after trip records are stored.',
                      value: _draft.showVehicleHealth,
                      onChanged: (value) =>
                          _update(_draft.copyWith(showVehicleHealth: value)),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const ValueKey('reset-report-settings'),
                      onPressed: _saving
                          ? null
                          : () => _update(
                              const ReportDisplayPreferences.defaults(),
                            ),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Restore default report layout'),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );

  Widget _switch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile(
    title: Text(title),
    subtitle: Text(subtitle),
    value: value,
    onChanged: _saving ? null : onChanged,
  );

  void _update(ReportDisplayPreferences value) {
    setState(() => _draft = value);
    _capture();
  }
}

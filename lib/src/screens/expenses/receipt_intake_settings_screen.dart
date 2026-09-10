import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/preferences/receipt_intake_display_preferences.dart';
import '../../data/storage/preference_draft_workflow.dart';
import '../../shared/secondary_display_draft_workflows.dart';
export '../../data/preferences/receipt_intake_display_preferences.dart';
export '../../shared/preference_display_readers.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import '../../shared/app_preferences.dart';

part 'receipt_settings_draft_recovery.dart';

class ReceiptIntakeSettingsScreen extends StatefulWidget {
  const ReceiptIntakeSettingsScreen({
    required this.initial,
    this.recoveredWorkflow,
    super.key,
  });

  final ReceiptIntakeDisplayPreferences initial;

  final PreferenceDraftWorkflow<ReceiptIntakeDisplayPreferences>?
  recoveredWorkflow;

  @override
  State<ReceiptIntakeSettingsScreen> createState() =>
      _ReceiptIntakeSettingsScreenState();
}

class _ReceiptIntakeSettingsScreenState
    extends State<ReceiptIntakeSettingsScreen>
    with DraftNavigationGuard {
  late var _draft = widget.initial;
  AppPreferencesController? get _saved => AppPreferencesScope.maybeOf(context);

  late PreferenceDraftWorkflow<ReceiptIntakeDisplayPreferences>? _workflow =
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

  void _change(ReceiptIntakeDisplayPreferences value) {
    setState(() => _draft = value);
    _capture();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    Scaffold(
      appBar: AppBar(title: const Text('Receipt intake settings')),
      body: !_ready
          ? Center(child: Text(_error ?? 'Opening saved input…'))
          : ListView(
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
                    'Back keeps unfinished choices. Save applies them to receipt intake.',
                  ),
                SwitchListTile(
                  title: const Text('Show review checklist'),
                  subtitle: const Text(
                    'Explains the required human review before anything is saved.',
                  ),
                  value: _draft.showReviewChecklist,
                  onChanged: _saving
                      ? null
                      : (value) => _change(
                          ReceiptIntakeDisplayPreferences(
                            showReviewChecklist: value,
                            showEvidenceReminders: _draft.showEvidenceReminders,
                          ),
                        ),
                ),
                SwitchListTile(
                  title: const Text('Show evidence reminders'),
                  subtitle: const Text(
                    'Reminds the user about photo order and retained originals.',
                  ),
                  value: _draft.showEvidenceReminders,
                  onChanged: _saving
                      ? null
                      : (value) => _change(
                          ReceiptIntakeDisplayPreferences(
                            showEvidenceReminders: value,
                            showReviewChecklist: _draft.showReviewChecklist,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('save-receipt-intake-settings-button'),
                  onPressed: _saving ? null : _confirm,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save receipt display settings'),
                ),
              ],
            ),
    ),
  );
}

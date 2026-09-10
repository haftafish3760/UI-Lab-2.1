import '../../data/workday/odometer_input.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/workday/workday_read_models.dart';
import '../../data/workday/end_workday_draft_workflow.dart';
import '../../data/workday/workday_persistence_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import 'dashboard_models.dart';

class EndWorkdayDialog extends StatefulWidget {
  const EndWorkdayDialog({
    required this.initialOdometerTenths,
    required this.minimumOdometerTenths,
    this.session,
    this.workday,
    this.recoveredWorkflow,
    super.key,
  });
  final int initialOdometerTenths;
  final int minimumOdometerTenths;
  final WorkdayPersistenceSession? session;
  final WorkdaySnapshot? workday;
  final EndWorkdayDraftController? recoveredWorkflow;
  @override
  State<EndWorkdayDialog> createState() => _EndWorkdayDialogState();
}

class _EndWorkdayDialogState extends State<EndWorkdayDialog>
    with DraftNavigationGuard<EndWorkdayDialog> {
  late final _controller = TextEditingController(
    text: formatOdometerTenths(widget.initialOdometerTenths),
  );
  late EndWorkdayDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  String? _errorText;
  bool _saving = false;
  bool _opening = true;
  bool _initialized = false;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_openDraft());
    });
  }

  Future<void> _openDraft() async {
    final session = widget.session;
    if (session == null) {
      if (widget.recoveredWorkflow != null) {
        await _workflow?.session.close().catchError((Object _) {});
        _workflow = null;
        if (mounted) {
          setState(
            () => _errorText =
                'Saved ending input requires its Workday session. It has been preserved.',
          );
        }
        return;
      }
      setState(() => _opening = false);
      return;
    }
    try {
      final workflow =
          widget.recoveredWorkflow ??
          await session.openEndDraft(
            workdayId: widget.workday!.record.id,
            initialOdometer: _controller.text,
          );
      if (widget.recoveredWorkflow != null) {
        session.validateEndWorkdayHandoff(workflow, widget.workday!.record.id);
      }
      final draft = workflow.session;
      if (!mounted) {
        await draft.close();
        return;
      }
      _workflow = workflow;
      _controller.text = workflow.input.odometer;
      _controller.addListener(_captureDraft);
      _subscription = draft.changes.listen((_) {
        if (mounted) setState(() {});
      });
      setState(() => _opening = false);
      _captureDraft();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        setState(
          () => _errorText =
              'Saved ending input could not be opened. Leave and retry; retained input is preserved.',
        );
      }
    }
  }

  void _captureDraft() {
    if (_opening || _saving) return;
    _workflow?.update(_controller.text);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    AlertDialog(
      title: const Text('End workday'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the physical ending odometer before closing today’s workday.',
            ),
            const SizedBox(height: 12),
            if (_opening)
              Text(_errorText ?? 'Opening saved ending input…')
            else ...[
              TextField(
                key: const ValueKey('ending-odometer-field'),
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Ending odometer',
                  suffixText: 'mi',
                  errorText: _errorText,
                ),
              ),
              if (_draft != null)
                EditorDraftStatus(
                  state: _draft!.state,
                  onRetry: _draft!.retry,
                  onDiscard: _discardDraft,
                ),
              if (_saving) const Text('Saving workday…'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: leaveDraftRoute,
          child: const Text('Keep workday open'),
        ),
        FilledButton(
          key: const ValueKey('confirm-end-workday-button'),
          onPressed: _opening ? null : _submit,
          child: const Text('End workday'),
        ),
      ],
    ),
  );

  Future<void> _submit() async {
    if (_saving || _opening) return;
    final reading = tryParseWorkdayOdometerMiles(_controller.text);
    if (reading == null || reading < widget.minimumOdometerTenths) {
      setState(
        () => _errorText =
            'Enter an ending odometer at or above the last confirmed reading.',
      );
      return;
    }
    final session = widget.session;
    if (session == null) {
      await finishDraftRoute(reading);
      return;
    }
    _captureDraft();
    setState(() {
      _saving = true;
      _errorText = null;
    });
    try {
      final result = await _workflow!.confirm();
      if (!mounted) return;
      if (!result.committed) {
        setState(() {
          _saving = false;
          _errorText = result.message;
        });
        return;
      }
      await finishDraftRoute(reading);
    } on EndWorkdayInputValidation catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorText = error.message;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorText =
              'The workday could not be ended. Your input is preserved.';
        });
      }
    }
  }

  Future<void> _discardDraft() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished ending input?'),
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
      await _draft!.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorText = 'Ending input could not be discarded. Try again.';
        });
      }
    }
  }
}

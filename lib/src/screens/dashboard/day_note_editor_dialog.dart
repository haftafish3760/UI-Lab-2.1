import '../../data/day_notes/day_note_draft_workflow.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/day_notes/day_note_persistence_session.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';

class DayNoteEditorDialog extends StatefulWidget {
  const DayNoteEditorDialog({
    required this.session,
    required this.date,
    required this.employeeId,
    required this.employeeLabel,
    this.recoveredWorkflow,
    super.key,
  });
  final DayNotePersistenceSession session;
  final DateTime date;
  final String employeeId;
  final String employeeLabel;
  final DayNoteDraftController? recoveredWorkflow;
  @override
  State<DayNoteEditorDialog> createState() => _DayNoteEditorDialogState();
}

class _DayNoteEditorDialogState extends State<DayNoteEditorDialog>
    with DraftNavigationGuard<DayNoteEditorDialog> {
  final _text = TextEditingController();
  late DayNoteDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  String? _error;
  int _timeMinutes = 0;
  bool _opening = true;
  bool _saving = false;
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
      if (mounted) unawaited(_open());
    });
  }

  Future<void> _open() async {
    try {
      final workflow =
          widget.recoveredWorkflow ??
          await widget.session.openDraft(
            date: widget.date,
            employeeId: widget.employeeId,
          );
      if (widget.recoveredWorkflow != null) {
        widget.session.validateDayNoteHandoff(
          workflow,
          date: widget.date,
          employeeId: widget.employeeId,
        );
      }
      final draft = workflow.session;
      if (!mounted) {
        await draft.close();
        return;
      }
      _workflow = workflow;
      _text.text = workflow.input.text;
      _timeMinutes = workflow.input.timeMinutes;
      _text.addListener(_capture);
      _subscription = draft.changes.listen((_) {
        if (mounted) setState(() {});
      });
      setState(() => _opening = false);
      _capture();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        setState(
          () => _error =
              'Saved day-record input could not be opened. Leave and retry; retained input is preserved.',
        );
      }
    }
  }

  void _capture() {
    if (_opening || _saving) return;
    _workflow?.update(text: _text.text, timeMinutes: _timeMinutes);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    AlertDialog(
      title: const Text('Add day record'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.employeeLabel} · ${MaterialLocalizations.of(context).formatFullDate(widget.date)}',
            ),
            const SizedBox(height: 12),
            if (_opening)
              Text(_error ?? 'Opening saved day-record input…')
            else ...[
              TextField(
                key: const ValueKey('day-note-description'),
                controller: _text,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Record description',
                  errorText: _error,
                ),
              ),
              TextButton.icon(
                onPressed: _chooseTime,
                icon: const Icon(Icons.schedule),
                label: Text(
                  'Record time: ${TimeOfDay(hour: _timeMinutes ~/ 60, minute: _timeMinutes % 60).format(context)}',
                ),
              ),
              if (_draft != null)
                EditorDraftStatus(
                  state: _draft!.state,
                  onRetry: _draft!.retry,
                  onDiscard: _discard,
                ),
              if (_saving) const Text('Saving day record…'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: leaveDraftRoute,
          child: const Text('Keep unfinished'),
        ),
        FilledButton(
          key: const ValueKey('save-day-note'),
          onPressed: _opening ? null : _save,
          child: const Text('Add'),
        ),
      ],
    ),
  );
  Future<void> _chooseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _timeMinutes ~/ 60,
        minute: _timeMinutes % 60,
      ),
      helpText: 'Choose the record time',
    );
    if (!mounted || time == null) return;
    setState(() => _timeMinutes = time.hour * 60 + time.minute);
    _capture();
  }

  Future<void> _save() async {
    if (_opening || _saving) return;
    _capture();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await _workflow!.confirm();
      if (!mounted) return;
      if (saved) {
        await finishDraftRoute();
        return;
      }
      setState(() {
        _saving = false;
        _error = widget.session.error;
      });
    } on DayNoteInputValidation catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'The day record could not be saved. Your input is preserved.';
        });
      }
    }
  }

  Future<void> _discard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished day-record input?'),
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
          _error = 'Input could not be discarded. Try again.';
        });
      }
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/work/job_notes_draft_workflow.dart';
import '../../data/work/work_persistence_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import 'work_models.dart';

class JobNotesEditorDialog extends StatefulWidget {
  const JobNotesEditorDialog({
    required this.record,
    this.work,
    this.recoveredWorkflow,
    super.key,
  });
  final WorkRecord record;
  final WorkPersistenceSession? work;
  final JobNotesDraftController? recoveredWorkflow;
  @override
  State<JobNotesEditorDialog> createState() => _JobNotesEditorDialogState();
}

class _JobNotesEditorDialogState extends State<JobNotesEditorDialog>
    with DraftNavigationGuard {
  final _notes = TextEditingController();
  late WorkRecord _base;
  late JobNotesDraftController? _workflow = widget.recoveredWorkflow;
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
        throw StateError('Recovered input requires its Work session.');
      }
      if (work != null) {
        final workflow =
            widget.recoveredWorkflow ??
            await work.openJobNotesDraft(widget.record.id);
        if (widget.recoveredWorkflow != null) {
          work.validateJobNotesHandoff(workflow, widget.record.id);
        }
        if (!mounted) {
          await workflow.session.close();
          return;
        }
        _workflow = workflow;
        _notes.text = workflow.input.notes;
        final draft = workflow.session;
        _subscription = draft.changes.listen((_) {
          if (mounted) setState(() {});
        });
      } else {
        _notes.text = _base.jobNotes;
      }
      if (!mounted) return;
      _notes.addListener(_capture);
      setState(() => _ready = true);
      _capture();
    } on Object {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        setState(
          () => _error =
              'Saved notes could not be opened. Leave and retry; saved input has been preserved.',
        );
      }
    }
  }

  void _capture() {
    if (!_ready || _saving) return;
    _workflow?.updateNotes(_notes.text);
  }

  Future<void> _save() async {
    if (!_ready || _saving) return;
    _capture();
    setState(() => _saving = true);
    try {
      final record = _workflow == null
          ? _base.copyWith(jobNotes: _notes.text.trim())
          : await _workflow!.confirm();
      if (record == null) throw StateError('Notes were not saved.');
      if (mounted) await finishDraftRoute(record);
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              widget.work?.failureMessage ??
              'The notes were not saved. Your unfinished input has been kept. Retry saving.';
        });
      }
    }
  }

  Future<void> _discard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished notes?'),
        content: const Text('Previously saved job notes stay unchanged.'),
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
              'Unfinished notes could not be discarded. They have been preserved.';
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxWidth: 480),
      title: const Text('Edit job notes'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_draft != null)
              EditorDraftStatus(
                state: _draft!.state,
                onRetry: _draft!.retry,
                onDiscard: _discard,
              ),
            if (_error != null) Text(_error!),
            if (!_ready && _error == null) const Text('Opening saved input…'),
            if (_ready)
              TextField(
                controller: _notes,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Notes for this job',
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => leaveDraftRoute(),
          child: const Text('Keep unfinished notes'),
        ),
        FilledButton(
          onPressed: _ready && !_saving ? _save : null,
          child: const Text('Save notes'),
        ),
      ],
    ),
  );
}

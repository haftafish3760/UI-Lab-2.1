part of 'work_job_editor.dart';

extension _WorkJobConfirmation on _WorkJobEditorState {
  Future<void> _save() async {
    if (_saving || !_draftReady) return;
    _captureJobInput();
    _refresh(() => _saving = true);
    final work = _store.workSession;
    try {
      final workflow = _workflow;
      final WorkRecord? job;
      if (work == null) {
        // Existing preview-only host: no durable-save claim or storage command.
        job = buildConfirmedJob(
          _jobInput,
          actorEmployeeId: demoEmployees.first.id,
          now: DateTime.now(),
        );
      } else {
        if (workflow == null) throw StateError('Job workflow is unavailable.');
        job = await workflow.confirm();
      }
      if (job == null) throw StateError('Job was not saved.');
      if (mounted) await finishDraftRoute(job);
    } on JobInputValidation catch (error) {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _formError = error.message;
        });
      }
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _formError =
              work?.failureMessage ??
              'The job was not saved. Your unfinished input has been kept. Retry saving.';
        });
      }
    }
  }
}

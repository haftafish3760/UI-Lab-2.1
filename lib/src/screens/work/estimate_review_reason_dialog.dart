import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/work_persistence_session.dart';
import '../../data/work/estimate_review_draft_workflow.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';
import 'estimate_models.dart';
import 'work_models.dart';

class EstimateReviewReasonDialog extends StatefulWidget {
  const EstimateReviewReasonDialog({
    required this.record,
    required this.decision,
    required this.permissions,
    this.recoveredWorkflow,
    super.key,
  });
  final WorkRecord record;
  final EstimateCompanyReviewDecision decision;
  final EstimatePermissions permissions;
  final EstimateReviewDraftController? recoveredWorkflow;
  @override
  State<EstimateReviewReasonDialog> createState() =>
      _EstimateReviewReasonDialogState();
}

class _EstimateReviewReasonDialogState extends State<EstimateReviewReasonDialog>
    with DraftNavigationGuard {
  final _reason = TextEditingController();
  late WorkRecord _base = widget.record;
  WorkPersistenceSession? _work;
  late EstimateReviewDraftController? _workflow = widget.recoveredWorkflow;
  EstimateReviewInput? _previewInput;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _subscription;
  bool _initialized = false, _ready = false, _saving = false;
  String? _error;
  bool get _returning =>
      widget.decision == EstimateCompanyReviewDecision.changesRequested;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      _work = PrototypeOperationsScope.maybeOf(context)?.workSession;
      final work = _work;
      if (work == null && widget.recoveredWorkflow != null) {
        throw StateError('Recovered review requires its Work session.');
      }
      if (work != null) {
        final workflow =
            widget.recoveredWorkflow ??
            await work.openEstimateReviewDraft(
              widget.record,
              decision: widget.decision,
              reviewPermissions: widget.permissions,
            );
        if (widget.recoveredWorkflow != null) {
          work.validateEstimateReviewHandoff(
            workflow,
            recordId: widget.record.id,
            decision: widget.decision,
            reviewPermissions: widget.permissions,
          );
        }
        if (!mounted) {
          await workflow.session.close();
          return;
        }
        _workflow = workflow;
        _base = workflow.input.base;
        _reason.text = workflow.input.reason;
        _subscription = workflow.session.changes.listen((_) {
          if (mounted) setState(() {});
        });
      } else {
        _previewInput = EstimateReviewInput(
          base: widget.record,
          baseRevision: 0,
          decision: widget.decision,
        )..validateReview(widget.permissions);
      }
      if (!mounted) return;
      _reason.addListener(_changed);
      setState(() => _ready = true);
    } on Object catch (error) {
      await _workflow?.session.close().catchError((Object _) {});
      _workflow = null;
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : 'Saved review could not be opened. Its input has been preserved.',
        );
      }
    }
  }

  void _changed() {
    if (!_ready || _saving) return;
    _workflow?.updateReason(_reason.text);
    _previewInput = _previewInput?.withReason(_reason.text);
  }

  Future<void> _confirm() async {
    if (!_ready || _saving) return;
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Enter a clear reason.');
      return;
    }
    setState(() => _saving = true);
    try {
      final workflow = _workflow;
      final WorkRecord? record;
      if (workflow != null) {
        record = await workflow.confirm();
      } else {
        _previewInput = _previewInput!.prepare();
        record = _previewInput!.confirmedRecord('Company reviewer');
      }
      if (record == null) {
        throw StateError(_work!.failureMessage ?? 'Review was not saved.');
      }
      if (mounted) await finishDraftRoute(record);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is StateError
              ? error.message.toString()
              : 'Review was not saved. Your reason has been retained.';
        });
      }
    }
  }

  Future<void> _discard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished review?'),
        content: const Text(
          'The saved estimate and review history stay unchanged.',
        ),
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
              'Review input could not be discarded. It has been preserved.';
        });
      }
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => guardDraftNavigation(
    AlertDialog(
      title: Text(_returning ? 'Return for changes' : 'Reject estimate'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${_base.number} · Revision ${_base.revision}'),
            if (_draft != null)
              EditorDraftStatus(
                state: _draft!.state,
                onRetry: _draft!.retry,
                onDiscard: _discard,
              ),
            if (_error != null) Text(_error!),
            if (!_ready && _error == null) const Text('Opening saved review…'),
            if (_ready)
              TextFormField(
                key: const ValueKey('company-review-reason'),
                controller: _reason,
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  alignLabelWithHint: true,
                  helperText: _returning
                      ? 'Tell the estimate creator exactly what needs to change.'
                      : 'Explain why this estimate must not be sent. The record will be retained.',
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => leaveDraftRoute(),
          child: Text(_work == null ? 'Cancel' : 'Keep unfinished'),
        ),
        FilledButton(
          key: const ValueKey('confirm-company-review-decision'),
          onPressed: _ready && !_saving ? _confirm : null,
          child: Text(_returning ? 'Return estimate' : 'Reject estimate'),
        ),
      ],
    ),
  );
}

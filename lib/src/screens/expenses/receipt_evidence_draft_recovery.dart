part of 'receipt_evidence_review_screen.dart';

extension _ReceiptEvidenceDraftRecovery on _ReceiptEvidenceReviewScreenState {
  void _capture() {
    if (!_ready || _saving || _draft == null) return;
    _workflow!.updateInput(_reviewInput);
  }

  ReceiptEvidenceReviewInput get _reviewInput => ReceiptEvidenceReviewInput(
    sourceId: _workflow!.input.sourceId,
    sourceRevision: _workflow!.input.sourceRevision,
    orderedEvidenceIds: _evidence.map((e) => e.evidenceId!),
    selectedId: _selected?.evidenceId,
    undoId: _undoItem?.evidenceId,
    undoIndex: _undoIndex,
  );

  Map<String, ReceiptEvidenceSelection> get _reviewEvidenceById {
    final result = {for (final item in _evidence) item.evidenceId!: item};
    final undo = _undoItem;
    if (undo != null) result[undo.evidenceId!] = undo;
    return result;
  }

  void _bindReview(
    ReceiptEvidenceReviewInput input,
    Map<String, ReceiptEvidenceSelection> byId,
  ) {
    _evidence
      ..clear()
      ..addAll(input.orderedEvidenceIds.map((id) => byId[id]!));
    _selectedIndex = input.selectedIndex;
    _undoItem = input.undoId == null ? null : byId[input.undoId];
    _undoIndex = input.undoIndex;
  }

  Future<void> _openDraft() async {
    if (!widget.permissions.canView ||
        !widget.permissions.canViewAmounts ||
        !widget.permissions.canAttachReceipt) {
      return;
    }
    final submission = _submission;
    if (submission == null && LocalDraftScope.maybeOf(context) == null) {
      _refresh(() => _ready = true);
      return;
    }
    try {
      if (submission == null ||
          widget.receiptDraftId == null ||
          widget.receiptRevision == null) {
        throw StateError('Missing receipt context.');
      }
      final workflow =
          _workflow ??
          await submission.openEvidenceDraft(
            receiptId: widget.receiptDraftId!,
            expectedRevision: widget.receiptRevision!,
            initiallySelectedId: _selected?.evidenceId,
          );
      if (!mounted) {
        await workflow.session.close();
        return;
      }
      final permissions = submission.receiptPermissions;
      if (workflow.source.draftId != widget.receiptDraftId ||
          workflow.session.organizationId != permissions.organizationId ||
          workflow.session.ownerId != permissions.actorEmployeeId ||
          !permissions.canTarget(workflow.source) ||
          !(permissions.owns(workflow.source)
              ? permissions.canEditOwn
              : permissions.canEditTeam)) {
        await workflow.session.close();
        _workflow = null;
        throw StateError('Recovered evidence does not match this editor.');
      }
      _workflow = workflow;
      _subscription = workflow.session.changes.listen((_) {
        if (mounted) _refresh(() {});
      });
      if (!workflow.recoveryAvailable) {
        throw StateError('Saved evidence review cannot be recovered.');
      }
      final source = workflow.source;
      final byId = {
        for (final item in source.activeEvidence)
          item.evidenceId: ReceiptEvidenceSelection(
            path: item.localPath,
            name: item.originalName,
            kind: item.kind == ReceiptDraftEvidenceKind.pdf
                ? ReceiptEvidenceKind.pdf
                : ReceiptEvidenceKind.photo,
            evidenceId: item.evidenceId,
          ),
      };
      _bindReview(workflow.input, byId);
      _refresh(() => _ready = true);
    } on Object {
      if (mounted) {
        _refresh(
          () => _failure =
              'Saved evidence review could not be opened, or the receipt has changed. Your input is preserved. Leave and reopen the receipt, or discard this unfinished review.',
        );
      }
    }
  }

  Future<void> _finish({required bool continueToDetails}) async {
    if (!_ready || _saving || (continueToDetails && _evidence.isEmpty)) return;
    _capture();
    _refresh(() {
      _saving = true;
      _failure = null;
    });
    try {
      final committed = await _workflow?.confirm();
      if (mounted) {
        await finishDraftRoute(
          ReceiptEvidenceReviewResult(
            orderedEvidence: List.unmodifiable(_evidence),
            continueToDetails: continueToDetails,
            committedReceipt: committed,
          ),
        );
      }
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _failure =
              'The evidence review was not applied. Your saved input is preserved; retry, or reopen the receipt if it changed.';
        });
      }
    }
  }

  Future<void> _discardDraft() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard unfinished evidence review?'),
        content: const Text(
          'The saved receipt and its original files stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep reviewing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard input'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    _refresh(() => _saving = true);
    try {
      await _draft?.discard();
      if (mounted) await finishDraftRoute();
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _failure =
              'The unfinished review could not be discarded. It has been preserved.';
        });
      }
    }
  }
}

// ignore_for_file: invalid_use_of_protected_member
part of 'estimate_approval_screen.dart';

extension _ApprovalDraftPersistence on EstimateApprovalScreenState {
  Future<void> _openApproval() async {
    try {
      final work = PrototypeOperationsScope.of(context).workSession;
      if (work == null) throw StateError('Customer approval is unavailable.');
      if (!work.permissions.canRecordCustomerApproval) {
        if (mounted) setState(() => _approvalReady = true);
        return;
      }
      final workflow =
          widget.recoveredWorkflow ??
          await work.openEstimateApprovalDraft(widget.record.id);
      work.validateEstimateApprovalHandoff(workflow, widget.record.id);
      if (workflow.input.baseRevision !=
          work.storageRevisionFor(widget.record.id)) {
        await workflow.session.close();
        throw StateError(
          'The document changed after this approval was started.',
        );
      }
      if (!mounted) {
        await workflow.session.close();
        return;
      }
      _approvalDraft = workflow;
      _approvalSubscription = workflow.session.changes.listen((_) {
        if (mounted) setState(() {});
      });
      final input = workflow.input;
      _name.text = input.name;
      _note.text = input.note;
      _method = input.method;
      // Displaying recovered input does not approve or overwrite it.
      _termsAccepted = input.accepted;
      setState(() => _approvalReady = true);
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'Approval input could not be opened. Saved information has been kept.',
        );
      }
    }
  }

  void _captureApproval() {
    final workflow = _approvalDraft;
    if (!_approvalReady || workflow == null) return;
    // Acknowledging terms alone, including to sign, is not an unfinished manual approval.
    if (workflow.recoveredInput == null &&
        _method == null &&
        _name.text == workflow.input.base.client &&
        _note.text.isEmpty) {
      return;
    }
    final existing = workflow.input;
    if (existing.name == _name.text &&
        existing.method == _method &&
        existing.note == _note.text &&
        existing.accepted == _termsAccepted) {
      return;
    }
    workflow.updateInput(
      EstimateApprovalInput(
        base: workflow.input.base,
        baseRevision: workflow.input.baseRevision,
        name: _name.text,
        method: _method,
        note: _note.text,
        evidence: existing.evidence,
        accepted: _termsAccepted,
      ),
    );
  }
}

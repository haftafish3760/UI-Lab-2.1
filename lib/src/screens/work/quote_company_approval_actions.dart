part of 'quote_detail_screen.dart';

extension _QuoteCompanyApprovalActions on _QuoteDetailScreenState {
  List<Widget> _approvalActions(WorkRecord record) {
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null || !record.requiresCompanyReview) return [];
    final approved = quoteHasCurrentCompanyApproval(record);
    final last = record.estimateCompanyReviewHistory.lastOrNull;
    final submitted =
        last?.decision == EstimateCompanyReviewDecision.submitted &&
        last?.contentFingerprint == quoteApprovalFingerprint(record);
    final canAct =
        work.permissions.canEdit(record) &&
        !_savingApproval &&
        record.resolvedEstimateStage == EstimateStage.readyToSend;
    return [
      Text(
        approved ? 'Approved for sending' : 'Supervisor or admin approval',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (record.estimateCompanyReviewNote.isNotEmpty)
        Text(record.estimateCompanyReviewNote),
      if (_approvalError != null) Text(_approvalError!),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (!approved && !submitted)
            TextButton.icon(
              key: const ValueKey('submit-quote-approval'),
              onPressed: canAct
                  ? () => _recordApproval(
                      record,
                      EstimateCompanyReviewDecision.submitted,
                    )
                  : null,
              icon: const Icon(Icons.send_outlined),
              label: const Text('Request approval'),
            ),
          if (!approved && submitted && work.permissions.canApproveQuotes) ...[
            TextButton.icon(
              key: const ValueKey('approve-quote-for-sending'),
              onPressed: canAct ? () => _confirmApproval(record) : null,
              icon: const Icon(Icons.check),
              label: const Text('Approve for sending'),
            ),
            TextButton(
              key: const ValueKey('request-quote-changes'),
              onPressed: canAct ? () => _requestChanges(record) : null,
              child: const Text('Request changes'),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
    ];
  }

  Future<void> _confirmApproval(WorkRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve for sending?'),
        content: Text(
          'Approve revision ${record.revision} for sending to the customer. This does not record customer acceptance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-quote-company-approval'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve for sending'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _recordApproval(record, EstimateCompanyReviewDecision.approved);
    }
  }

  Future<void> _requestChanges(WorkRecord record) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => const _QuoteChangesDialog(),
    );
    if (note != null && mounted) {
      await _recordApproval(
        record,
        EstimateCompanyReviewDecision.changesRequested,
        note: note,
      );
    }
  }

  Future<void> _recordApproval(
    WorkRecord record,
    EstimateCompanyReviewDecision decision, {
    String note = '',
  }) async {
    if (_savingApproval) return;
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null) return;
    _setApprovalState(true, null);
    final saved = await work.recordQuoteApproval(record, decision, note: note);
    if (mounted) {
      _setApprovalState(
        false,
        saved
            ? null
            : work.failureMessage ?? 'Approval was not saved. Please retry.',
      );
    }
  }
}

class _QuoteChangesDialog extends StatefulWidget {
  const _QuoteChangesDialog();
  @override
  State<_QuoteChangesDialog> createState() => _QuoteChangesDialogState();
}

class _QuoteChangesDialogState extends State<_QuoteChangesDialog> {
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('What needs changing?'),
    content: TextField(
      controller: _reason,
      autofocus: true,
      maxLines: 4,
      decoration: const InputDecoration(labelText: 'Changes needed'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ListenableBuilder(
        listenable: _reason,
        builder: (context, _) => FilledButton(
          onPressed: _reason.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _reason.text.trim()),
          child: const Text('Request changes'),
        ),
      ),
    ],
  );
}

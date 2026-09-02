part of 'estimate_detail_screen.dart';

class _EstimateCompanyReviewCard extends StatelessWidget {
  const _EstimateCompanyReviewCard({
    required this.record,
    required this.permissions,
    required this.onApprove,
    required this.onReturn,
    required this.onReject,
    required this.onEdit,
    required this.onSubmit,
  });

  final WorkRecord record;
  final EstimatePermissions permissions;
  final VoidCallback onApprove;
  final VoidCallback onReturn;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final status = record.estimateCompanyReviewStatus;
    final (accent, surface, icon) = switch (status) {
      EstimateCompanyReviewStatus.pending => (
        semantic.attention,
        semantic.attentionSurface,
        Icons.approval_outlined,
      ),
      EstimateCompanyReviewStatus.approved => (
        semantic.success,
        semantic.successSurface,
        Icons.verified_outlined,
      ),
      EstimateCompanyReviewStatus.changesRequested => (
        semantic.attention,
        semantic.attentionSurface,
        Icons.rate_review_outlined,
      ),
      EstimateCompanyReviewStatus.rejected => (
        semantic.danger,
        semantic.dangerSurface,
        Icons.cancel_outlined,
      ),
      EstimateCompanyReviewStatus.notRequired => (
        semantic.draft,
        semantic.draftSurface,
        Icons.info_outline,
      ),
    };
    return SectionCard(
      key: const ValueKey('estimate-company-review-card'),
      backgroundColor: surface,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company review',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      status.label,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_explanation(status)),
          if (record.estimateCompanyReviewNote.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              record.estimateCompanyReviewNote,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          if (_showsActions(status)) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: _actions(status)),
          ],
          if (record.estimateCompanyReviewHistory.isNotEmpty) ...[
            const Divider(height: 22),
            Text(
              'Review history',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            for (final event in record.estimateCompanyReviewHistory.reversed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_decisionLabel(event.decision)} · ${event.actor} · revision ${event.revision}',
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _explanation(EstimateCompanyReviewStatus status) => switch (status) {
    EstimateCompanyReviewStatus.pending =>
      permissions.canApproveCompanyReview
          ? 'Review this exact revision before it can be sent to the customer.'
          : 'This revision is waiting for an authorized company reviewer.',
    EstimateCompanyReviewStatus.approved =>
      'This revision may now be sent to the customer. Customer approval is still separate.',
    EstimateCompanyReviewStatus.changesRequested =>
      'Update the estimate, then submit the revised version for company approval.',
    EstimateCompanyReviewStatus.rejected =>
      'The estimate remains in company records, but it cannot be sent to the customer.',
    EstimateCompanyReviewStatus.notRequired =>
      'This estimate does not require company approval before customer delivery.',
  };

  bool _showsActions(EstimateCompanyReviewStatus status) =>
      (status == EstimateCompanyReviewStatus.pending &&
          permissions.canApproveCompanyReview) ||
      (status == EstimateCompanyReviewStatus.changesRequested &&
          permissions.canEditItems);

  List<Widget> _actions(EstimateCompanyReviewStatus status) {
    if (status == EstimateCompanyReviewStatus.pending) {
      return [
        FilledButton.icon(
          key: const ValueKey('approve-estimate-for-sending'),
          onPressed: onApprove,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Approve for sending'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('return-estimate-for-changes'),
          onPressed: onReturn,
          icon: const Icon(Icons.undo_rounded),
          label: const Text('Return for changes'),
        ),
        OutlinedButton.icon(
          key: const ValueKey('reject-estimate'),
          onPressed: onReject,
          icon: const Icon(Icons.close_rounded),
          label: const Text('Reject estimate'),
        ),
      ];
    }
    return [
      OutlinedButton.icon(
        key: const ValueKey('edit-returned-estimate'),
        onPressed: onEdit,
        icon: const Icon(Icons.edit_note_outlined),
        label: const Text('Edit estimate'),
      ),
      FilledButton.icon(
        key: const ValueKey('submit-estimate-for-approval'),
        onPressed: onSubmit,
        icon: const Icon(Icons.send_outlined),
        label: const Text('Submit for approval'),
      ),
    ];
  }
}

String _decisionLabel(EstimateCompanyReviewDecision decision) =>
    switch (decision) {
      EstimateCompanyReviewDecision.submitted => 'Submitted',
      EstimateCompanyReviewDecision.approved => 'Approved for sending',
      EstimateCompanyReviewDecision.changesRequested => 'Returned for changes',
      EstimateCompanyReviewDecision.rejected => 'Rejected',
    };

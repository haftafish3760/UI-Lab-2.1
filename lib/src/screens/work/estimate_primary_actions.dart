part of 'estimate_detail_screen.dart';

extension _EstimatePrimaryActions on _EstimateDetailScreenState {
  Widget _primaryActions() {
    final tone = OperationalCardPalette.plan;
    final work = PrototypeOperationsScope.of(context).workSession;
    final draft = _record.resolvedEstimateStage == EstimateStage.draft;
    final canSend =
        widget.permissions.canSend &&
        (work == null || work.permissions.canShareDocuments);
    return DefaultTextStyle.merge(
      style: TextStyle(color: tone.foreground),
      child: SectionCard(
        backgroundColor: tone.start,
        borderColor: tone.start,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              draft ? 'Finish your estimate' : 'Manage this estimate',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: tone.foreground),
            ),
            const SizedBox(height: 6),
            Text(
              draft
                  ? 'Your draft stays saved while you review the work and prices.'
                  : 'Review the customer copy, send it, or plan the approved work.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.permissions.canEditItems)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: OperationalCardTone.darkInk,
                      foregroundColor: OperationalCardTone.ink,
                      disabledBackgroundColor: tone.row,
                      disabledForegroundColor: OperationalCardTone.darkInk,
                    ),
                    key: const ValueKey('estimate-primary-edit'),
                    onPressed: _editEstimate,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit estimate'),
                  ),
                if (widget.permissions.canEditItems)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OperationalCardTone.darkInk,
                      backgroundColor: tone.row,
                    ),
                    key: const ValueKey('estimate-primary-items'),
                    onPressed: _editItems,
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Items'),
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OperationalCardTone.darkInk,
                    backgroundColor: tone.row,
                  ),
                  key: const ValueKey('estimate-primary-preview'),
                  onPressed: _preview,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Preview'),
                ),
                if (canSend ||
                    (_record.requiresCompanyReview &&
                        !_record.companyReviewAllowsCustomerApproval &&
                        widget.permissions.canEditItems))
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: OperationalCardTone.darkInk,
                      foregroundColor: OperationalCardTone.ink,
                      disabledBackgroundColor: tone.row,
                      disabledForegroundColor: OperationalCardTone.darkInk,
                    ),
                    key: const ValueKey('estimate-primary-send'),
                    onPressed: _reviewAndSend,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(
                      _record.requiresCompanyReview &&
                              !_record.companyReviewAllowsCustomerApproval
                          ? 'Submit for approval'
                          : 'Send estimate',
                    ),
                  ),
                if (_record.companyReviewAllowsCustomerApproval &&
                    widget.permissions.canCollectSignature &&
                    _record.resolvedEstimateStage != EstimateStage.converted)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OperationalCardTone.darkInk,
                      backgroundColor: tone.row,
                    ),
                    onPressed: _recordCustomerApproval,
                    icon: const Icon(Icons.draw_outlined),
                    label: const Text('Record customer approval'),
                  ),
                if (widget.permissions.canCollectSignature &&
                    _record.companyReviewAllowsCustomerApproval &&
                    _record.resolvedEstimateStage != EstimateStage.converted)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OperationalCardTone.darkInk,
                      backgroundColor: tone.row,
                    ),
                    onPressed: _collectSignature,
                    icon: const Icon(Icons.draw_outlined),
                    label: const Text('Sign in person'),
                  ),
                if (widget.permissions.canEditItems)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OperationalCardTone.darkInk,
                      backgroundColor: tone.row,
                    ),
                    onPressed: () => _collectSignature(forBusiness: true),
                    icon: const Icon(Icons.edit_document),
                    label: const Text('Business signature'),
                  ),
                if (widget.permissions.canConvertToJob)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: OperationalCardTone.darkInk,
                      foregroundColor: OperationalCardTone.ink,
                      disabledBackgroundColor: tone.row,
                      disabledForegroundColor: OperationalCardTone.darkInk,
                    ),
                    key: const ValueKey('estimate-primary-job'),
                    onPressed:
                        _record.resolvedEstimateStage == EstimateStage.converted
                        ? null
                        : _createApprovedJob,
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Create and assign job'),
                  ),
                if (work != null && work.canDeleteDraft(_record))
                  TextButton.icon(
                    key: const ValueKey('estimate-primary-delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: OperationalCardTone.ink,
                      backgroundColor: const Color(0xFF7F1D1D),
                    ),
                    onPressed: _deleteEstimateDraft,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete draft'),
                  ),
              ],
            ),
            if (!_record.hasCurrentCustomerApproval &&
                _record.resolvedEstimateStage != EstimateStage.converted) ...[
              const SizedBox(height: 10),
              const Text(
                'Record customer approval before creating the job. You will choose its schedule and employees in the job form.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _reviewAndSend() async {
    if (_record.requiresCompanyReview &&
        !_record.companyReviewAllowsCustomerApproval) {
      await _submitCompanyReview();
      return;
    }
    if (!mounted) return;
    await _prepareDelivery();
  }

  Future<void> _deleteEstimateDraft() async {
    final work = PrototypeOperationsScope.of(context).workSession;
    if (work == null || !work.canDeleteDraft(_record)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Delete draft?'),
        content: Text('Delete ${_record.number} for ${_record.client}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Keep draft'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Delete draft'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _refreshActions(() => _saving = true);
    final deleted = await work.deleteDraft(_record);
    if (!mounted) return;
    _refreshActions(() => _saving = false);
    if (deleted) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            work.failureMessage ?? 'The draft could not be deleted.',
          ),
        ),
      );
    }
  }
}

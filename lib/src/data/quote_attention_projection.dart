part of 'operational_attention.dart';

extension _QuoteAttentionProjection on PrototypeAttentionCenter {
  OperationalAttentionItem? _quoteAttention(
    WorkRecord record,
    OperationalAttentionQuery query,
  ) {
    if (!query.includes(OperationalAttentionResourceKind.quote)) return null;
    final authority = _workPermissions?.call();
    if (authority == null || !authority.canEdit(record)) return null;
    final status = quoteStatus(record, DateTime.now());
    final String reason;
    if (status == QuoteStatus.needsApproval &&
        record.estimateCompanyReviewStatus ==
            EstimateCompanyReviewStatus.pending &&
        authority.canApproveQuotes) {
      reason = 'Approve quote';
    } else if (status == QuoteStatus.changesRequested) {
      reason = 'Quote changes requested';
    } else if (status == QuoteStatus.expired) {
      reason = 'Quote expired';
    } else {
      return null;
    }
    return OperationalAttentionItem(
      id: 'work-quote:${record.id}',
      module: OperationalAttentionModule.work,
      resourceKind: OperationalAttentionResourceKind.quote,
      sourceId: record.id,
      title: record.title,
      reason: '$reason · ${record.client}',
    );
  }
}

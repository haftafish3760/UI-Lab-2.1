part of 'estimate_detail_screen.dart';

class _EstimateStatusCard extends StatelessWidget {
  const _EstimateStatusCard({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) {
    final stage = record.resolvedEstimateStage;
    final signature = record.customerSignature;
    final approval = record.customerApprovals
        .where((entry) => entry.revision == record.revision)
        .lastOrNull;
    return SectionCard(
      backgroundColor: stage.needsAttention
          ? Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: .55)
          : (Theme.of(context).brightness == Brightness.dark
                ? null
                : OperationalCardPalette.entries.row),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Estimate status: ${stage.label}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(stage.nextStep),
          if (approval != null) ...[
            const Divider(height: 22),
            Text(
              'Approved by ${approval.customerName}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('${approval.method.label} · Revision ${approval.revision}'),
            Text(
              'Recorded by ${approval.recordedByEmployeeId} on ${approval.recordedOn.toLocal()}',
            ),
            if (approval.note.isNotEmpty) Text(approval.note),
          ] else if (record.hasCurrentCustomerSignature) ...[
            const Divider(height: 22),
            const Text(
              'Customer approval is current',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('Approved by ${signature!.signedBy}'),
            Text('Approval applies to revision ${signature.signedRevision}.'),
          ] else if (signature != null) ...[
            const Divider(height: 22),
            const Text(
              'Customer approval required again',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(signature.invalidationReason ?? 'The estimate changed.'),
          ],
        ],
      ),
    );
  }
}

class _EstimateScopeCard extends StatelessWidget {
  const _EstimateScopeCard({required this.record, this.onEdit});
  final WorkRecord record;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EstimateCardHeading(
          title: 'Description of work',
          label: 'Edit work details',
          actionKey: 'estimate-primary-edit',
          onEdit: onEdit,
        ),
        const SizedBox(height: 6),
        Text(record.detail),
      ],
    ),
  );
}

class _EstimateTermsCard extends StatelessWidget {
  const _EstimateTermsCard({required this.record, this.onEdit});
  final WorkRecord record;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EstimateCardHeading(
          title: 'Service terms and deposit',
          label: 'Edit service terms and deposit',
          actionKey: 'review-edit-terms',
          onEdit: onEdit,
        ),
        const SizedBox(height: 8),
        Text(record.terms.isEmpty ? 'No service terms added.' : record.terms),
        const SizedBox(height: 12),
        Text(
          record.requiredDepositCents > 0
              ? 'Required deposit: \$${(record.requiredDepositCents / 100).toStringAsFixed(2)}'
              : 'No deposit required',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _EstimateDatesCard extends StatelessWidget {
  const _EstimateDatesCard({required this.record, this.onEdit});
  final WorkRecord record;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final dates = record.estimateDates;
    return SectionCard(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : OperationalCardPalette.plan.row,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EstimateCardHeading(
            title: 'Estimate dates',
            label: 'Edit estimate dates',
            actionKey: 'review-edit-dates',
            onEdit: onEdit,
          ),
          const SizedBox(height: 8),
          if (dates == null)
            const Text('No detailed estimate dates are recorded.')
          else ...[
            _DetailDate(label: 'Created', value: dates.createdOn),
            _DetailDate(label: 'Last edited', value: dates.lastEditedOn),
            _DetailDate(label: 'Sent', value: dates.sentOn),
            _DetailDate(label: 'Follow up', value: dates.followUpOn),
            _DetailDate(label: 'Valid through', value: dates.expiresOn),
            _DetailDate(
              label: 'Proposed service date',
              value: dates.proposedServiceOn,
            ),
          ],
        ],
      ),
    );
  }
}

class _EstimateItemsCard extends StatelessWidget {
  const _EstimateItemsCard({
    required this.record,
    required this.onEdit,
    this.onEditPricing,
  });
  final WorkRecord record;
  final VoidCallback? onEdit;
  final VoidCallback? onEditPricing;

  @override
  Widget build(BuildContext context) {
    final labor = record.items.where(
      (item) => item.type == WorkLineItemType.labor,
    );
    final other = record.items.where(
      (item) =>
          item.type != WorkLineItemType.labor &&
          item.type != WorkLineItemType.material,
    );
    final materials = record.items.where(
      (item) => item.type == WorkLineItemType.material,
    );
    return SectionCard(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : OperationalCardPalette.plan.row,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyedSubtree(
            key: const ValueKey('estimate-primary-items'),
            child: _EstimateCardHeading(
              title: 'Labor and materials',
              label: 'Edit labor and materials',
              actionKey: 'edit-estimate-items',
              onEdit: onEdit,
            ),
          ),
          const Divider(height: 20),
          _ItemSummary(label: 'Labor', items: labor.toList()),
          const Divider(height: 20),
          _ItemSummary(label: 'Materials', items: materials.toList()),
          if (other.isNotEmpty) ...[
            const Divider(height: 20),
            _ItemSummary(label: 'Other charges', items: other.toList()),
          ],
          const Divider(height: 20),
          Text(
            'Subtotal: \$${record.items.fold<double>(0, (sum, item) => sum + item.total).toStringAsFixed(2)}',
          ),
          Text('Discount: \$${record.discount.toStringAsFixed(2)}'),
          Text('Tax: \$${record.tax.toStringAsFixed(2)}'),
          Text(
            'Estimated total: \$${record.total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (onEditPricing != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: const ValueKey('review-edit-pricing'),
                onPressed: onEditPricing,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit discount and tax'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemSummary extends StatelessWidget {
  const _ItemSummary({required this.label, required this.items});
  final String label;
  final List<WorkLineItem> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      if (items.isEmpty)
        const Text('None recorded')
      else
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (item.description.isNotEmpty) Text(item.description),
                Text(
                  '${item.quantity} ${item.unit} · \$${item.total.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
    ],
  );
}

class _EstimateHistoryCard extends StatelessWidget {
  const _EstimateHistoryCard({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Changes and sharing history',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text('Current revision: ${record.revision}'),
        for (final revision in record.estimateRevisionHistory.reversed)
          Text('Revision ${revision.revision}: ${revision.description}'),
        for (final delivery in record.estimateDeliveries.reversed)
          Text('${delivery.method.label}: ${delivery.description}'),
        if (record.estimateRevisionHistory.isEmpty &&
            record.estimateDeliveries.isEmpty)
          const Text('No earlier revisions or deliveries are recorded.'),
      ],
    ),
  );
}

/// Keep each edit action inside its section and above the information it edits.
/// Flexible labels reflow at narrow widths and enlarged accessibility text.
class _EstimateCardHeading extends StatelessWidget {
  const _EstimateCardHeading({
    required this.title,
    required this.label,
    required this.actionKey,
    this.onEdit,
  });
  final String title, label, actionKey;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
      if (onEdit != null) ...[
        const SizedBox(width: 8),
        Flexible(
          child: TextButton.icon(
            key: ValueKey(actionKey),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: Text(label),
          ),
        ),
      ],
    ],
  );
}

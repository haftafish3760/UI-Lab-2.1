part of 'estimate_detail_screen.dart';

class _EstimateStatusCard extends StatelessWidget {
  const _EstimateStatusCard({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) {
    final stage = record.resolvedEstimateStage;
    final signature = record.customerSignature;
    return SectionCard(
      backgroundColor: stage.needsAttention
          ? Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: .55)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Customer status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            stage.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(stage.nextStep),
          if (record.hasCurrentCustomerSignature) ...[
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
  const _EstimateScopeCard({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Proposed work', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(record.detail),
        const Divider(height: 22),
        Text(
          'Pricing: ${record.pricing == WorkPricingModel.flatRate ? 'Flat rate' : 'Time and materials'}',
        ),
        Text('Template: ${record.template}'),
        Text('Terms: ${record.terms}'),
      ],
    ),
  );
}

class _EstimateDatesCard extends StatelessWidget {
  const _EstimateDatesCard({required this.record});
  final WorkRecord record;

  @override
  Widget build(BuildContext context) {
    final dates = record.estimateDates;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Estimate dates',
            style: Theme.of(context).textTheme.titleMedium,
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
  const _EstimateItemsCard({required this.record, required this.onEdit});
  final WorkRecord record;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final labor = record.items.where(
      (item) => item.type == WorkLineItemType.labor,
    );
    final materials = record.items.where(
      (item) => item.type == WorkLineItemType.material,
    );
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Labor and materials',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (onEdit != null)
                TextButton.icon(
                  key: const ValueKey('edit-estimate-items'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
            ],
          ),
          _ItemSummary(label: 'Labor', items: labor.toList()),
          const Divider(height: 20),
          _ItemSummary(label: 'Materials', items: materials.toList()),
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
            child: Text('${item.name} · ${item.quantity} ${item.unit}'),
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
          'Revision and delivery history',
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

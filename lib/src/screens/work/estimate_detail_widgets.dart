part of 'estimate_detail_screen.dart';

class _EstimateDetailHeading extends StatelessWidget {
  const _EstimateDetailHeading({
    required this.record,
    this.onEditCustomer,
    this.onEditWork,
    this.onEditDate,
    this.onContinueEditing,
  });
  final VoidCallback? onContinueEditing;
  final WorkRecord record;
  final VoidCallback? onEditCustomer, onEditWork, onEditDate;

  String _createdLabel(BuildContext context, DateTime value) {
    final date = value.toLocal();
    final locale = MaterialLocalizations.of(context);
    final label = 'Created ${locale.formatShortDate(date)}';
    // Older estimates store only a calendar date. Do not invent a midnight
    // creation time for those records.
    if (date.hour == 0 && date.minute == 0 && date.second == 0) return label;
    return '$label · ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
  }

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 12,
    runSpacing: 8,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onEditWork,
                    child: Text(
                      record.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                if (onContinueEditing != null) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: TextButton(
                      key: const ValueKey('continue-editing-top'),
                      onPressed: onContinueEditing,
                      child: const Text('Continue editing'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 3),
            InkWell(
              key: const ValueKey('review-edit-customer'),
              onTap: onEditCustomer,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      record.client,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (onEditCustomer != null)
                      const Icon(Icons.edit_outlined, size: 20),
                  ],
                ),
              ),
            ),
            InkWell(
              key: const ValueKey('review-proposed-date'),
              onTap: onEditDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Proposed service date: ${record.estimateDates?.proposedServiceOn == null ? 'Not set' : MaterialLocalizations.of(context).formatShortDate(record.estimateDates!.proposedServiceOn!)}',
                    ),
                    if (onEditDate != null)
                      const Icon(Icons.edit_calendar_outlined, size: 20),
                  ],
                ),
              ),
            ),
            Text('${record.number} · Revision ${record.revision}'),
            if (record.createdOn != null)
              Text(_createdLabel(context, record.createdOn!)),
          ],
        ),
      ),
      Text(
        '\$${record.total.toStringAsFixed(2)}',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ],
  );
}

class _DetailDate extends StatelessWidget {
  const _DetailDate({required this.label, required this.value});
  final String label;
  final DateTime? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(label),
        Text(
          value == null
              ? 'Not recorded'
              : MaterialLocalizations.of(context).formatMediumDate(value!),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

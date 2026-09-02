part of 'estimate_detail_screen.dart';

class _EstimateDetailHeading extends StatelessWidget {
  const _EstimateDetailHeading({required this.record});
  final WorkRecord record;

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
            Text(
              record.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 3),
            Text(
              '${record.number} · ${record.client} · Revision ${record.revision}',
            ),
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
    child: Row(
      children: [
        Expanded(child: Text(label)),
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

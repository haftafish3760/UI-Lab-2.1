part of 'payments_screen.dart';

class _PaymentRecordRow extends StatelessWidget {
  const _PaymentRecordRow({required this.entry, required this.linkedWork});

  final PrototypeFinancialEntry entry;
  final WorkRecord? linkedWork;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Theme.of(context).extension<AppSemanticColors>()!.success;
    final title =
        linkedWork?.number ??
        (entry.description.isEmpty ? 'Payment received' : entry.description);
    final customer = entry.payerName.isNotEmpty
        ? entry.payerName
        : linkedWork?.client ?? 'Payer not recorded';
    return Semantics(
      button: true,
      label: '$title, $customer, payment ${_moneyCents(entry.amountCents)}',
      child: Material(
        key: ValueKey('payment-entry-${entry.id}'),
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(color: accent.withValues(alpha: .65)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) =>
                  PaymentDetailScreen(payment: entry, linkedWork: linkedWork),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Row(
              children: [
                SizedBox(width: 5, child: ColoredBox(color: accent)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          customer,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  _moneyCents(entry.amountCents),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 22),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

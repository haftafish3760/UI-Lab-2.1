part of 'payments_screen.dart';

class _PaymentRecordRow extends StatelessWidget {
  const _PaymentRecordRow({
    required this.entry,
    required this.invoice,
    required this.permissions,
  });

  final PrototypeFinancialEntry entry;
  final WorkRecord? invoice;
  final InvoicePermissions permissions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Theme.of(context).extension<AppSemanticColors>()!.success;
    final customer = invoice?.client ?? 'Invoice customer unavailable';
    return Semantics(
      button: invoice != null,
      label:
          '${invoice?.number ?? entry.sourceId}, $customer, payment ${_moneyCents(entry.amountCents)}',
      child: Material(
        key: ValueKey('payment-entry-${entry.id}'),
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7),
          side: BorderSide(color: accent.withValues(alpha: .65)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: invoice == null
              ? null
              : () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => InvoiceDetailScreen(
                      record: invoice!,
                      permissions: permissions,
                    ),
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
                          invoice?.number ?? entry.sourceId,
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
                if (invoice != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 22),
                ],
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

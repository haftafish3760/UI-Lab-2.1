part of 'invoice_detail_screen.dart';

class _InvoiceDetailHeading extends StatelessWidget {
  const _InvoiceDetailHeading({
    required this.invoice,
    required this.balanceCents,
    required this.showFinancials,
    required this.collectionStatus,
  });

  final WorkRecord invoice;
  final int balanceCents;
  final bool showFinancials;
  final InvoiceCollectionStatus? collectionStatus;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final color = collectionStatus == InvoiceCollectionStatus.paid
        ? semantic.success
        : collectionStatus?.isOverdue == true
        ? semantic.attention
        : invoice.status == WorkRecordStatus.draft
        ? semantic.draft
        : semantic.current;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 18,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text('${invoice.number} · ${invoice.client}'),
                  Text(
                    invoice.status == WorkRecordStatus.draft
                        ? 'Draft · Not issued to the customer'
                        : collectionStatus?.localizedLabel(context.l10n) ??
                              invoice.status.label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (showFinancials)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Balance'),
                  Text(
                    _invoiceDetailMoney(balanceCents / 100),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceDetailLayout extends StatelessWidget {
  const _InvoiceDetailLayout({
    required this.layout,
    required this.invoice,
    required this.sourceJob,
    required this.payments,
    required this.paidCents,
    required this.balanceCents,
    required this.showFinancials,
  });

  final DetailWorkspaceLayout layout;
  final WorkRecord invoice;
  final WorkRecord? sourceJob;
  final List<PrototypeFinancialEntry> payments;
  final int paidCents;
  final int balanceCents;
  final bool showFinancials;

  @override
  Widget build(BuildContext context) {
    final primary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InvoiceWorkSection(invoice: invoice, sourceJob: sourceJob),
        const SizedBox(height: 12),
        _InvoiceLineItemsSection(
          items: invoice.items,
          showFinancials: showFinancials,
        ),
      ],
    );
    final secondary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFinancials) ...[
          _InvoiceBalanceSection(
            invoice: invoice,
            paidCents: paidCents,
            balanceCents: balanceCents,
          ),
          const SizedBox(height: 12),
          _InvoicePaymentHistory(payments: payments),
          const SizedBox(height: 12),
        ],
        _InvoiceTermsSection(invoice: invoice),
      ],
    );
    if (layout.columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [primary, const SizedBox(height: 12), secondary],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: layout.columnWidth, child: primary),
        SizedBox(width: layout.gap),
        SizedBox(width: layout.columnWidth, child: secondary),
      ],
    );
  }
}

class _InvoiceWorkSection extends StatelessWidget {
  const _InvoiceWorkSection({required this.invoice, required this.sourceJob});

  final WorkRecord invoice;
  final WorkRecord? sourceJob;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer and work',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _InvoiceDetailValue(label: 'Customer', value: invoice.client),
        if (invoice.serviceLocation.isNotEmpty)
          _InvoiceDetailValue(
            label: 'Service location',
            value: invoice.serviceLocation,
          ),
        _InvoiceDetailValue(label: 'Work completed', value: invoice.detail),
        _InvoiceDetailValue(
          label: 'Source job',
          value: sourceJob == null
              ? 'Direct invoice'
              : '${sourceJob!.number} · ${sourceJob!.title}',
        ),
      ],
    ),
  );
}

class _InvoiceLineItemsSection extends StatelessWidget {
  const _InvoiceLineItemsSection({
    required this.items,
    required this.showFinancials,
  });

  final List<WorkLineItem> items;
  final bool showFinancials;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 7),
          child: Text(
            'Invoice items',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Text('No invoice items are recorded.'),
          )
        else
          for (var index = 0; index < items.length; index++) ...[
            _InvoiceLineItemRow(
              item: items[index],
              showFinancials: showFinancials,
            ),
            if (index < items.length - 1) const Divider(height: 1),
          ],
      ],
    ),
  );
}

class _InvoiceLineItemRow extends StatelessWidget {
  const _InvoiceLineItemRow({required this.item, required this.showFinancials});

  final WorkLineItem item;
  final bool showFinancials;

  @override
  Widget build(BuildContext context) {
    final accessible = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.35;
    final quantity = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toStringAsFixed(2);
    final details = '$quantity ${item.unit} · ${item.type.label}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: accessible
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(details),
                if (item.description.isNotEmpty) Text(item.description),
                if (showFinancials)
                  Text(
                    _invoiceDetailMoney(item.total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(details),
                      if (item.description.isNotEmpty) Text(item.description),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (showFinancials)
                  Text(
                    _invoiceDetailMoney(item.total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
              ],
            ),
    );
  }
}

class _InvoiceBalanceSection extends StatelessWidget {
  const _InvoiceBalanceSection({
    required this.invoice,
    required this.paidCents,
    required this.balanceCents,
  });

  final WorkRecord invoice;
  final int paidCents;
  final int balanceCents;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      children: [
        _InvoiceAmountRow(
          label: 'Subtotal',
          value: invoice.items.fold(0, (sum, item) => sum + item.total),
        ),
        _InvoiceAmountRow(label: 'Discount', value: -invoice.discount),
        _InvoiceAmountRow(label: 'Tax', value: invoice.tax),
        const Divider(height: 18),
        _InvoiceAmountRow(
          label: 'Invoice total',
          value: invoice.total,
          strong: true,
        ),
        _InvoiceAmountRow(
          label: 'Payments received',
          value: -(paidCents / 100),
        ),
        const Divider(height: 18),
        _InvoiceAmountRow(
          label: 'Balance due',
          value: balanceCents / 100,
          strong: true,
        ),
      ],
    ),
  );
}

class _InvoicePaymentHistory extends StatelessWidget {
  const _InvoicePaymentHistory({required this.payments});

  final List<PrototypeFinancialEntry> payments;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Payment history', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 7),
        if (payments.isEmpty)
          const Text('No payments have been recorded for this invoice.')
        else
          for (final payment in payments)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Wrap(
                spacing: 10,
                runSpacing: 2,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    '${payment.kind == PrototypeFinancialKind.paymentApplied ? 'Deposit applied · ' : ''}${_invoiceDetailDate(context, payment.occurredOn)}${payment.paymentMethod.isEmpty ? '' : ' · ${payment.paymentMethod}'}',
                  ),
                  Text(
                    _invoiceDetailMoney(payment.amountCents / 100),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
      ],
    ),
  );
}

class _InvoiceTermsSection extends StatelessWidget {
  const _InvoiceTermsSection({required this.invoice});

  final WorkRecord invoice;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dates and terms', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _InvoiceDetailValue(
          label: 'Invoice date',
          value: _optionalInvoiceDate(context, invoice.issuedOn),
        ),
        _InvoiceDetailValue(
          label: 'Payment due',
          value: _optionalInvoiceDate(context, invoice.dueOn),
        ),
        _InvoiceDetailValue(
          label: 'Expected payment method',
          value: invoice.paymentMethod,
        ),
        _InvoiceDetailValue(label: 'Payment terms', value: invoice.terms),
      ],
    ),
  );
}

class _InvoiceDetailValue extends StatelessWidget {
  const _InvoiceDetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Text(value.isEmpty ? 'Not recorded' : value),
      ],
    ),
  );
}

class _InvoiceAmountRow extends StatelessWidget {
  const _InvoiceAmountRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          _invoiceDetailMoney(value),
          style: TextStyle(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

String _optionalInvoiceDate(BuildContext context, DateTime? value) =>
    value == null ? 'Not recorded' : _invoiceDetailDate(context, value);

String _invoiceDetailDate(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatMediumDate(value);

String _invoiceDetailMoney(double value) =>
    '${value < 0 ? '-' : ''}\$${value.abs().toStringAsFixed(2)}';

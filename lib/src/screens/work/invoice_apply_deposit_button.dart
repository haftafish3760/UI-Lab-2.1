import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/storage/local_record_identity.dart';
import '../../data/work/work_payment_allocation.dart';
import 'work_models.dart';

/// Applies previously received money; it never records a second payment.
class InvoiceApplyDepositButton extends StatelessWidget {
  const InvoiceApplyDepositButton({
    required this.invoice,
    required this.balanceCents,
    super.key,
  });

  final WorkRecord invoice;
  final int balanceCents;

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final work = store.workSession;
    if (work == null ||
        !work.permissions.canRecordPayments ||
        balanceCents <= 0 ||
        invoice.status == WorkRecordStatus.draft) {
      return const SizedBox.shrink();
    }
    final deposits = store.financialEntries
        .where(
          (payment) =>
              paymentMayFundInvoice(payment, invoice, store.workRecords) &&
              unappliedPaymentCents(payment, store.financialEntries) > 0,
        )
        .toList();
    if (deposits.isEmpty) return const SizedBox.shrink();
    return OutlinedButton.icon(
      key: const ValueKey('invoice-apply-deposit'),
      onPressed: () => _chooseDeposit(context, deposits),
      icon: const Icon(Icons.account_balance_wallet_outlined),
      label: const Text('Apply a recorded deposit'),
    );
  }

  Future<void> _chooseDeposit(
    BuildContext context,
    List<PrototypeFinancialEntry> deposits,
  ) async {
    final payment = await showModalBottomSheet<PrototypeFinancialEntry>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Choose a deposit to apply')),
            for (final deposit in deposits)
              ListTile(
                title: Text(
                  deposit.description.isEmpty
                      ? 'Payment received'
                      : deposit.description,
                ),
                subtitle: Text(
                  '\$${(unappliedPaymentCents(deposit, PrototypeOperationsScope.of(context).financialEntries) / 100).toStringAsFixed(2)} available',
                ),
                onTap: () => Navigator.of(sheetContext).pop(deposit),
              ),
          ],
        ),
      ),
    );
    if (payment == null || !context.mounted) return;
    final store = PrototypeOperationsScope.of(context);
    final work = store.workSession;
    if (work == null || !work.permissions.canRecordPayments) return;
    final available = unappliedPaymentCents(payment, work.financialEntries);
    final current = work.records
        .where((record) => record.id == invoice.id)
        .firstOrNull;
    if (current == null || current.status == WorkRecordStatus.draft) return;
    final paid = work.financialEntries
        .where(
          (entry) =>
              (entry.kind == PrototypeFinancialKind.paymentReceived ||
                  entry.kind == PrototypeFinancialKind.paymentApplied) &&
              entry.paymentLinkKind == PaymentLinkKind.invoice &&
              (entry.sourceId == current.id ||
                  entry.sourceId == current.number),
        )
        .fold(0, (sum, entry) => sum + entry.amountCents);
    final remaining = (current.total * 100).round() - paid;
    final amount = available < remaining ? available : remaining;
    if (amount <= 0 || !paymentMayFundInvoice(payment, current, work.records)) {
      return;
    }
    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Apply this deposit?'),
        content: Text(
          'Apply \$${(amount / 100).toStringAsFixed(2)} already received to ${current.number}? This does not record a new payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apply deposit'),
          ),
        ],
      ),
    );
    if (apply != true || !context.mounted) return;
    final saved = await work.save(
      financialEntries: [
        PrototypeFinancialEntry(
          id: newLocalRecordIdentity('deposit-application'),
          kind: PrototypeFinancialKind.paymentApplied,
          occurredOn: DateTime.now(),
          amountCents: amount,
          sourceId: current.id,
          sourcePaymentId: payment.id,
          paymentMethod: payment.paymentMethod,
          description: 'Deposit applied to ${current.number}',
        ),
      ],
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Deposit applied to ${current.number}.'
              : work.failureMessage ??
                    'The deposit was not applied. Review the invoice and retry.',
        ),
      ),
    );
  }
}

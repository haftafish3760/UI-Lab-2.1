import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/work/work_payment_allocation.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'work_detail_header.dart';
import 'work_models.dart';
import 'work_saved_document_route.dart';
import 'payment_receipt_screen.dart';

class PaymentDetailScreen extends StatelessWidget {
  const PaymentDetailScreen({
    required this.payment,
    this.linkedWork,
    super.key,
  });

  final PrototypeFinancialEntry payment;
  final WorkRecord? linkedWork;

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final work = store.workSession;
    if (work != null &&
        (!work.permissions.canManageOtherCreators ||
            !work.financialEntries.any((entry) => entry.id == payment.id))) {
      return const Scaffold(
        key: ValueKey('payment-detail-screen'),
        body: Center(child: Text('This payment is unavailable.')),
      );
    }
    final ledger = store.financialEntries;
    final canShareReceipt =
        payment.kind == PrototypeFinancialKind.paymentReceived &&
        store.directorySession?.permissions.canViewCompany == true &&
        store.directorySession!.company.companyName.trim().isNotEmpty &&
        store.workSession?.permissions.canManageOtherCreators == true &&
        store.workSession?.permissions.canShareDocuments == true &&
        store.workSession?.financialEntries.any(
              (entry) => entry.id == payment.id,
            ) ==
            true;
    final remaining = unappliedPaymentCents(payment, ledger);
    final applied = payment.amountCents - remaining;
    return Scaffold(
      key: const ValueKey('payment-detail-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final width = AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth - insets.horizontal,
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 24),
              children: [
                Center(
                  child: SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Payment received',
                          selectedDay: payment.occurredOn,
                          onBack: () => Navigator.pop(context),
                          showDateContext: true,
                        ),
                        const SizedBox(height: 12),
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$${(payment.amountCents / 100).toStringAsFixed(2)}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                payment.payerName.isEmpty
                                    ? linkedWork?.client ?? 'Payer not recorded'
                                    : payment.payerName,
                              ),
                              if (payment.description.isNotEmpty)
                                Text(payment.description),
                              Text('Paid by ${payment.paymentMethod}'),
                              if (payment.note.isNotEmpty)
                                Text('Reference or note: ${payment.note}'),
                              if (payment.paymentLinkKind ==
                                      PaymentLinkKind.estimate ||
                                  payment.paymentLinkKind ==
                                      PaymentLinkKind.job)
                                Text(
                                  applied == 0
                                      ? 'This payment has not been applied to an invoice.'
                                      : remaining == 0
                                      ? 'This payment has been applied to an invoice.'
                                      : '\$${(applied / 100).toStringAsFixed(2)} applied to an invoice · \$${(remaining / 100).toStringAsFixed(2)} still available',
                                ),
                              if (linkedWork != null) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => openSavedWorkDocument(
                                    context,
                                    linkedWork!,
                                  ),
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  label: Text(
                                    'Open ${linkedWork!.kind.name} ${linkedWork!.number}',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (canShareReceipt) ...[
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            key: const ValueKey('preview-payment-receipt'),
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => PaymentReceiptScreen(
                                  payment: payment,
                                  linkedWork: linkedWork,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Preview payment receipt'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

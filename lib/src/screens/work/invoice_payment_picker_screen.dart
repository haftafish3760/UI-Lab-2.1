import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

class InvoicePaymentPickerScreen extends StatefulWidget {
  const InvoicePaymentPickerScreen({
    required this.invoices,
    required this.selectedDay,
    required this.balanceCentsFor,
    super.key,
  });

  final List<WorkRecord> invoices;
  final DateTime selectedDay;
  final int Function(WorkRecord) balanceCentsFor;

  @override
  State<InvoicePaymentPickerScreen> createState() =>
      _InvoicePaymentPickerScreenState();
}

class _InvoicePaymentPickerScreenState
    extends State<InvoicePaymentPickerScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final matches = widget.invoices.where((invoice) {
      if (query.isEmpty) return true;
      return invoice.number.toLowerCase().contains(query) ||
          invoice.client.toLowerCase().contains(query) ||
          invoice.title.toLowerCase().contains(query);
    }).toList();
    return Scaffold(
      key: const ValueKey('invoice-payment-picker-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final width = AppLayoutEngine.formWorkspaceWidthFor(
              constraints.maxWidth - insets.horizontal,
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: 'Choose invoice',
                          selectedDay: widget.selectedDay,
                          onBack: () => Navigator.of(context).pop(),
                          showDateContext: true,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          key: const ValueKey('payment-invoice-search'),
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Search open invoices',
                            hintText: 'Invoice number, customer, or work title',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SectionCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ListTile(
                                tileColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                                leading: const Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                                title: const Text('Invoices with a balance'),
                                trailing: Text('${matches.length}'),
                              ),
                              if (matches.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No open invoice matches that search.',
                                  ),
                                )
                              else
                                for (final invoice in matches)
                                  _PaymentInvoiceRow(
                                    invoice: invoice,
                                    balanceCents: widget.balanceCentsFor(
                                      invoice,
                                    ),
                                    onTap: () =>
                                        Navigator.of(context).pop(invoice),
                                  ),
                            ],
                          ),
                        ),
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

class _PaymentInvoiceRow extends StatelessWidget {
  const _PaymentInvoiceRow({
    required this.invoice,
    required this.balanceCents,
    required this.onTap,
  });

  final WorkRecord invoice;
  final int balanceCents;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('payment-invoice-${invoice.id}'),
    minTileHeight: 64,
    title: Text('${invoice.number} · ${invoice.client}'),
    subtitle: Text(invoice.title),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '\$${(balanceCents / 100).toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
    onTap: onTap,
  );
}

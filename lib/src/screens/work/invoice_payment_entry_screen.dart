import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

class InvoicePaymentEntryScreen extends StatefulWidget {
  const InvoicePaymentEntryScreen({
    required this.invoice,
    required this.balanceCents,
    required this.initialDay,
    super.key,
  });

  final WorkRecord invoice;
  final int balanceCents;
  final DateTime initialDay;

  @override
  State<InvoicePaymentEntryScreen> createState() =>
      _InvoicePaymentEntryScreenState();
}

class _InvoicePaymentEntryScreenState extends State<InvoicePaymentEntryScreen> {
  late final TextEditingController _amount = TextEditingController(
    text: (widget.balanceCents / 100).toStringAsFixed(2),
  );
  final _note = TextEditingController();
  late DateTime _receivedOn = DateUtils.dateOnly(widget.initialDay);
  var _method = 'Card';
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('invoice-payment-entry-screen'),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final width = AppLayoutEngine.formWorkspaceWidthFor(
            constraints.maxWidth - insets.horizontal,
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 96),
            children: [
              Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkDetailHeader(
                        label: 'Record payment',
                        selectedDay: _receivedOn,
                        onBack: () => Navigator.of(context).pop(),
                        showDateContext: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.invoice.number,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '${widget.invoice.client} · ${widget.invoice.title}',
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Remaining balance: \$${(widget.balanceCents / 100).toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Payment received',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              key: const ValueKey('invoice-payment-amount'),
                              controller: _amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Amount received',
                                prefixText: r'$ ',
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue: _method,
                              decoration: const InputDecoration(
                                labelText: 'Payment method',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Card',
                                  child: Text('Card'),
                                ),
                                DropdownMenuItem(
                                  value: 'Check',
                                  child: Text('Check'),
                                ),
                                DropdownMenuItem(
                                  value: 'Cash',
                                  child: Text('Cash'),
                                ),
                                DropdownMenuItem(
                                  value: 'Bank transfer',
                                  child: Text('Bank transfer'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _method = value);
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            ListTile(
                              key: const ValueKey('invoice-payment-date'),
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Date received'),
                              subtitle: Text(
                                MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(_receivedOn),
                              ),
                              trailing: const Icon(
                                Icons.edit_calendar_outlined,
                              ),
                              onTap: _pickDate,
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _note,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Reference or note (optional)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_error case final message?) ...[
                        const SizedBox(height: 10),
                        Text(
                          message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
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
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.all(12),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: FilledButton.icon(
            key: const ValueKey('save-invoice-payment'),
            onPressed: _save,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Save payment'),
          ),
        ),
      ),
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedOn,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Choose payment date',
    );
    if (mounted && picked != null) {
      setState(() => _receivedOn = DateUtils.dateOnly(picked));
    }
  }

  void _save() {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter the amount actually received.');
      return;
    }
    final cents = (value * 100).round();
    if (cents > widget.balanceCents) {
      setState(
        () => _error =
            'This payment is larger than the remaining invoice balance.',
      );
      return;
    }
    Navigator.of(context).pop(
      PrototypeFinancialEntry(
        id: 'payment-${DateTime.now().microsecondsSinceEpoch}',
        kind: PrototypeFinancialKind.paymentReceived,
        occurredOn: _receivedOn,
        amountCents: cents,
        sourceId: widget.invoice.number,
        paymentMethod: _method,
        note: _note.text.trim(),
      ),
    );
  }
}

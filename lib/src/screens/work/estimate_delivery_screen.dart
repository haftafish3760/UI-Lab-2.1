import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import 'estimate_models.dart';
import 'work_contact_models.dart';
import 'work_detail_header.dart';
import 'work_models.dart';

class EstimateDeliveryChoice {
  const EstimateDeliveryChoice({required this.method, required this.recipient});
  final EstimateDeliveryMethod method;
  final String recipient;
}

class EstimateDeliveryScreen extends StatefulWidget {
  const EstimateDeliveryScreen({required this.record, super.key});
  final WorkRecord record;

  @override
  State<EstimateDeliveryScreen> createState() => _EstimateDeliveryScreenState();
}

class _EstimateDeliveryScreenState extends State<EstimateDeliveryScreen> {
  var _method = EstimateDeliveryMethod.email;
  final _recipient = TextEditingController();
  var _reviewed = false;
  var _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final store = PrototypeOperationsScope.of(context);
    WorkCustomerProfile? customer;
    for (final candidate in store.customers) {
      if (candidate.name == widget.record.client) customer = candidate;
    }
    _recipient.text = customer?.email ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _recipient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const ValueKey('estimate-delivery-screen'),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          final layout = AppLayoutEngine.detailWorkspaceFor(
            constraints.maxWidth - insets.horizontal,
            textScaler: MediaQuery.textScalerOf(context),
          );
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
            children: [
              Center(
                child: SizedBox(
                  width: layout.columns == 1
                      ? layout.columnWidth
                      : layout.workspaceWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WorkDetailHeader(
                        label: 'Send estimate',
                        selectedDay:
                            widget.record.estimateDates?.createdOn ??
                            DateTime.now(),
                        onBack: () => Navigator.of(context).pop(),
                        showDateContext: true,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Choose delivery method',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.record.number} · Revision ${widget.record.revision} · ${widget.record.client}',
                      ),
                      const SizedBox(height: 14),
                      _DeliveryMethodCard(
                        selected: _method,
                        onSelected: _selectMethod,
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Recipient and approval copy',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              key: const ValueKey(
                                'estimate-delivery-recipient',
                              ),
                              controller: _recipient,
                              decoration: InputDecoration(
                                labelText: _recipientLabel,
                                helperText:
                                    'Confirm this before any customer document leaves the app.',
                              ),
                            ),
                            const SizedBox(height: 10),
                            CheckboxListTile(
                              value: _reviewed,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: const Text(
                                'I reviewed the customer copy and recipient',
                              ),
                              subtitle: Text(
                                'Approval will apply only to revision ${widget.record.revision}.',
                              ),
                              onChanged: (value) =>
                                  setState(() => _reviewed = value ?? false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withValues(alpha: .55),
                        child: const Text(
                          'UI Lab records and verifies this delivery workflow. The production app must connect Email or Text to an expiring secure approval link, and Device Share, Save, or Print to the generated PDF. This screen does not pretend a network message was sent.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const ValueKey('confirm-estimate-delivery'),
                        onPressed: _reviewed ? _confirm : null,
                        icon: const Icon(Icons.task_alt_outlined),
                        label: const Text('Prepare and record delivery'),
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

  String get _recipientLabel => switch (_method) {
    EstimateDeliveryMethod.email => 'Customer email address',
    EstimateDeliveryMethod.textMessage => 'Customer mobile number',
    EstimateDeliveryMethod.deviceShare => 'Share recipient or destination',
    EstimateDeliveryMethod.savedPdf => 'Saved copy label',
    EstimateDeliveryMethod.print => 'Printed copy recipient',
    EstimateDeliveryMethod.inPerson => 'Customer name',
  };

  void _selectMethod(EstimateDeliveryMethod method) {
    final store = PrototypeOperationsScope.of(context);
    WorkCustomerProfile? customer;
    for (final candidate in store.customers) {
      if (candidate.name == widget.record.client) customer = candidate;
    }
    setState(() {
      _method = method;
      _recipient.text = switch (method) {
        EstimateDeliveryMethod.email => customer?.email ?? '',
        EstimateDeliveryMethod.textMessage => customer?.phone ?? '',
        _ => widget.record.client,
      };
    });
  }

  void _confirm() {
    if (_recipient.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter or confirm the recipient.')),
      );
      return;
    }
    Navigator.of(context).pop(
      EstimateDeliveryChoice(
        method: _method,
        recipient: _recipient.text.trim(),
      ),
    );
  }
}

class _DeliveryMethodCard extends StatelessWidget {
  const _DeliveryMethodCard({required this.selected, required this.onSelected});
  final EstimateDeliveryMethod selected;
  final ValueChanged<EstimateDeliveryMethod> onSelected;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final method in const [
          EstimateDeliveryMethod.email,
          EstimateDeliveryMethod.textMessage,
          EstimateDeliveryMethod.deviceShare,
          EstimateDeliveryMethod.savedPdf,
          EstimateDeliveryMethod.print,
        ])
          ListTile(
            key: ValueKey('delivery-${method.name}'),
            leading: Icon(
              selected == method
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
            ),
            title: Text(_methodLabel(method)),
            subtitle: Text(_methodHelp(method)),
            onTap: () => onSelected(method),
          ),
      ],
    ),
  );
}

String _methodLabel(EstimateDeliveryMethod method) => switch (method) {
  EstimateDeliveryMethod.email => 'Email PDF to customer',
  EstimateDeliveryMethod.textMessage => 'Text secure approval link',
  EstimateDeliveryMethod.deviceShare => 'Share from this device',
  EstimateDeliveryMethod.savedPdf => 'Save PDF copy',
  EstimateDeliveryMethod.print => 'Print customer copy',
  EstimateDeliveryMethod.inPerson => 'Sign in person',
};

String _methodHelp(EstimateDeliveryMethod method) => switch (method) {
  EstimateDeliveryMethod.email || EstimateDeliveryMethod.textMessage =>
    'Customer opens an expiring link and approves this exact revision.',
  EstimateDeliveryMethod.deviceShare =>
    'Use the device share sheet after the customer PDF is generated.',
  EstimateDeliveryMethod.savedPdf => 'Keep a customer-ready PDF file.',
  EstimateDeliveryMethod.print => 'Print the exact customer copy.',
  EstimateDeliveryMethod.inPerson => 'Customer signs on this device.',
};

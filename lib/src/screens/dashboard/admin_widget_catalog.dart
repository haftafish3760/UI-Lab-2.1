import 'package:flutter/material.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/operations_workspace.dart';
import '../../shared/section_card.dart';

const adminWidgetLabels = {
  'work': 'Company work today',
  'billing': 'Billing and collections',
  'calendar': 'Calendar',
  'entries': 'Recorded activity',
  'approvals': 'Approvals',
  'payments': 'Payments received',
};
const _descriptions = {
  'work':
      'Jobs scheduled or in progress, with customer and assignment details.',
  'billing': 'Outstanding invoices and estimates awaiting a customer response.',
  'calendar': 'Browse dates and open the records for a day.',
  'entries':
      'Recorded expenses, payments and work activity for the selected day.',
  'approvals':
      'Estimates awaiting company approval. Available when approval is enabled.',
  'payments': 'Money received on the selected day, linked to payment records.',
};

class AdminWidgetCatalog extends StatelessWidget {
  const AdminWidgetCatalog({required this.available, super.key});
  final List<String> available;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add dashboard widgets')),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
        final layout = AppLayoutEngine.operationsFor(
          constraints.maxWidth - insets.horizontal,
          textScaler: MediaQuery.textScalerOf(context),
        );
        return SingleChildScrollView(
          padding: insets.copyWith(top: 16, bottom: 24),
          child: OperationsWorkspaceFrame(
            layout: layout,
            primaryContent: available.isEmpty
                ? const Text(
                    'All available widgets are already on your dashboard.',
                  )
                : OperationsLaneGrid(
                    layout: layout,
                    children: [
                      for (final id in available)
                        SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                adminWidgetLabels[id]!,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(_descriptions[id]!),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                key: ValueKey('add-widget-$id'),
                                onPressed: () => Navigator.pop(context, id),
                                icon: const Icon(Icons.add),
                                label: const Text('Add to dashboard'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    ),
  );
}

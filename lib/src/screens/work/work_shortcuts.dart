import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';

enum WorkDestination {
  companyInfo('My Info', Icons.business_outlined),
  customers('Saved Clients', Icons.people_alt_outlined),
  payments('Payments', Icons.payments_outlined),
  jobs('Jobs', Icons.home_repair_service_outlined),
  estimates('Estimates', Icons.request_quote_outlined),
  invoices('Invoices', Icons.receipt_long_outlined);

  const WorkDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}

class WorkShortcutGrid extends StatelessWidget {
  const WorkShortcutGrid({
    required this.onSelected,
    this.destinations = WorkDestination.values,
    super.key,
  });

  final ValueChanged<WorkDestination> onSelected;
  final List<WorkDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = AppLayoutEngine.workShortcutsFor(
          constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        );
        return Semantics(
          label: 'Work sections',
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: layout.gap,
            runSpacing: layout.gap,
            children: [
              for (final destination in destinations)
                SizedBox(
                  key: ValueKey('quick-${destination.name}'),
                  width: layout.tileWidth,
                  child: _WorkShortcutTile(
                    destination: destination,
                    iconExtent: layout.iconExtent,
                    onTap: () => onSelected(destination),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkShortcutTile extends StatelessWidget {
  const _WorkShortcutTile({
    required this.destination,
    required this.iconExtent,
    required this.onTap,
  });

  final WorkDestination destination;
  final double iconExtent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: destination.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                key: ValueKey('work-shortcut-icon-${destination.name}'),
                width: iconExtent,
                height: iconExtent,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outline),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: .16),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(destination.icon, size: 28),
              ),
              const SizedBox(height: 5),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

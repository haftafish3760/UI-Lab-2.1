import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';

enum WorkDestination {
  companyInfo('My Info', Icons.business_outlined),
  customers('Saved Clients', Icons.people_alt_outlined),
  payments('Payments', Icons.payments_outlined),
  jobs('Jobs', Icons.home_repair_service_outlined),
  scheduling('Scheduling', Icons.event_available_outlined),
  quotes('Quotes', Icons.description_outlined),
  estimates('Estimates', Icons.request_quote_outlined),
  invoices('Invoices', Icons.receipt_long_outlined);

  const WorkDestination(this.label, this.icon);
  final String label;
  final IconData icon;

  bool get isConnected => this != scheduling && this != quotes;
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
        var minimumLabelWidth = 0.0;
        for (final destination in destinations) {
          for (final word in destination.label.split(' ')) {
            final painter = TextPainter(
              text: TextSpan(
                text: word,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            if (painter.width + 4 > minimumLabelWidth) {
              minimumLabelWidth = painter.width + 4;
            }
          }
        }
        final layout = AppLayoutEngine.workShortcutsFor(
          constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
          minimumLabelWidth: minimumLabelWidth,
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
                child: Icon(destination.icon, size: 32, color: colors.primary),
              ),
              const SizedBox(height: 5),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              if (!destination.isConnected)
                Text(
                  'Not connected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

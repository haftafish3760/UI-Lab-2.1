import 'package:flutter/material.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../shared/app_view_mode.dart';

class DashboardViewSelector extends StatelessWidget {
  const DashboardViewSelector({
    required this.view,
    required this.onChanged,
    super.key,
  });
  final AppViewMode view;
  final ValueChanged<AppViewMode> onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<AppViewMode>(
    key: const ValueKey('dashboard-view-selector'),
    tooltip: context.l10n.operationalChangeViewTooltip,
    initialValue: view,
    onSelected: onChanged,
    itemBuilder: (_) => [
      for (final mode in AppViewMode.values)
        PopupMenuItem(
          value: mode,
          child: Text(mode.localizedLabel(context.l10n)),
        ),
    ],
    child: Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              view.localizedLabel(context.l10n),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.expand_more, size: 20),
        ],
      ),
    ),
  );
}

part of 'operational_header.dart';

/// Opt-in Dashboard toolbar; other screens and compact layouts are unchanged.
class _DashboardHeaderContents extends StatelessWidget {
  const _DashboardHeaderContents({required this.header});
  final OperationalHeader header;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    child: Row(
      children: [
        header._leadingButton(),
        const SizedBox(width: 12),
        Expanded(flex: 5, child: _OwnerVehicleSelector(header: header)),
        if (header.contextReading != null) ...[
          const SizedBox(width: 16),
          Expanded(flex: 3, child: header.contextReading!),
        ],
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: PopupMenuButton<AppViewMode>(
            tooltip: context.l10n.operationalChangeViewTooltip,
            initialValue: header.view,
            onSelected: header.onViewChanged,
            color: AppColors.headerControl,
            itemBuilder: (_) => [
              for (final view in AppViewMode.values)
                PopupMenuItem(
                  value: view,
                  child: Text(
                    view.localizedLabel(context.l10n),
                    style: const TextStyle(color: AppColors.onHeader),
                  ),
                ),
            ],
            child: Container(
              key: header.viewKey,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.headerControl,
                border: Border.all(color: AppColors.headerBorder),
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      header.view.localizedLabel(context.l10n),
                      style: const TextStyle(color: AppColors.onHeader),
                    ),
                  ),
                  const Icon(Icons.expand_more, color: AppColors.onHeader),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        header._settingsSlot(),
      ],
    ),
  );
}

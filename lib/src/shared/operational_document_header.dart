part of 'operational_header.dart';

/// Compact document navigation uses the Dashboard's 76-LP minimum, but grows
/// with accessibility text. Scope and role remain controlled by the caller.
class _DocumentHeaderContents extends StatelessWidget {
  const _DocumentHeaderContents({required this.header});
  final OperationalHeader header;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 76),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          header._leadingButton(),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header.headerTitle ?? '',
                  style: const TextStyle(
                    color: AppColors.onHeader,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                PopupMenuButton<OperationalHeaderContextOption>(
                  key: header.contextKey,
                  tooltip: header.selectedContext.localizedLabel(context.l10n),
                  onSelected: header.onContextChanged,
                  itemBuilder: (_) => [
                    for (final option in header.contextOptions)
                      PopupMenuItem(
                        value: option,
                        child: Text(option.localizedTitle(context.l10n)),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            header.selectedContext.localizedTitle(context.l10n),
                            style: const TextStyle(
                              color: AppColors.onHeaderMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.expand_more,
                          size: 18,
                          color: AppColors.onHeaderMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: PopupMenuButton<AppViewMode>(
              key: header.viewKey,
              tooltip: 'View',
              onSelected: header.onViewChanged,
              itemBuilder: (_) => [
                for (final mode in AppViewMode.values)
                  PopupMenuItem(
                    value: mode,
                    child: Text(mode.localizedLabel(context.l10n)),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'View: ${header.view.localizedLabel(context.l10n)}',
                  style: const TextStyle(
                    color: AppColors.onHeader,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          if (header.showSettings) header._settingsButton(),
        ],
      ),
    ),
  );
}

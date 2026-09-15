part of 'operational_header.dart';

class _DashboardHeaderContents extends StatelessWidget {
  const _DashboardHeaderContents({required this.header});
  final OperationalHeader header;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 76),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 48, child: header._leadingButton()),
          Expanded(
            child: Material(
              color: AppColors.headerControl,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: AppColors.headerBorder),
              ),
              child: InkWell(
                key: header.contextKey,
                onTap: () async {
                  final selected =
                      await showDialog<OperationalHeaderContextOption>(
                        context: context,
                        builder: (_) =>
                            _OperationalContextPicker(header: header),
                      );
                  if (context.mounted && selected != null) {
                    header.onContextChanged(selected);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        header.selectedContext
                            .localizedLabel(context.l10n)
                            .toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.onHeaderMuted,
                          fontSize: 10,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              header.selectedContext.localizedTitle(
                                context.l10n,
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.onHeader,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.expand_more,
                            size: 18,
                            color: AppColors.onHeader,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (header.contextReading != null) ...[
            const SizedBox(width: 8),
            Expanded(child: header.contextReading!),
          ],
          SizedBox(width: 48, child: header._settingsSlot()),
        ],
      ),
    ),
  );
}

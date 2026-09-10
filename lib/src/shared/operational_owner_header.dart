part of 'operational_header.dart';

/// Owner-facing presentation of the shared header. No role switch or workday
/// action lives here; callers supply context and a separately owned reading.
class _OwnerHeaderContents extends StatelessWidget {
  const _OwnerHeaderContents({required this.header});

  final OperationalHeader header;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            header._leadingButton(),
            Expanded(
              child: Text(
                header.headerTitle ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onHeader,
                  fontSize: 16,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            header._settingsSlot(),
          ],
        ),
        const SizedBox(height: 2),
        LayoutBuilder(
          builder: (context, constraints) {
            final selector = _OwnerVehicleSelector(header: header);
            final reading = header.contextReading;
            if (reading == null) return selector;
            if (AppLayoutEngine.stackOwnerHeaderContextFor(
              constraints.maxWidth,
              textScaler: MediaQuery.textScalerOf(context),
            )) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [selector, const SizedBox(height: 12), reading],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: selector),
                const SizedBox(width: 12),
                Expanded(child: reading),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _OwnerVehicleSelector extends StatelessWidget {
  const _OwnerVehicleSelector({required this.header});
  final OperationalHeader header;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async {
      final selected = await showDialog<OperationalHeaderContextOption>(
        context: context,
        builder: (_) => _OperationalContextPicker(header: header),
      );
      if (context.mounted && selected != null) {
        header.onContextChanged(selected);
      }
    },
    child: Semantics(
      button: true,
      child: ConstrainedBox(
        key: header.contextKey,
        constraints: const BoxConstraints(minHeight: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              header.selectedContext.localizedLabel(context.l10n).toUpperCase(),
              style: const TextStyle(
                color: AppColors.onHeaderMuted,
                fontSize: 11,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    header.selectedContext.localizedTitle(context.l10n),
                    style: const TextStyle(
                      color: AppColors.onHeader,
                      fontSize: 17,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, color: AppColors.onHeaderMuted),
              ],
            ),
            if (header.selectedContext.detail != null)
              Text(
                header.selectedContext.detail!,
                style: const TextStyle(
                  color: AppColors.onHeaderMuted,
                  fontSize: 12,
                  height: 1.15,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

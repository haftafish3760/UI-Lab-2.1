part of 'operational_header.dart';

class _ContextSelector extends StatelessWidget {
  const _ContextSelector({
    required this.selected,
    required this.options,
    required this.onSelected,
    required this.controlKey,
  });

  final OperationalHeaderContextOption selected;
  final List<OperationalHeaderContextOption> options;
  final ValueChanged<OperationalHeaderContextOption> onSelected;
  final Key controlKey;

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final selectedLabel = selected.localizedLabel(localizations);
    final selectedTitle = selected.localizedTitle(localizations);
    return PopupMenuButton<OperationalHeaderContextOption>(
      initialValue: selected,
      tooltip: localizations.operationalChangeContextTooltip,
      position: PopupMenuPosition.under,
      color: AppColors.headerControl,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.headerBorder),
        borderRadius: BorderRadius.circular(AppRadii.overlay),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final option in options)
          PopupMenuItem(
            value: option,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                option.icon,
                color: option.iconColor ?? AppColors.onHeaderMuted,
              ),
              title: Text(
                option.localizedTitle(localizations),
                style: const TextStyle(
                  color: AppColors.onHeader,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: option.detail == null
                  ? null
                  : Text(
                      option.detail!,
                      style: const TextStyle(color: AppColors.onHeaderMuted),
                    ),
            ),
          ),
      ],
      child: Semantics(
        button: true,
        label: localizations.operationalContextSemantics(
          selectedLabel,
          selectedTitle,
        ),
        excludeSemantics: true,
        child: Container(
          key: controlKey,
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsetsDirectional.fromSTEB(9, 2, 5, 2),
          decoration: BoxDecoration(
            color: AppColors.headerControlAlt,
            border: Border.all(color: AppColors.headerBorder, width: 1.1),
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      selectedLabel.toUpperCase(),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.onHeaderMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .3,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      selectedTitle,
                      maxLines: 2,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.onHeader,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_drop_down_rounded,
                color: AppColors.onHeader,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({
    required this.selected,
    required this.stackLabel,
    required this.onSelected,
    required this.controlKey,
  });

  final AppViewMode selected;
  final bool stackLabel;
  final ValueChanged<AppViewMode> onSelected;
  final Key controlKey;

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final selectedLabel = selected.localizedLabel(localizations);
    return PopupMenuButton<AppViewMode>(
      initialValue: selected,
      tooltip: localizations.operationalChangeViewTooltip,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 176),
      color: AppColors.headerControl,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.headerBorder),
        borderRadius: BorderRadius.circular(AppRadii.overlay),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final view in AppViewMode.values)
          PopupMenuItem(
            value: view,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Icon(
                    view == selected ? Icons.check_rounded : null,
                    color: const Color(0xFF76D6A4),
                  ),
                ),
                Expanded(
                  child: Text(
                    view.localizedLabel(localizations),
                    style: const TextStyle(
                      color: AppColors.onHeader,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        key: controlKey,
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: AppColors.headerControl,
          border: Border.all(color: AppColors.headerBorder, width: 1.1),
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: stackLabel
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${localizations.operationalViewLabel}:',
                          style: const TextStyle(
                            color: AppColors.onHeaderMuted,
                            fontSize: 9,
                            height: 1,
                          ),
                        ),
                        Text(
                          selectedLabel,
                          maxLines: 1,
                          style: const TextStyle(
                            color: AppColors.onHeader,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      localizations.operationalViewValue(selectedLabel),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.onHeader,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.onHeader,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _StartWorkdayButton extends StatelessWidget {
  const _StartWorkdayButton({
    required this.stackLabel,
    required this.label,
    required this.icon,
    required this.controlKey,
    this.onPressed,
  });

  final bool stackLabel;
  final String label;
  final IconData icon;
  final Key controlKey;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: controlKey,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: stackLabel && label.contains(' ')
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.substring(0, label.indexOf(' ')),
                  style: const TextStyle(fontSize: 11, height: 1),
                ),
                Text(
                  label.substring(label.indexOf(' ') + 1),
                  style: const TextStyle(fontSize: 11, height: 1),
                ),
              ],
            )
          : Text(label, maxLines: 1, softWrap: false),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF6AD39B),
        foregroundColor: AppColors.header,
        minimumSize: const Size(0, 42),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
      ),
    );
  }
}
